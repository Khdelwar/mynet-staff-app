import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/field/location.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/field.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/field_info_screens.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

class _Here implements LocationReader {
  const _Here(this.fix);
  final GeoFix? fix;

  @override
  Future<GeoFix?> current() async => fix;
}

const _dhaka = GeoFix(latitude: 23.81, longitude: 90.41);

Future<void> _pump(
  WidgetTester tester,
  FakeErp erp,
  Widget home, {
  GeoFix? here = _dhaka,
}) async {
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      secretStoreProvider.overrideWithValue(
        MemorySecretStore()..values[sessionTokenKey] = 'tok',
      ),
      apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
      locationReaderProvider.overrideWithValue(_Here(here)),
    ],
  );
  addTearDown(container.dispose);
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

FakeErp _erp(Map<String, (int, Object?) Function(dynamic)> routes) => FakeErp({
  'GET /me': (_) => (
    200,
    {
      'user': {'id': 1, 'name': 'Tech'},
    },
  ),
  for (final e in routes.entries) e.key: (o) => e.value(o),
});

void main() {
  test('home shows the field buttons the ERP lists, not more', () {
    final user = StaffUser.fromJson({
      'user': {
        'id': 1,
        'permissions': ['inventory.use', 'olt.view', 'fiber.view'],
        // A reseller: the ERP leaves out stock and fiber.
        'screens': ['olt'],
      },
    });
    expect(featuresFor(user).map((f) => f.screen), ['olt']);

    final staff = StaffUser.fromJson({
      'user': {
        'id': 2,
        'permissions': [
          'inventory.view',
          'staff.location.view',
          'olt.create_own',
          'fiber.manage',
        ],
        'screens': ['inventory', 'staff_map', 'olt', 'fiber'],
      },
    });
    expect(featuresFor(staff).map((f) => f.screen), [
      'inventory',
      'staff_map',
      'olt',
      'fiber',
    ]);
  });

  testWidgets('stock shows my items, parts (low marked) and categories', (
    tester,
  ) async {
    final erp = _erp({
      'GET /stock': (_) => (
        200,
        {
          'in_hand': [
            {'id': 5, 'category': 'ONU', 'model': 'V2802', 'serial': 'SN-1'},
          ],
          'parts': [
            {
              'id': 9,
              'name': 'Patch cord',
              'unit': 'pcs',
              'quantity': 3,
              'low': true,
            },
          ],
          'categories': [
            {'id': 1, 'name': 'Router', 'in_stock': 4},
          ],
        },
      ),
    });
    await _pump(tester, erp, const StockScreen());

    expect(find.text('ONU · V2802'), findsOne);
    expect(find.text('SN-1'), findsOne);
    expect(find.text('3 pcs · low'), findsOne);
    expect(find.text('Router'), findsOne);
    expect(find.text('Items in the store'), findsOne);
  });

  testWidgets('stock without inventory.view hides the store list', (
    tester,
  ) async {
    final erp = _erp({
      'GET /stock': (_) =>
          (200, {'in_hand': [], 'parts': [], 'categories': null}),
    });
    await _pump(tester, erp, const StockScreen());
    expect(find.text('Items in the store'), findsNothing);
    expect(find.text('Nothing here.'), findsNWidgets(2));
  });

  testWidgets('staff on duty sends my location and shows state and distance', (
    tester,
  ) async {
    final erp = _erp({
      'GET /staff-map': (_) => (
        200,
        {
          'staff': [
            {
              'id': 3,
              'name': 'Rahim',
              'state': 'busy',
              'lat': 23.8,
              'lng': 90.4,
              'phone': '01700000000',
              'seen_minutes': 2,
              'distance_m': 1500,
              'ticket': {'subject': 'No internet'},
            },
          ],
        },
      ),
    });
    await _pump(tester, erp, const StaffMapScreen());

    expect(
      find.text('Working · No internet · 1.5 km away · 2 min ago'),
      findsOne,
    );
    final sent = erp.requests.last.uri.queryParameters;
    expect(sent['lat'], '23.81');
    expect(sent['lng'], '90.41');
  });

  testWidgets('OLT list opens the OLT with problem ONUs, then all', (
    tester,
  ) async {
    final erp = _erp({
      'GET /olts': (_) => (
        200,
        {
          'olts': [
            {
              'id': 7,
              'name': 'Main OLT',
              'status': 'online',
              'pop': 'Mirpur',
              'onu': {
                'total': 10,
                'online': 9,
                'offline': 1,
                'weak': 2,
                'critical': 1,
              },
            },
          ],
        },
      ),
      'GET /olts/7': (o) => (
        200,
        {
          'olt': {'id': 7, 'name': 'Main OLT', 'status': 'online'},
          'ports': [
            {'port': '0/1', 'onu_total': 10, 'onu_online': 9},
          ],
          'onus': [
            {
              'id': 1,
              'port': '0/1',
              'onu_index': 4,
              'status': 'online',
              'rx_dbm': -29.5,
              'level': 'critical',
              'client': {'id': 2, 'name': 'Weak House', 'code': 'C-9'},
            },
            if ((o as dynamic).uri.queryParameters['show'] == 'all')
              {
                'id': 2,
                'port': '0/1',
                'status': 'online',
                'rx_dbm': -20.0,
                'serial_mac': 'ABCD1',
              },
          ],
        },
      ),
    });
    await _pump(tester, erp, const OltListScreen());

    expect(
      find.text('Online · Mirpur · 9/10 online · 2 weak · 1 bad'),
      findsOne,
    );
    await tester.tap(find.text('Main OLT'));
    await tester.pumpAndSettle();
    expect(find.text('Weak House C-9'), findsOne);
    expect(find.text('-29.5 dBm'), findsOne);
    expect(find.text('ABCD1'), findsNothing);

    await tester.tap(find.text('All ONUs'));
    await tester.pumpAndSettle();
    expect(find.text('ABCD1'), findsOne);
  });

  testWidgets('fiber near me lists the nearest and can search wider', (
    tester,
  ) async {
    final erp = _erp({
      'GET /fiber/nearby': (o) => (
        200,
        {
          'items': [
            {
              'type': 'splitter',
              'id': 4,
              'code': 'SP-1',
              'lat': 23.81,
              'lng': 90.41,
              'distance_m': 120,
              'ratio': '1:8',
              'ports_total': 8,
              'ports_free': 3,
            },
          ],
        },
      ),
    });
    await _pump(tester, erp, const FiberNearbyScreen());

    expect(find.text('Splitter · SP-1'), findsOne);
    expect(find.text('120 m · 1:8 · 3/8 ports free'), findsOne);
    expect(erp.requests.last.uri.queryParameters['radius_m'], '1000');

    await tester.tap(find.byKey(const ValueKey('fiber-wider')));
    await tester.pumpAndSettle();
    expect(erp.requests.last.uri.queryParameters['radius_m'], '2500');
  });

  testWidgets('fiber without GPS asks to turn location on, calls nothing', (
    tester,
  ) async {
    final erp = _erp({});
    await _pump(tester, erp, const FiberNearbyScreen(), here: null);
    expect(
      find.text("Turn on the phone's location to find fiber near you."),
      findsOne,
    );
    expect(erp.calls.where((c) => c.contains('fiber')), isEmpty);
  });
}
