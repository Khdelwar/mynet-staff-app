import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/duty.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/duty/tracker.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/duty.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/duty_screen.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

Map<String, Object?> _duty({bool on = false, int distance = 0}) => {
  'on_duty': on,
  'session': on
      ? {
          'id': 12,
          'started_at': '2026-11-23T10:00:00+06:00',
          'distance_m': distance,
        }
      : null,
  'within_duty_hours': true,
  'tracking': {
    'duty_start': '08:00',
    'duty_end': '22:00',
    'timezone': 'Asia/Dhaka',
    'interval_moving_s': 60,
    'interval_still_s': 600,
    'interval_on_the_way_s': 30,
    'max_batch': 200,
  },
};

Future<void> _pump(
  WidgetTester tester,
  FakeErp erp,
  IdleTracker tracker, {
  LocationPoint? here,
}) async {
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore()..values[sessionTokenKey] = 'tok',
        ),
        apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
        dutyTrackerProvider.overrideWithValue(tracker),
        hereProvider.overrideWithValue(() async => here),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DutyScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('duty is hidden when /me screens leave it out', () {
    final user = StaffUser.fromJson({
      'user': {'id': 7, 'name': 'Rahim'},
      'permissions': ['staff_app.use', 'tickets.view'],
      'screens': ['tickets'],
    });
    expect(featuresFor(user).map((f) => f.permission), ['tickets.view']);
  });

  testWidgets('start sends this spot and end stops duty', (tester) async {
    final tracker = IdleTracker();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 7, 'name': 'Rahim'},
        },
      ),
      'GET /duty': (_) => (200, _duty()),
      'POST /duty/start': (o) => (200, _duty(on: true, distance: 0)),
      'POST /duty/end': (_) => (200, _duty()),
      'GET /tickets': (_) => (200, {'tickets': []}),
    });
    await _pump(
      tester,
      erp,
      tracker,
      here: LocationPoint(
        latitude: 23.81,
        longitude: 90.41,
        recordedAt: DateTime.utc(2026, 11, 23, 4),
        accuracy: 8,
      ),
    );
    expect(find.text('Off duty'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('duty-start')));
    await tester.pumpAndSettle();
    final start =
        erp.requests.lastWhere((r) => r.uri.path.endsWith('/duty/start')).data
            as Map;
    expect(start['latitude'], 23.81);
    expect(start['longitude'], 90.41);
    expect(tracker.running, isTrue);
    expect(find.text('On duty'), findsOneWidget);
    expect(find.text('Staff app: location on'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('duty-end')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(erp.calls, contains('POST /duty/end'));
    expect(tracker.running, isFalse);
    expect(find.text('Off duty'), findsOneWidget);
  });

  testWidgets('outside duty hours shows the ERP message', (tester) async {
    final tracker = IdleTracker();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1},
        },
      ),
      'GET /duty': (_) => (200, _duty()),
      'POST /duty/start': (_) => (
        422,
        {
          'message': 'Duty hours are 08:00–22:00',
          'errors': {
            'duty': ['Duty hours are 08:00–22:00'],
          },
        },
      ),
    });
    await _pump(tester, erp, tracker);
    await tester.tap(find.byKey(const ValueKey('duty-start')));
    await tester.pumpAndSettle();
    expect(find.text('Duty hours are 08:00–22:00'), findsOneWidget);
    expect(tracker.running, isFalse);
  });

  testWidgets('a point is sent, and 409 stops tracking', (tester) async {
    final tracker = IdleTracker();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 7},
        },
      ),
      'GET /duty': (_) => (200, _duty(on: true, distance: 4200)),
      'GET /tickets': (_) => (
        200,
        {
          'tickets': [
            {'id': 41, 'status': 'on_the_way'},
          ],
        },
      ),
      'POST /locations': (_) => (
        409,
        {'code': 'not_on_duty', 'message': 'Not on duty', 'on_duty': false},
      ),
    });
    await _pump(tester, erp, tracker);
    expect(find.textContaining('4200'), findsOneWidget);
    expect(tracker.running, isTrue);
    final recorded = DateTime.utc(2026, 11, 23, 4, 1);
    tracker.emit(
      LocationPoint(
        latitude: 23.8103,
        longitude: 90.4125,
        recordedAt: recorded,
        accuracy: 8,
        speed: 1.2,
        heading: 90,
        battery: 64,
        isMock: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    final body =
        erp.requests.lastWhere((r) => r.uri.path.endsWith('/locations')).data
            as Map;
    final point = (body['points'] as List).single as Map;
    expect(point['latitude'], 23.8103);
    expect(point['is_mock'], false);
    expect(point['heading'], 90);
    expect(tracker.running, isFalse);
    expect(find.text('Off duty'), findsOneWidget);
  });
}
