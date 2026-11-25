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
    // Fully on screen, not just its top edge.
    await tester.ensureVisible(find.byKey(const ValueKey('client-connection')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('client-connection')));
    await tester.pumpAndSettle();
    expect(find.text('The line is online.'), findsOneWidget);
    expect(find.text('2 disconnects in 24 hours'), findsOneWidget);
    expect(erp.calls, contains('GET /clients/9/connection'));
  });

  testWidgets('search and filters work as the web client list', (tester) async {
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
          'clients': [
            {
              ..._row(),
              'display_status': 'due',
              'pppoe_username': 'karim01',
              'pop': 'Mirpur',
            },
          ],
          'page': 1,
          'last_page': 1,
          'total': 1,
        },
      ),
      'GET /clients/suggest': (o) => (
        200,
        {
          'clients': [_row()],
          'exact_id': o.queryParameters['q'] == 'C-1001' ? 9 : null,
        },
      ),
      'GET /clients/filters': (o) => (
        200,
        {
          'directories': [
            {'value': 'all', 'label': 'All clients'},
            {'value': 'expired', 'label': 'Expired clients'},
          ],
          'statuses': [
            {'value': 'due', 'label': 'Has due'},
          ],
          'pops': [
            {'id': 3, 'name': 'Mirpur'},
          ],
          'packages': [],
          'sorts': ['id', 'name'],
        },
      ),
      'GET /clients/9': (_) => (
        200,
        {
          'client': {..._row(), 'can': {}},
        },
      ),
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

    // The ERP's own label for the status, and the language asked for.
    expect(find.textContaining('Has due'), findsOne);
    expect(find.textContaining('karim01'), findsOne);
    expect(find.text('1 clients'), findsOne);
    final filters = erp.requests.firstWhere(
      (r) => r.uri.path.endsWith('/clients/filters'),
    );
    expect(filters.uri.queryParameters['lang'], 'en');

    // Results follow the typing, without pressing Enter.
    await tester.enterText(find.byKey(const ValueKey('client-search')), 'kar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      erp.requests.last.uri.queryParameters['q'],
      'kar',
      reason: 'live search',
    );

    // Filters: the web's choices; the list asks the ERP with them.
    await tester.tap(find.byKey(const ValueKey('client-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-directory-expired')));
    await tester.tap(find.byKey(const ValueKey('filter-pop_id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mirpur').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-apply')));
    await tester.pumpAndSettle();
    final filtered = erp.requests.lastWhere(
      (r) => r.uri.path.endsWith('/clients'),
    );
    expect(filtered.uri.queryParameters['directory'], 'expired');
    expect(filtered.uri.queryParameters['pop_id'], '3');
    expect(filtered.uri.queryParameters['q'], 'kar');

    // Enter on an exact client ID opens that client, as the web does.
    await tester.enterText(
      find.byKey(const ValueKey('client-search')),
      'C-1001',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('client-detail')), findsOneWidget);
  });
}
