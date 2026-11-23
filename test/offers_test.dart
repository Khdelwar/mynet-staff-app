import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/assign_screen.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:mynet_staff/ui/offers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

const _offer = {
  'id': 5,
  'distance_m': 640,
  'seconds_left': 87,
  'ticket': {
    'id': 41,
    'subject': 'No internet',
    'client': {'name': 'Karim'},
  },
};

Future<void> _open(
  WidgetTester tester,
  FakeErp erp,
  Widget home,
  Map<String, Object?> user,
) async {
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  erp.routes['GET /me'] = (_) => (200, {'user': user, ...user});
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
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('offers stay hidden without the permission or the screen', () {
    final technician = StaffUser.fromJson({
      'permissions': ['tickets.view'],
      'screens': ['tickets', 'offers'],
    });
    expect(
      featuresFor(technician).any((f) => f.permission == 'tickets.update'),
      isFalse,
    );
    final noScreen = StaffUser.fromJson({
      'permissions': ['tickets.update'],
      'screens': ['tickets'],
    });
    expect(
      featuresFor(noScreen).any((f) => f.permission == 'tickets.update'),
      isFalse,
    );
    final office = StaffUser.fromJson({
      'permissions': ['tickets.assign', 'tickets.view'],
      'screens': ['tickets'],
    });
    expect(
      featuresFor(office).map((f) => f.permission),
      containsAll(['tickets.view', 'tickets.assign']),
    );
  });

  testWidgets('accept and reject call the ERP', (tester) async {
    final erp = FakeErp({
      'GET /offers': (_) => (
        200,
        {
          'offers': [_offer],
        },
      ),
      'POST /offers/5/accept': (_) => (
        200,
        {
          'ok': true,
          'ticket': {'id': 41, 'subject': 'No internet'},
        },
      ),
      'POST /offers/5/reject': (_) => (200, {'ok': true}),
    });
    await _open(tester, erp, const OffersScreen(), {
      'id': 7,
      'permissions': ['tickets.update'],
      'screens': ['offers'],
      'roles': ['technician'],
    });
    expect(find.text('No internet'), findsOneWidget);
    expect(find.textContaining('640'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accept-5')));
    await tester.pumpAndSettle();
    expect(erp.calls, contains('POST /offers/5/accept'));
    expect(find.text('You took ticket #41.'), findsOneWidget);
  });

  testWidgets('a closed offer shows the ERP message', (tester) async {
    final erp = FakeErp({
      'GET /offers': (_) => (
        200,
        {
          'offers': [_offer],
        },
      ),
      'POST /offers/5/reject': (_) => (
        422,
        {
          'message': 'This offer is closed',
          'errors': {
            'offer': ['This offer is closed'],
          },
        },
      ),
    });
    await _open(tester, erp, const OffersScreen(), {
      'id': 7,
      'permissions': ['tickets.update'],
      'roles': ['technician'],
    });
    await tester.tap(find.byKey(const ValueKey('reject-5')));
    await tester.pumpAndSettle();
    expect(find.text('This offer is closed'), findsOneWidget);
  });

  testWidgets('the office can assign or start an offer', (tester) async {
    final erp = FakeErp({
      'GET /tickets': (_) => (
        200,
        {
          'tickets': [
            {
              'id': 41,
              'subject': 'No internet',
              'client': {'name': 'Karim'},
            },
          ],
        },
      ),
      'GET /tickets/41/suggestions': (_) => (
        200,
        {
          'suggestions': [
            {
              'user': {'id': 7, 'name': 'Rahim', 'phone': '017'},
              'score': 71.4,
              'distance_m': 640,
              'eta_min': 3,
              'open_tickets': 0,
              'busy': false,
              'same_area': true,
              'reasons': {'distance': 47.9, 'workload': 20},
            },
          ],
        },
      ),
      'POST /tickets/41/assign': (_) => (200, {'ok': true}),
      'POST /tickets/41/offer': (_) => (
        200,
        {
          'ok': true,
          'offered_to': {'id': 7, 'name': 'Rahim', 'distance_m': 640},
        },
      ),
    });
    await _open(tester, erp, const AssignScreen(), {
      'id': 1,
      'permissions': ['tickets.assign', 'tickets.view', 'tickets.manage'],
      'screens': ['tickets'],
      'roles': ['manager'],
    });
    expect(find.text('No internet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assign-ticket-41')));
    await tester.pumpAndSettle();
    expect(find.text('Rahim'), findsOneWidget);
    expect(find.textContaining('71.4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assign-7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final assign =
        erp.requests.lastWhere((r) => r.uri.path.endsWith('/assign')).data
            as Map;
    expect(assign['user_id'], 7);

    await tester.tap(find.byKey(const ValueKey('start-offer')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(erp.calls, contains('POST /tickets/41/offer'));
  });
}
