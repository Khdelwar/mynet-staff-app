import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:mynet_staff/ui/olt_screens.dart';
import 'package:mynet_staff/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Read-only OLT screens from /olts, /olts/{id}, /olts/{id}/onus.

final _routes = <String, (int, Object?) Function(RequestOptions)>{
  'GET /olts': (_) => (
    200,
    {
      'olts': [
        {
          'id': 1,
          'name': 'OLT-Main',
          'type': 'VSOL-EPON',
          'pop': 'Mirpur',
          'is_active': true,
          'reachable': false,
          'onus': 3,
          'online': 2,
          'offline': 1,
          'weak_rx': 1,
        },
      ],
      'alerts': [
        {'olt': 'OLT-Main', 'message': 'PON 2 down', 'level': 'critical'},
      ],
      'unmatched': 2,
    },
  ),
  'GET /olts/1': (_) => (
    200,
    {
      'olt': {'id': 1, 'name': 'OLT-Main', 'pop': 'Mirpur'},
      'totals': {'onus': 3, 'online': 2, 'offline': 1, 'weak_rx': 1},
      'ports': [
        {
          'port': '1/1/2',
          'label': 'EPON0/2',
          'onus': 1,
          'online': 0,
          'offline': 1,
        },
        {
          'port': '1/1/1',
          'label': 'EPON0/1',
          'onus': 2,
          'online': 2,
          'offline': 0,
        },
      ],
    },
  ),
  'GET /olts/1/onus': (o) {
    final page = int.tryParse('${o.queryParameters['page']}') ?? 1;
    return (
      200,
      {
        'label': 'EPON0/1',
        'avg_rx': -24.25,
        'onus': [
          {
            'id': page,
            'serial': 'ABCD000$page',
            'onu': 'EPON0/1:$page',
            'status': 'online',
            'status_label': 'Online',
            'signal_level': 'ok',
            'rx_dbm': -20.5,
            'client': {'id': 9, 'name': 'Kamal', 'code': 'C-77'},
          },
        ],
        'page': page,
        'last_page': 2,
        'total': 2,
      },
    );
  },
};

Future<FakeErp> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final erp = FakeErp(_routes);
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
  return erp;
}

void main() {
  test('Home: OLT button for the ERP olt screen permissions', () {
    StaffUser u(List<String> p) =>
        StaffUser.fromJson({'id': 1, 'permissions': p});
    expect(featuresFor(u(['olt.view'])).map((f) => f.screen), contains('olt'));
    expect(
      featuresFor(u(['olt.create_own'])).map((f) => f.screen),
      contains('olt'),
    );
    expect(
      featuresFor(u(['clients.check_dbm'])).map((f) => f.screen),
      isNot(contains('olt')),
    );
  });

  test('Rx colours follow the web', () {
    expect(rxColor(-20, 'ok'), ErpColors.accent700);
    expect(rxColor(-26, null), const Color(0xFFEA580C));
    expect(rxColor(-29, null), ErpColors.rose700);
    expect(rxColor(null, 'critical'), ErpColors.slate500);
  });

  testWidgets('OLT list, ports, then a port\'s ONUs with filter and paging', (
    tester,
  ) async {
    final erp = await _pump(tester, const OltListScreen());
    expect(find.text('OLT-Main'), findsOneWidget);
    expect(find.text('Unreachable'), findsOneWidget);
    expect(find.text('Unmatched ONUs (2)'), findsOneWidget);
    expect(find.text('OLT-Main · PON 2 down'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('olt-1')));
    await tester.pumpAndSettle();
    expect(find.text('EPON0/2'), findsOneWidget);
    expect(find.text('Whole port down'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('port-1/1/1')));
    await tester.pumpAndSettle();
    expect(find.text('Kamal · C-77'), findsOneWidget);
    expect(find.text('-20.50 dBm'), findsOneWidget);
    expect(find.text('Average Rx: -24.25 dBm'), findsOneWidget);
    expect(erp.requests.last.queryParameters['port'], '1/1/1');

    await tester.tap(find.byKey(const ValueKey('onu-filter-weak_rx')));
    await tester.pumpAndSettle();
    expect(erp.requests.last.queryParameters['filter'], 'weak_rx');

    await tester.tap(find.byKey(const ValueKey('onu-more')));
    await tester.pumpAndSettle();
    expect(erp.requests.last.queryParameters['page'], 2);
    expect(find.byKey(const ValueKey('onu-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('onu-more')), findsNothing);
  });
}
