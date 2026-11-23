import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/devices_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

void main() {
  testWidgets('lists phones and signs another phone out', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final store = MemorySecretStore()..values[sessionTokenKey] = 'tok';
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1, 'name': 'Rahim'},
        },
      ),
      'GET /devices': (_) => (
        200,
        {
          'devices': [
            {
              'id': 1,
              'device_name': 'This Redmi',
              'app_version': '0.1.0',
              'last_used_at': '2026-11-23T10:00:00+06:00',
              'this_device': true,
            },
            {'id': 2, 'device_name': 'Office tablet', 'this_device': false},
          ],
        },
      ),
      'DELETE /devices/2': (_) => (200, {'ok': true}),
    });
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        secretStoreProvider.overrideWithValue(store),
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
          home: DevicesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This Redmi'), findsOneWidget);
    expect(find.text('Office tablet'), findsOneWidget);
    expect(find.textContaining('This phone'), findsOneWidget);
    final list = erp.requests.firstWhere(
      (r) => r.uri.path.endsWith('/devices'),
    );
    expect(list.headers['Authorization'], 'Bearer tok');

    await tester.tap(find.byKey(const ValueKey('revoke-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(erp.calls, contains('DELETE /devices/2'));
    expect(store.values[sessionTokenKey], 'tok');
  });
}
