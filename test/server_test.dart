import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/config.dart';
import 'package:mynet_staff/main.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

const _user = {
  'id': 7,
  'name': 'Rahim',
  'roles': ['technician'],
  'permissions': ['staff_app.use', 'tickets.view'],
  'staff': {'id': 3, 'code': 'S-9', 'name': 'Rahim Uddin'},
};

void main() {
  group('normalizeServer', () {
    test('accepts a bare host or https address and keeps only the root', () {
      expect(
        AppConfig.normalizeServer('bill.example.com'),
        'https://bill.example.com',
      );
      expect(
        AppConfig.normalizeServer('  Bill.Example.com/ '),
        'https://bill.example.com',
      );
      expect(
        AppConfig.normalizeServer('https://erp.example.com'),
        'https://erp.example.com',
      );
      expect(
        AppConfig.normalizeServer('https://erp.example.com/api/staff/v1/me'),
        'https://erp.example.com',
      );
      expect(
        AppConfig.normalizeServer('https://isp.example.com:8443/erp'),
        'https://isp.example.com:8443/erp',
      );
    });

    test('refuses plain http and things that are not addresses', () {
      for (final bad in [
        '',
        'http://bill.example.com',
        'ftp://bill.example.com',
        'localhost',
        'bill example.com',
        'https://user:pw@bill.example.com',
        'https://bill.example.com/?x=1',
      ]) {
        expect(AppConfig.normalizeServer(bad), isNull, reason: bad);
      }
    });
  });

  group('sign-in to the ERP the staff typed', () {
    late FakeErp erp;
    late List<String> hosts;

    Future<ProviderContainer> container(Map<String, Object> prefsValues) async {
      SharedPreferences.setMockInitialValues(prefsValues);
      final prefs = await SharedPreferences.getInstance();
      hosts = [];
      erp = FakeErp({
        'POST /auth/login': (o) {
          hosts.add(o.uri.host);
          return o.uri.host == 'bill.example.com'
              ? (200, {'token': 'tok', 'user': _user})
              : (404, {'message': 'Not found'});
        },
        'GET /me': (o) => (200, {'user': _user}),
      });
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('saves the address only after the ERP accepts the sign-in', () async {
      final c = await container({});
      expect(c.read(serverProvider), isNull);

      await expectLater(
        c
            .read(authProvider.notifier)
            .login('a@b.c', 'pw', server: 'https://wrong.example.com'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      expect(c.read(serverProvider), isNull);

      await c
          .read(authProvider.notifier)
          .login('a@b.c', 'pw', server: 'https://bill.example.com');
      expect(hosts, ['wrong.example.com', 'bill.example.com']);
      expect(c.read(authProvider).signedIn, isTrue);
      expect(c.read(serverProvider), 'https://bill.example.com');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ServerController.key), 'https://bill.example.com');
    });

    test('uses the saved address when none is given', () async {
      final c = await container({
        ServerController.key: 'https://bill.example.com',
      });
      await c.read(authProvider.notifier).login('a@b.c', 'pw');
      expect(hosts, ['bill.example.com']);
    });

    test('refuses to sign in with no address at all', () async {
      final c = await container({});
      await expectLater(
        c.read(authProvider.notifier).login('a@b.c', 'pw'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'no_server')),
      );
      expect(hosts, isEmpty);
    });
  });

  group('login screen', () {
    Future<void> pump(
      WidgetTester tester,
      Map<String, Object> prefsValues,
      FakeErp erp,
    ) async {
      SharedPreferences.setMockInitialValues({'locale': 'en', ...prefsValues});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            secretStoreProvider.overrideWithValue(MemorySecretStore()),
            connectivityProvider.overrideWith(
              (ref) => Stream.value([ConnectivityResult.wifi]),
            ),
            apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
          ],
          child: const StaffApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    FakeErp erpAt(String host) => FakeErp({
      'POST /auth/login': (o) => o.uri.host == host
          ? (200, {'token': 'tok', 'user': _user})
          : (404, {'message': 'Not found'}),
      'GET /me': (_) => (200, {'user': _user}),
    });

    testWidgets('asks for the ERP address on a new phone', (tester) async {
      await pump(tester, {}, erpAt('bill.example.com'));
      expect(find.byKey(const ValueKey('server')), findsOne);

      await tester.enterText(
        find.byKey(const ValueKey('server')),
        'http://bill.example.com',
      );
      await tester.enterText(find.byKey(const ValueKey('identifier')), 'a@b.c');
      await tester.enterText(find.byKey(const ValueKey('password')), 'pw');
      await tester.ensureVisible(find.byKey(const ValueKey('submit')));
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter an https web address, e.g. bill.example.com'),
        findsOne,
      );

      await tester.enterText(
        find.byKey(const ValueKey('server')),
        'erp.example.com',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('submit')));
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('No ERP found at this address. Check it and try again.'),
        findsOne,
      );

      await tester.enterText(
        find.byKey(const ValueKey('server')),
        'bill.example.com',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('submit')));
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Rahim Uddin'), findsOne);
    });

    testWidgets('shows the saved address with a change button', (tester) async {
      await pump(tester, {
        ServerController.key: 'https://bill.example.com',
      }, erpAt('bill.example.com'));
      expect(find.byKey(const ValueKey('server')), findsNothing);
      expect(find.text('bill.example.com'), findsOne);

      await tester.tap(find.byKey(const ValueKey('server-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('server')), findsOne);
    });
  });
}
