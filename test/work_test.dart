import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/field/photos.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/field.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/collection_screen.dart';
import 'package:mynet_staff/ui/kpi_card.dart';
import 'package:mynet_staff/api/work.dart';
import 'package:mynet_staff/ui/work_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// STF-03b, STF-06b, STF-08, STF-09 screens against a fake ERP: the app sends
/// what the API asks for (with a request_key where money or stock moves) and
/// shows what the ERP answers.

class _FakePhotos implements PhotoPicker {
  @override
  Future<String?> pick(PhotoSource source) async => 'test/fake_erp.dart';
}

Map<String, dynamic> _me(List<String> permissions) => {
  'user': {'id': 1, 'name': 'Rakib', 'permissions': permissions},
};

Future<void> _pump(WidgetTester tester, FakeErp erp, Widget home) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      secretStoreProvider.overrideWithValue(
        MemorySecretStore()..values[sessionTokenKey] = 'tok',
      ),
      apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
      photoPickerProvider.overrideWithValue(_FakePhotos()),
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
}

Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('ask-text')), text);
  await tester.tap(find.byKey(const ValueKey('ask-ok')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows the ERP boxes as the web cards', (tester) async {
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['dashboard.view'])),
      'GET /dashboard': (_) => (
        200,
        {
          'kpis': [
            {
              'key': 'kpi_total',
              'label': 'Total clients',
              'value': 1520,
              'money': false,
            },
            {
              'key': 'kpi_due',
              'label': 'Due amount',
              'value': 125430.5,
              'money': true,
            },
            {
              'key': 'kpi_expired_online',
              'label': 'Expired but online',
              'value': 0,
              'money': false,
            },
          ],
        },
      ),
    });
    await _pump(tester, erp, const DashboardScreen());

    expect(find.byKey(const ValueKey('kpi-kpi_total')), findsOneWidget);
    expect(find.text('Total clients'), findsOneWidget);
    expect(find.text('1,520'), findsOneWidget);
    // Money in whole taka with the sign, as the web dashboard card.
    expect(find.text('৳ 125,431'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  test('card colours follow the web dashboard', () {
    Kpi k(String key, num v) => Kpi(key: key, label: key, value: v);
    expect(kpiStyle(k('kpi_due', 5)).$2, KpiTone.amber);
    expect(kpiStyle(k('kpi_expired', 5)).$2, KpiTone.red);
    expect(kpiStyle(k('kpi_expired_online', 0)).$2, KpiTone.navy);
    expect(kpiStyle(k('kpi_expired_online', 3)).$2, KpiTone.red);
    expect(kpiStyle(k('kpi_active_offline', 2)).$2, KpiTone.amber);
    expect(kpiStyle(k('something_new', 1)).$2, KpiTone.brand);
    expect(
      kpiValue(const Kpi(label: 'x', value: 999.6, money: true)),
      '৳ 1,000',
    );
  });

  testWidgets('parts used on a ticket: one request key, kept on retry', (
    tester,
  ) async {
    final sent = <Map>[];
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['inventory.use'])),
      'GET /tickets/41/materials': (_) => (
        200,
        {
          'materials': [],
          'parts': [
            {'id': 4, 'name': 'Patch cord', 'unit': 'pcs', 'in_stock': 5},
          ],
          'purposes': ['new_connection', 'repair'],
          'default_purpose': 'repair',
        },
      ),
      'POST /tickets/41/materials': (o) {
        sent.add(o.data as Map);
        if (sent.length == 1) return (503, {'message': 'Busy'});
        return (201, {'replayed': false, 'materials': []});
      },
    });
    await _pump(
      tester,
      erp,
      const MaterialsScreen(ticketId: 41, canUse: true, canScan: true),
    );

    await tester.tap(find.byKey(const ValueKey('use-parts')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('qty-4')), '2');
    await tester.tap(find.byKey(const ValueKey('parts-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('parts-save')));
    await tester.pumpAndSettle();

    expect(sent, hasLength(2));
    expect(sent.first['lines'], [
      {'consumable_id': 4, 'quantity': 2},
    ]);
    expect(sent.first['purpose'], 'repair');
    expect(sent.first['request_key'], sent.last['request_key']);
    expect(find.byKey(const ValueKey('materials')), findsOne);
  });

  testWidgets('install shows the ERP refusal on the field', (tester) async {
    Map? body;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['tickets.update'])),
      'GET /tickets/50/install': (_) => (
        200,
        {
          'can_install': true,
          'pop_id': 2,
          'pops': [
            {'id': 2, 'name': 'Mirpur'},
          ],
          'routers': [
            {'id': 5, 'name': 'MK-1'},
          ],
        },
      ),
      'POST /tickets/50/install': (o) {
        body = o.data as Map;
        return (
          422,
          {
            'message': 'Need ONU',
            'errors': {
              'onu_sn': ['Give the ONU serial or MAC.'],
            },
          },
        );
      },
    });
    await _pump(tester, erp, const InstallScreen(ticketId: 50));

    await tester.tap(find.byKey(const ValueKey('install-save')));
    await tester.pumpAndSettle();

    expect(body!['pop_id'], 2);
    expect(body!['router_id'], 5);
    expect(find.text('Give the ONU serial or MAC.'), findsOne);
  });

  testWidgets('a scanned product is sold to a client', (tester) async {
    Map? sale;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['inventory.sell', 'clients.view'])),
      'GET /sales': (_) => (
        200,
        {
          'awaiting_client': [],
          'recent': [],
          'digital_methods': ['bkash'],
        },
      ),
      'POST /sales/scan': (_) => (
        200,
        {
          'found': {
            'kind': 'item',
            'id': 3,
            'code': 'ONU-1',
            'name': 'ONU ONU-1',
          },
        },
      ),
      'GET /clients': (_) => (
        200,
        {
          'clients': [
            {'id': 9, 'code': 'C-1001', 'name': 'Karim'},
          ],
          'page': 1,
          'last_page': 1,
          'total': 1,
        },
      ),
      'POST /sales': (o) {
        sale = o.data as Map;
        return (
          201,
          {
            'replayed': false,
            'sale': {'id': 1, 'status': 'done', 'cash_to_handover': true},
          },
        );
      },
    });
    await _pump(tester, erp, const SalesScreen());

    await tester.tap(find.byKey(const ValueKey('new-sale')));
    await tester.pumpAndSettle();
    await _answer(tester, 'ONU-1');
    expect(find.text('ONU ONU-1'), findsOne);

    await tester.enterText(find.byKey(const ValueKey('sell-price')), '2200');
    await tester.tap(find.byKey(const ValueKey('sell-client')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('client-search')),
      'Karim',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim · C-1001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sell-save')));
    await tester.pumpAndSettle();

    expect(sale!['code'], 'ONU-1');
    expect(sale!['price'], 2200);
    expect(sale!['payment'], 'cash');
    expect(sale!['client_id'], 9);
    expect((sale!['request_key'] as String).isNotEmpty, isTrue);
    expect(
      find.text('Sold. The cash goes into your day-end handover.'),
      findsOne,
    );
  });

  testWidgets('recharge shows the quote, then sends the chosen method', (
    tester,
  ) async {
    Map? body;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['clients.recharge'])),
      'GET /clients/9/recharge-quote': (_) => (
        200,
        {
          'months': 1,
          'amount': 600,
          'pay_total': 600,
          'old_expiry': '2026-11-20',
          'new_expiry': '2026-12-24',
          'wallet_charge': 450,
          'wallet_balance': 1000,
          'wallet_after': 550,
          'methods': [
            {'id': 'reseller_wallet', 'label': 'Wallet'},
          ],
          'pending': false,
        },
      ),
      'POST /clients/9/recharge': (o) {
        body = o.data as Map;
        return (
          201,
          {
            'replayed': false,
            'client': {'id': 9, 'expiry_date': '2026-12-24'},
          },
        );
      },
    });
    await _pump(
      tester,
      erp,
      const RechargeScreen(clientId: 9, clientName: 'Karim'),
    );

    // The ERP's numbers, as sent.
    expect(find.text('2026-12-24'), findsOne);
    expect(find.text('550'), findsOne);

    await tester.tap(find.byKey(const ValueKey('recharge-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recharge-confirm')));
    await tester.pumpAndSettle();

    expect(body!['months'], 1);
    expect(body!['method'], 'reseller_wallet');
    expect((body!['request_key'] as String).isNotEmpty, isTrue);
  });

  testWidgets('an expense goes with its receipt photo', (tester) async {
    Object? sent;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['collection.collect'])),
      'GET /collection/summary': (_) => (
        200,
        {
          'collected_today': 0,
          'in_hand': 600,
          'can': {
            'cash': true,
            'gateway': false,
            'expense': true,
            'handover': true,
          },
        },
      ),
      'POST /collection/expenses': (o) {
        sent = o.data;
        return (
          201,
          {
            'replayed': false,
            'expense': {'id': 3, 'status': 'pending_approval'},
          },
        );
      },
    });
    await _pump(tester, erp, const CollectionScreen());

    await tester.tap(find.text('Expense').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('money-amount')), '80');
    await tester.enterText(find.byKey(const ValueKey('money-note')), 'Fuel');
    await tester.tap(find.byKey(const ValueKey('expense-receipt')));
    await tester.pumpAndSettle();
    expect(find.text('Receipt photo added'), findsOne);
    // The photo is read from disk: give real time between frames.
    await tester.tap(find.byKey(const ValueKey('money-save')));
    for (var i = 0; i < 40 && sent == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(sent, isA<FormData>());
    final form = sent as FormData;
    expect(form.files.single.key, 'receipt');
    expect(Map.fromEntries(form.fields), containsPair('note', 'Fuel'));
  });

  testWidgets('own HR: ask for an advance for this month', (tester) async {
    Map? body;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['hr.self'])),
      'GET /hr/me': (_) => (
        200,
        {
          'month': '2026-11',
          'attendance': {
            'counts': {'present': 20},
            'late_minutes': 15,
          },
          'leaves': [],
          'advances': [],
        },
      ),
      'POST /hr/advances': (o) {
        body = o.data as Map;
        return (201, {'ok': true});
      },
    });
    await _pump(tester, erp, const HrScreen());

    expect(find.text('present'), findsOne);
    await tester.tap(find.byKey(const ValueKey('ask-advance')));
    await tester.pumpAndSettle();
    await _answer(tester, '2000');

    expect(body!['amount'], 2000);
    expect(body!['month'], matches(RegExp(r'^\d{4}-\d{2}$')));
    expect(find.text('Request sent.'), findsOne);
  });
}
