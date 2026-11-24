import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/collection_screen.dart';
import 'package:mynet_staff/ui/due_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeErp erp,
  Widget home,
) async {
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
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
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('cash uses the ERP receipt and one request key', (tester) async {
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {
            'id': 1,
            'name': 'Rakib',
            'permissions': ['collection.collect'],
          },
        },
      ),
      'GET /collection/summary': (_) => (
        200,
        {
          'collected_today': 800,
          'in_hand': 1500,
          'not_handed_over': 1500,
          'expense_available': 200,
          'hold': {'blocked': false},
          'can': {
            'cash': true,
            'gateway': false,
            'expense': false,
            'handover': false,
          },
        },
      ),
      'GET /collection/clients': (_) => (
        200,
        {
          'clients': [
            {
              'id': 9,
              'code': 'C-1001',
              'name': 'Karim',
              'due': 600,
              'balance': -600,
            },
          ],
        },
      ),
      'POST /collection/cash': (o) => (
        201,
        {
          'replayed': false,
          'payment': {
            'id': 812,
            'receipt_no': 'R-000812',
            'amount': o.data['amount'],
            'approval_status': 'pending',
            'paid_sms': 'after_approval',
            'client': {'id': 9, 'name': 'Karim'},
          },
        },
      ),
    });
    await _pump(tester, erp, const CollectionScreen());
    expect(find.text('1500'), findsWidgets);
    expect(find.text('2300'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('collect-cash')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('collect-search')), 'ka');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-client-9')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('collect-amount')), '600');
    await tester.tap(find.byKey(const ValueKey('collect-submit')));
    await tester.pumpAndSettle();

    final body =
        erp.requests.lastWhere((r) => r.uri.path.endsWith('/cash')).data as Map;
    expect(body['client_id'], 9);
    expect(body['amount'], 600);
    expect((body['request_key'] as String).length, greaterThanOrEqualTo(8));
    expect(find.text('R-000812'), findsOneWidget);
    expect(
      find.text('The client is told after the office approves.'),
      findsOneWidget,
    );
  });

  testWidgets('the due list shows the ERP due', (tester) async {
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1, 'name': 'Rakib'},
        },
      ),
      'GET /due-list': (_) => (
        200,
        {
          'clients': [
            {'id': 9, 'code': 'C-1001', 'name': 'Karim', 'due': 600},
          ],
          'page': 1,
          'last_page': 1,
          'total': 1,
        },
      ),
    });
    await _pump(tester, erp, const DueListScreen());
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
  });

  testWidgets('save never does nothing: it says what is missing, then saved', (
    tester,
  ) async {
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {
            'id': 1,
            'name': 'Rakib',
            'permissions': ['collection.collect'],
          },
        },
      ),
      'GET /collection/clients': (_) => (
        200,
        {
          'clients': [
            {'id': 9, 'code': 'C-1001', 'name': 'Karim', 'due': 500},
          ],
        },
      ),
      'POST /collection/gateway': (o) => (
        201,
        {
          'replayed': false,
          'payment': {
            'id': 813,
            'receipt_no': 'R-000813',
            'amount': o.data['amount'],
            'method': 'nagad',
            'approval_status': 'pending',
            'paid_sms': 'after_approval',
            'client': {'id': 9, 'name': 'Karim'},
          },
        },
      ),
    });
    await _pump(tester, erp, const CollectScreen(cash: false));

    // No client yet: a clear message, nothing sent.
    await tester.tap(find.byKey(const ValueKey('collect-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Pick the client first.'), findsOne);

    // The search button works too, not only the keyboard.
    await tester.enterText(find.byKey(const ValueKey('collect-search')), 'ka');
    await tester.tap(find.byKey(const ValueKey('collect-search-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-client-9')));
    await tester.pumpAndSettle();
    // The picked client is shown on its own; the due fills the amount.
    expect(find.byKey(const ValueKey('collect-picked')), findsOne);
    expect(find.byKey(const ValueKey('pay-client-9')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('collect-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the TrxID.'), findsOne);
    expect(erp.calls, isNot(contains('POST /collection/gateway')));

    await tester.enterText(find.byKey(const ValueKey('collect-txn')), 'NG1');
    await tester.tap(find.byKey(const ValueKey('collect-submit')));
    await tester.pumpAndSettle();

    final body =
        erp.requests.lastWhere((r) => r.uri.path.endsWith('/gateway')).data
            as Map;
    expect(body['amount'], 500);
    expect(body['txn_id'], 'NG1');
    expect(find.text('Saved. The money is taken.'), findsWidgets);
    expect(find.text('Waiting for office approval'), findsOne);

    // "Take another" gives an empty form for the next client.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('collect-another')));
    await tester.tap(find.byKey(const ValueKey('collect-another')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('collect-search')), findsOne);
  });
}
