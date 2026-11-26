import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/fiber.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/fiber_map_screen.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Read-only Fiber & GIS map from GET /fiber-map.

final _payload = {
  'center': {'lat': 23.04, 'lng': 88.89},
  'zoom': 13,
  'features': [
    {
      'type': 'pole',
      'id': 1,
      'code': 'P-01',
      'lat': 23.04,
      'lng': 88.89,
      'status': 'active',
    },
    {
      'type': 'splitter',
      'id': 3,
      'code': 'SPL-1',
      'lat': 23.041,
      'lng': 88.891,
      'ratio': '1:8',
      'olt': 'OLT-A',
      'pon': 'EPON0/1',
      'ports': '2/8',
    },
    {
      'type': 'route',
      'id': 4,
      'code': 'FR-1',
      'status': 'active',
      'coordinates': [
        [23.04, 88.89],
        [23.05, 88.90],
      ],
    },
    {
      'type': 'cut',
      'id': 5,
      'code': 'CUT-1',
      'lat': 23.045,
      'lng': 88.895,
      'status': 'open',
      'status_label': 'Open',
    },
    {
      'type': 'client',
      'id': 9,
      'code': 'C-77',
      'lat': 23.046,
      'lng': 88.896,
      'name': 'Kamal',
    },
  ],
  'clients_total': 1200,
  'clients_shown': 1000,
  'cuts': [
    {
      'id': 5,
      'code': 'CUT-1',
      'status': 'open',
      'status_label': 'Open',
      'route': 'FR-1',
      'notes': 'Near bazar',
      'lat': 23.045,
      'lng': 88.895,
    },
  ],
};

void main() {
  test('reads the ERP payload as sent', () {
    final map = FiberMap.fromJson(_payload);
    expect(map.features, hasLength(5));
    expect(map.features[1].details['ratio'], '1:8');
    expect(map.features[2].path, [(23.04, 88.89), (23.05, 88.90)]);
    expect(map.cuts.single.route, 'FR-1');
  });

  test('Home: fiber button for the ERP fiber screen permissions', () {
    StaffUser u(List<String> p) =>
        StaffUser.fromJson({'id': 1, 'permissions': p});
    expect(
      featuresFor(u(['fiber.view'])).map((f) => f.screen),
      contains('fiber'),
    );
    expect(
      featuresFor(u(['fiber.manage'])).map((f) => f.screen),
      contains('fiber'),
    );
    expect(
      featuresFor(u(['staff_app.use'])).map((f) => f.screen),
      isNot(contains('fiber')),
    );
  });

  testWidgets('map, layers, details and open cuts', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final erp = FakeErp({'GET /fiber-map': (_) => (200, _payload)});
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
          home: const FiberMapScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Open cuts (1)'), findsOneWidget);
    expect(find.text('CUT-1 · FR-1'), findsOneWidget);
    expect(find.text('Near bazar'), findsOneWidget);
    expect(
      find.text('Showing 1000 of 1200 clients on the map.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fiber-client-9')), findsOneWidget);

    // Hide clients, as the web layer switch.
    await tester.tap(find.byKey(const ValueKey('fiber-layer-client')));
    await tester.pump();
    expect(find.byKey(const ValueKey('fiber-client-9')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fiber-splitter-3')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('fiber-details')), findsOneWidget);
    expect(find.text('1:8'), findsOneWidget);
    expect(find.text('OLT-A'), findsOneWidget);
    expect(find.text('2/8'), findsOneWidget);
  });
}
