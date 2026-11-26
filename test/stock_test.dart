import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:mynet_staff/ui/stock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Read-only stock: GET /stock, the ERP decides how much is shown.

Map<String, Object?> _mine() => {
  'can_view_all': false,
  'mine': {
    'items': [
      {
        'id': 5,
        'category': 'ONU',
        'model': 'HG8546',
        'serial': 'ONU-MINE',
        'status': 'assigned_tech',
        'status_label': 'Assigned to tech',
      },
    ],
    'parts': [
      {'id': 3, 'name': 'Patch cord', 'unit': 'pcs', 'quantity': 3},
    ],
  },
  'parts_in_office': [
    {'id': 3, 'name': 'Patch cord', 'unit': 'pcs', 'in_stock': 40},
  ],
};

Map<String, Object?> _all(Map<String, dynamic> q) {
  final page = int.tryParse('${q['page']}') ?? 1;
  return {
    ..._mine(),
    'can_view_all': true,
    'counts': {
      'statuses': [
        {'status': 'in_stock', 'label': 'In stock', 'count': 120},
        {'status': 'damaged', 'label': 'Damaged', 'count': 2},
      ],
      'low_stock_alerts': 1,
    },
    'categories': [
      {'id': 1, 'name': 'ONU'},
    ],
    'items': {
      'data': [
        {
          'id': 100 + page,
          'category': 'ONU',
          'serial': 'SN-$page',
          'status': 'issued_client',
          'status_label': 'Issued to client',
          'client': {'id': 9, 'name': 'Kamal', 'code': 'C-77'},
        },
      ],
      'page': page,
      'last_page': 2,
      'total': 2,
    },
    'parts': {
      'data': [
        {
          'id': 4,
          'name': 'TJ box',
          'unit': 'pcs',
          'quantity': 2,
          'low_stock_threshold': 5,
          'low': true,
        },
      ],
      'page': 1,
      'last_page': 1,
      'total': 1,
    },
  };
}

Future<FakeErp> _pump(WidgetTester tester, FakeErp erp) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
        home: const StockScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return erp;
}

void main() {
  test('Home: stock button for any of the ERP screen permissions', () {
    StaffUser u(List<String> p) =>
        StaffUser.fromJson({'id': 1, 'permissions': p});
    expect(
      featuresFor(u(['inventory.use'])).map((f) => f.screen),
      contains('inventory'),
    );
    expect(
      featuresFor(u(['inventory.manage'])).map((f) => f.screen),
      contains('inventory'),
    );
    expect(
      featuresFor(u(['inventory.sell'])).map((f) => f.screen),
      isNot(contains('inventory')),
    );
  });

  testWidgets('a technician sees what they hold and the office parts', (
    tester,
  ) async {
    await _pump(tester, FakeErp({'GET /stock': (_) => (200, _mine())}));
    expect(find.text('In my hand'), findsOneWidget);
    expect(find.text('ONU · HG8546'), findsOneWidget);
    expect(find.text('Assigned to tech'), findsOneWidget);
    expect(find.text('3 pcs'), findsOneWidget);
    expect(find.text('40 pcs'), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-tabs')), findsNothing);
  });

  testWidgets('inventory.view gets the lists, filters and paging', (
    tester,
  ) async {
    final erp = await _pump(
      tester,
      FakeErp({'GET /stock': (o) => (200, _all(o.queryParameters))}),
    );
    await tester.tap(find.text('All stock'));
    await tester.pumpAndSettle();

    expect(find.text('In stock · 120'), findsOneWidget);
    expect(find.text('1 things are low (under their limit).'), findsOneWidget);
    expect(find.text('Items (2)'), findsOneWidget);
    expect(find.text('SN-1 · Kamal · C-77'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-status-damaged')));
    await tester.pumpAndSettle();
    expect(erp.requests.last.queryParameters['status'], 'damaged');

    await tester.enterText(find.byKey(const ValueKey('stock-search')), 'C-77');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(erp.requests.last.queryParameters['q'], 'C-77');

    await tester.tap(find.byKey(const ValueKey('stock-items-more')));
    await tester.pumpAndSettle();
    expect(erp.requests.last.queryParameters['page'], 2);
    expect(find.text('SN-2 · Kamal · C-77'), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-items-more')), findsNothing);
  });
}
