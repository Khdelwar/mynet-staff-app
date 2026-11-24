import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
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
      onUnauthorized: (rejected, _) => ref
          .read(authProvider.notifier)
          .sessionExpired(rejectedToken: rejected),
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
      expect(erp.requests.first.data['identifier'], 'tech@example.com');

      await c.read(authProvider.notifier).refreshProfile();
      expect(erp.requests.last.headers['Authorization'], 'Bearer tok');
    });

    test('2FA: no token until the code is verified', () async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (
          202,
          {
            'code': 'two_factor_required',
            'challenge': 'ch-1',
            'channel': 'totp',
          },
        ),
        'POST /auth/two-factor': (o) => o.data['code'] == '123456'
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
      expect(store.values, isEmpty);

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
        ..values[cachedUserKey] = jsonEncode({'user': _user});
      final c = await _container(erp, store);
      await _settle(c);

      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(authProvider).ended, isTrue);
      expect(store.values, isEmpty);
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
      final store = MemorySecretStore()..values[sessionTokenKey] = 'tok';
      final c = await _container(erp, store);
      await _settle(c);

      await c.read(authProvider.notifier).logout();
      expect(c.read(authProvider).signedIn, isFalse);
      expect(c.read(authProvider).ended, isFalse);
      expect(store.values, isEmpty);
    });
  });

  group('features', () {
    test('only what the ERP permissions open', () {
      final user = StaffUser.fromJson(_user);
      expect(featuresFor(user).map((f) => f.permission), [
        'tickets.view',
        'clients.view',
      ]);
      expect(
        featuresFor(StaffUser.fromJson({'id': 1, 'is_super_admin': true})),
        hasLength(features.length),
      );
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
            ? (200, {'token': 'tok', 'user': _user})
            : (401, {'code': 'failed', 'message': 'nope'}),
        'GET /me': (_) => (200, {'user': _user}),
      });
      await pumpApp(tester, erp, MemorySecretStore());

      await tester.enterText(
        find.byKey(const ValueKey('identifier')),
        'tech@example.com',
      );
      await tester.enterText(find.byKey(const ValueKey('password')), 'wrong');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Email / mobile or password is incorrect.'), findsOne);

      await tester.enterText(find.byKey(const ValueKey('password')), 'right');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Rahim Uddin'), findsOne);
      expect(find.text('Tickets'), findsOne);
      expect(find.text('Bill collection'), findsNothing);
    });

    testWidgets('2FA step asks for the code', (tester) async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (
          202,
          {'code': 'two_factor_required', 'challenge': 'c', 'channel': 'sms'},
        ),
        'POST /auth/two-factor': (_) => (200, {'token': 't', 'user': _user}),
        'GET /me': (_) => (200, {'user': _user}),
      });
      await pumpApp(tester, erp, MemorySecretStore());

      await tester.enterText(find.byKey(const ValueKey('identifier')), 'a@b.c');
      await tester.enterText(find.byKey(const ValueKey('password')), 'pw');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('We sent a code by SMS.'), findsOne);

      await tester.enterText(find.byKey(const ValueKey('code')), '123456');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Rahim Uddin'), findsOne);
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
