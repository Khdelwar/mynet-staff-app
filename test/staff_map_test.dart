import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/api/staff_map.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:mynet_staff/ui/staff_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Web Staff map in the app: GET /staff-map (staff.location.view).

Map<String, Object?> _payload({int? selected}) => {
  'center': {'lat': 23.81, 'lng': 90.41},
  'staff': [
    {
      'id': 7,
      'name': 'Rahim',
      'lat': 23.8103,
      'lng': 90.4125,
      'battery': 71,
      'seen_minutes': 2,
      'state': 'busy',
      'ticket': {'id': 42, 'subject': 'No internet', 'status': 'in_progress'},
      'on_duty_since': '2026-11-25T09:30:00+06:00',
      'distance_km': 4.2,
      'closed_today': 3,
    },
    {'id': 8, 'name': 'Karim', 'state': 'stale', 'closed_today': 0},
  ],
  'tickets': [
    {
      'id': 42,
      'subject': 'No internet',
      'priority': 'high',
      'status': 'in_progress',
      'client': 'Kamal',
      'assignee': 'Rahim',
      'lat': 23.80,
      'lng': 90.41,
    },
  ],
  'route': selected == 7
      ? [
          [23.81, 90.41],
          [23.82, 90.42],
        ]
      : [],
  'selected': selected,
  'suspicious_today': selected == 7 ? 1 : 0,
};

void main() {
  test('reads the ERP payload as sent', () {
    final data = StaffMapData.fromJson(_payload(selected: 7));
    expect(data.staff, hasLength(2));
    expect(data.staff.first.state, 'busy');
    expect(data.staff.first.ticketId, 42);
    expect(data.staff.last.onMap, isFalse);
    expect(data.route, [(23.81, 90.41), (23.82, 90.42)]);
    expect(data.selected, 7);
    expect(data.suspiciousToday, 1);
  });

  test('Home shows the button only with staff.location.view', () {
    final manager = StaffUser.fromJson({
      'user': {
        'id': 1,
        'permissions': ['staff.location.view'],
        'screens': ['staff_map'],
      },
    });
    final tech = StaffUser.fromJson({
      'user': {
        'id': 2,
        'permissions': ['staff_app.use'],
        'screens': ['duty'],
      },
    });
    expect(featuresFor(manager).map((f) => f.screen), contains('staff_map'));
    expect(
      featuresFor(tech).map((f) => f.screen),
      isNot(contains('staff_map')),
    );
  });

  testWidgets('lists staff on duty and shows one person\'s day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final erp = FakeErp({
      'GET /staff-map': (o) => (
        200,
        _payload(selected: int.tryParse('${o.queryParameters['user']}')),
      ),
    });
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
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StaffMapScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('On duty (2)'), findsOneWidget);
    expect(find.text('On a ticket · 2 min ago'), findsOneWidget);
    expect(find.text('No signal · no location yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-staff-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-staff-8')), findsNothing);
    expect(find.byKey(const ValueKey('map-ticket-42')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-row-7')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(erp.calls.last, 'GET /staff-map');
    expect(erp.requests.last.queryParameters['user'], 7);
    expect(find.byKey(const ValueKey('map-detail')), findsOneWidget);
    expect(find.text('4.2 km'), findsOneWidget);
    expect(find.text('71%'), findsOneWidget);
    expect(find.textContaining('1 location points today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-show-all')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(erp.requests.last.queryParameters.containsKey('user'), isFalse);
    expect(find.byKey(const ValueKey('map-detail')), findsNothing);

    // Stop the 30-second refresh.
    await tester.pumpWidget(const SizedBox());
  });
}
