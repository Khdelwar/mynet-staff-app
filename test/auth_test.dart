import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/device.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/main.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/app_shell.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

const _user = {
  'id': 7,
  'name': 'Rahim',
  'email': 'tech@example.com',
  'phone': '01711000001',
  'roles': ['technician'],
  'is_super_admin': false,
  'permissions': ['staff_app.use', 'tickets.view', 'clients.view'],
  'staff': {'id': 3, 'code': 'S-9', 'name': 'Rahim Uddin'},
};

List<Override> _overrides(
  FakeErp erp,
  MemorySecretStore store,
  SharedPreferences prefs,
) => [
  prefsProvider.overrideWithValue(prefs),
  secretStoreProvider.overrideWithValue(store),
  connectivityProvider.overrideWith(
    (ref) => Stream.value([ConnectivityResult.wifi]),
  ),
  apiProvider.overrideWith(
    (ref) => StaffApi(
      dio: erp.dio,
      onUnauthorized: (rejected, code, message) => ref
          .read(authProvider.notifier)
          .sessionExpired(
            rejectedToken: rejected,
            code: code,
            message: message,
          ),
    ),
  ),
];

Future<ProviderContainer> _container(
  FakeErp erp,
  MemorySecretStore store,
) async {
  SharedPreferences.setMockInitialValues({
    'locale': 'en',
    ServerController.key: 'https://erp.test',
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: _overrides(erp, store, prefs));
  addTearDown(c.dispose);
  return c;
}

Future<void> _settle(ProviderContainer c) async {
  c.read(authProvider);
  for (var i = 0; i < 20 && !c.read(authProvider).ready; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  group('session', () {
    test('signs in, keeps the token in secure storage, sends Bearer', () async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (200, {'token': 'tok', 'user': _user}),
        'GET /me': (_) => (200, {'user': _user}),
      });
      final store = MemorySecretStore();
      final c = await _container(erp, store);
      await _settle(c);

      final outcome = await c
          .read(authProvider.notifier)
          .login(' tech@example.com ', 'pw');
      expect(outcome, isA<SignedIn>());
      expect(c.read(authProvider).signedIn, isTrue);
      expect(c.read(authProvider).user?.staff?.code, 'S-9');
      expect(store.values[sessionTokenKey], 'tok');
      final loginBody = erp.requests.first.data as Map;
      expect(loginBody['identifier'], 'tech@example.com');
      expect(
        loginBody['device_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(loginBody['device_id'], store.values[deviceIdKey]);
      expect(loginBody['device_name'], isNotEmpty);
      expect(loginBody.containsKey('email'), isFalse);
      expect(loginBody['app_version'], staffAppVersion);

      await c.read(authProvider.notifier).refreshProfile();
      expect(erp.requests.last.headers['Authorization'], 'Bearer tok');
    });

    test('2FA: no token until the code is verified', () async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (
          202,
          {
            'code': 'two_factor_required',
            'challenge_token': 'ch-1',
            'channel': 'totp',
          },
        ),
        'POST /auth/two-factor': (o) =>
            o.data['code'] == '123456' && o.data['challenge_token'] == 'ch-1'
            ? (200, {'token': 'tok2', 'user': _user})
            : (422, {'message': 'Wrong code'}),
      });
      final store = MemorySecretStore();
      final c = await _container(erp, store);
      await _settle(c);

      final outcome = await c.read(authProvider.notifier).login('a@b.c', 'pw');
      expect(outcome, isA<TwoFactorNeeded>());
      expect((outcome as TwoFactorNeeded).channel, 'totp');
      expect(c.read(authProvider).signedIn, isFalse);
      expect(store.values.containsKey(sessionTokenKey), isFalse);
      expect(store.values[deviceIdKey], isNotEmpty);

      await expectLater(
        c.read(authProvider.notifier).verifyTwoFactor('ch-1', '000000'),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(authProvider).signedIn, isFalse);

      await c.read(authProvider.notifier).verifyTwoFactor('ch-1', '123456');
      expect(c.read(authProvider).signedIn, isTrue);
      expect(store.values[sessionTokenKey], 'tok2');
    });

    test('a 401 from ERP signs out and says why', () async {
      final erp = FakeErp({
        'GET /me': (_) => (401, {'code': 'inactive', 'message': 'Inactive'}),
      });
      final store = MemorySecretStore()
        ..values[sessionTokenKey] = 'old'
        ..values[deviceIdKey] = 'phone-1'
        ..values[cachedUserKey] = jsonEncode({'user': _user});
      final c = await _container(erp, store);
      await _settle(c);

      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(authProvider).ended, isTrue);
      expect(store.values[deviceIdKey], 'phone-1');
      expect(store.values.containsKey(sessionTokenKey), isFalse);
    });

    test(
      'starting offline keeps the staff signed in with the cached profile',
      () async {
        final erp = FakeErp({})..offline = true;
        final store = MemorySecretStore()
          ..values[sessionTokenKey] = 'tok'
          ..values[cachedUserKey] = jsonEncode(_user);
        final c = await _container(erp, store);
        await _settle(c);

        expect(c.read(authProvider).signedIn, isTrue);
        expect(c.read(authProvider).user?.name, 'Rahim');
      },
    );

    test('logout forgets the token even when offline', () async {
      final erp = FakeErp({})..offline = true;
      final store = MemorySecretStore()
        ..values[sessionTokenKey] = 'tok'
        ..values[deviceIdKey] = 'phone-1';
      final c = await _container(erp, store);
      await _settle(c);

      await c.read(authProvider.notifier).logout();
      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(authProvider).ended, isFalse);
      expect(store.values[deviceIdKey], 'phone-1');
      expect(store.values.containsKey(sessionTokenKey), isFalse);
    });
  });

  group('features', () {
    test('only what the ERP permissions open', () {
      final user = StaffUser.fromJson(_user);
      expect(featuresFor(user).map((f) => f.permission), [
        'tickets.view',
        'clients.view',
        'staff_app.use',
      ]);
      expect(
        featuresFor(StaffUser.fromJson({'id': 1, 'is_super_admin': true})),
        hasLength(features.length),
      );
    });

    test('roles and screens are read from user, company from the root', () {
      final user = StaffUser.fromJson({
        'user': {
          'id': 7,
          'name': 'Rahim',
          'roles': ['technician'],
          'permissions': ['tickets.view'],
          'screens': ['tickets'],
          'staff': {'id': 3, 'code': 'S-9'},
        },
        'roles': ['manager'],
        'permissions': ['clients.view'],
        'screens': ['clients', 'duty'],
        'company': {'name': 'MyNet'},
      });
      expect(user.roles, ['technician']);
      expect(user.screens, {'tickets'});
      expect(user.can('tickets.view'), isTrue);
      expect(user.can('clients.view'), isFalse);
      expect(user.staff?.code, 'S-9');
      expect(user.companyName, 'MyNet');
    });
  });

  group('screens', () {
    Future<void> pumpApp(
      WidgetTester tester,
      FakeErp erp,
      MemorySecretStore store,
    ) async {
      SharedPreferences.setMockInitialValues({
        'locale': 'en',
        ServerController.key: 'https://erp.test',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(erp, store, prefs),
          child: const StaffApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('wrong password shows the message, right one opens home', (
      tester,
    ) async {
      final erp = FakeErp({
        'POST /auth/login': (o) => o.data['password'] == 'right'
            ? (
                200,
                {
                  'token': 'tok',
                  'user': _user,
                  'company': {'name': 'MyNet'},
                },
              )
            : (401, {'code': 'invalid', 'message': 'nope'}),
        'GET /me': (_) => (
          200,
          {
            'user': _user,
            'company': {'name': 'MyNet'},
          },
        ),
      });
      await pumpApp(tester, erp, MemorySecretStore());

      await tester.enterText(
        find.byKey(const ValueKey('email')),
        'tech@example.com',
      );
      await tester.enterText(find.byKey(const ValueKey('password')), 'wrong');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Email or password is incorrect.'), findsOne);

      await tester.enterText(find.byKey(const ValueKey('password')), 'right');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Rahim Uddin'), findsOne);
      expect(find.text('MyNet'), findsOne);
      expect(find.text('Tickets'), findsOne);
      expect(find.text('Bill collection'), findsNothing);
      final body = erp.requests.first.data as Map;
      expect(body['identifier'], 'tech@example.com');
      expect(body['device_id'], isNotEmpty);
      expect(body['device_name'], isNotEmpty);
      expect(body['app_version'], staffAppVersion);
    });

    testWidgets('2FA step asks for the code', (tester) async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (
          202,
          {
            'code': 'two_factor_required',
            'challenge_token': 'c',
            'channel': 'sms',
          },
        ),
        'POST /auth/two-factor': (_) => (200, {'token': 't', 'user': _user}),
        'GET /me': (_) => (200, {'user': _user}),
      });
      await pumpApp(tester, erp, MemorySecretStore());

      await tester.enterText(find.byKey(const ValueKey('email')), 'a@b.c');
      await tester.enterText(find.byKey(const ValueKey('password')), 'pw');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('We sent a code by SMS.'), findsOne);

      await tester.enterText(find.byKey(const ValueKey('code')), '123456');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Rahim Uddin'), findsOne);
      final two = erp.requests.lastWhere(
        (r) => r.uri.path.endsWith('/two-factor'),
      );
      expect(two.data['challenge_token'], 'c');
      expect(two.data['challenge'], 'c');
      expect(two.data['code'], '123456');
    });

    testWidgets('401 inactive clears the token and shows the ERP message', (
      tester,
    ) async {
      final store = MemorySecretStore()
        ..values[sessionTokenKey] = 'tok'
        ..values[cachedUserKey] = '{"id":7,"name":"Rahim"}';
      final erp = FakeErp({
        'GET /me': (_) => (
          401,
          {'code': 'inactive', 'message': 'This login is switched off.'},
        ),
      });
      await pumpApp(tester, erp, store);
      expect(find.text('This login is switched off.'), findsOne);
      expect(find.text('স্টাফ লগইন'), findsNothing);
      expect(find.text('Staff sign-in'), findsOne);
      expect(store.values.containsKey(sessionTokenKey), isFalse);
      expect(store.values.containsKey(cachedUserKey), isFalse);
    });

    testWidgets('Bangla is the default language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(FakeErp({}), MemorySecretStore(), prefs),
          child: const StaffApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('স্টাফ লগইন'), findsOne);
    });
  });
}
