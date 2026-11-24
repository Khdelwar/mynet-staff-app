import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/clients.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/clients_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

Map<String, Object?> _row() => {
  'id': 9,
  'code': 'C-1001',
  'name': 'Karim',
  'phone': '01711000001',
  'status': 'active',
  'due': 600,
  'advance': 0,
  'balance': -600,
  'seen_online': true,
};

void main() {
  test('detail from the API keeps the ERP receipt', () async {
    final erp = FakeErp({
      'GET /clients/9': (_) => (
        200,
        {
          'client': {
            'id': 9,
            'recent_payments': [
              {'id': 812, 'receipt_no': 'R-000812', 'amount': 600},
            ],
          },
        },
      ),
    });
    final detail = await StaffApi(dio: erp.dio).client(9);
    expect(detail.recentPayments.single.receiptNo, 'R-000812');
  });

  test('detail keeps the ERP receipt', () {
    final detail = ClientDetail.fromJson({
      'client': {
        'id': 9,
        'recent_payments': [
          {'id': 812, 'receipt_no': 'R-000812', 'amount': 600},
        ],
      },
    });
    expect(detail.recentPayments.single.receiptNo, 'R-000812');
  });

  testWidgets('lists clients and opens the ERP detail', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1, 'name': 'Rahim'},
        },
      ),
      'GET /clients': (o) => (
        200,
        {
          'clients': [_row()],
          'page': 1,
          'last_page': 1,
          'total': 1,
        },
      ),
      'GET /clients/9': (_) => (
        200,
        {
          'client': {
            ..._row(),
            'pppoe_username': 'karim',
            'address': 'House 1',
            'package': {'name': '10 Mbps', 'price': 500},
            'onu': {'sn': 'HWTC123', 'last_rx_dbm': -22.1},
            'open_tickets': [
              {'id': 41, 'subject': 'No internet', 'status': 'assigned'},
            ],
            'recent_payments': [
              {
                'id': 812,
                'receipt_no': 'R-000812',
                'amount': 600,
                'approval_status': 'pending',
              },
            ],
            'can': {'update': false},
          },
        },
      ),
      'GET /clients/9/connection': (_) =>
          (200, {'online': true, 'disconnects_24h': 2}),
    });
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore()..values[sessionTokenKey] = 'tok',
        ),
        apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
      ],
    );
    addTearDown(container.dispose);
    container.read(authProvider);
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ClientListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Karim'), findsOneWidget);
    final list = erp.requests.firstWhere(
      (r) => r.uri.path.endsWith('/clients'),
    );
    expect(list.uri.queryParameters.containsKey('q'), isFalse);

    await tester.enterText(find.byKey(const ValueKey('client-search')), 'ka');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final search = erp.requests.lastWhere(
      (r) => r.uri.path.endsWith('/clients'),
    );
    expect(search.uri.queryParameters['q'], 'ka');

    await tester.tap(find.byKey(const ValueKey('client-9')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('client-detail')), findsOneWidget);
    expect(find.text('karim'), findsOneWidget);
    expect(find.text('-600'), findsOneWidget);
    expect(find.text('No internet', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('client-connection')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('client-connection')));
    await tester.pumpAndSettle();
    expect(find.text('The line is online.'), findsOneWidget);
    expect(find.text('2 disconnects in 24 hours'), findsOneWidget);
    expect(erp.calls, contains('GET /clients/9/connection'));
  });
}
