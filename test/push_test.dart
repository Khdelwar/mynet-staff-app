import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/main.dart';
import 'package:mynet_staff/push/push.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

const _user = {
  'id': 7,
  'name': 'Rahim',
  'email': 'tech@example.com',
  'roles': ['technician'],
  'permissions': ['staff_app.use', 'tickets.view'],
};

Map<String, Object?> _ticket(int id, {String role = 'main'}) => {
  'ticket': {
    'id': id,
    'subject': 'No internet',
    'priority': 'urgent',
    'status': 'assigned',
    'role': role,
    'client': {'id': 9, 'name': 'Karim'},
    'comments': <Object?>[],
    'can': {
      'update_status': false,
      'comment': false,
      'set_location': false,
      'check_dbm': false,
    },
    'next_statuses': <Object?>[],
  },
};

class FakePush implements PushService {
  FakePush({this.token});

  String? token;
  final _messages = StreamController<PushMessage>.broadcast();
  PushMessage? pending;

  @override
  Stream<PushMessage> get messages => _messages.stream;

  @override
  PushMessage? takePending() {
    final held = pending;
    pending = null;
    return held;
  }

  void emit(PushMessage message) => _messages.add(message);

  @override
  Future<void> register(StaffApi api) async {
    final value = token;
    if (value == null || value.isEmpty) return;
    await api.registerPush(value);
  }

  @override
  Future<void> unregister(StaffApi api) async {
    await api.unregisterPush();
  }
}

void main() {
  group('parse', () {
    test('reads string ids from an FCM data map', () {
      final message = parsePush(
        {'type': 'ticket_assigned', 'ticket_id': '41', 'priority': 'high'},
        title: 'Ticket #41',
        tapped: true,
      );
      expect(message, isNotNull);
      expect(message!.opensTicket, isTrue);
      expect(message.ticketId, 41);
      expect(message.priority, 'high');
      expect(message.tapped, isTrue);
    });

    test('an unassigned ticket still opens that ticket', () {
      final message = parsePush({
        'type': 'ticket_unassigned',
        'ticket_id': '41',
      });
      expect(message!.opensTicket, isTrue);
      expect(message.ticketId, 41);
      expect(message.opensOffer, isFalse);
    });

    test('an offer tap carries the offer id', () {
      final message = parsePush({
        'type': 'ticket_offer',
        'offer_id': '5',
        'ticket_id': '41',
      });
      expect(message!.opensOffer, isTrue);
      expect(message.offerId, 5);
      expect(message.opensTicket, isFalse);
    });

    test('a payload without a type is ignored', () {
      expect(parsePush({'ticket_id': '1'}), isNull);
    });
  });

  group('register', () {
    test('login sends the token; logout unregisters before signing out', () async {
      final erp = FakeErp({
        'POST /auth/login': (_) => (200, {'token': 'tok', 'user': _user}),
        'GET /me': (_) => (200, {'user': _user}),
        'POST /push/register': (_) => (200, {'ok': true}),
        'POST /push/unregister': (_) => (200, {'ok': true}),
        'POST /auth/logout': (_) => (200, {'ok': true}),
      });
      final push = FakePush(token: 'fcm-1');
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          configuredProvider.overrideWithValue(true),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          pushServiceProvider.overrideWithValue(push),
          apiProvider.overrideWith(
            (ref) => StaffApi(
              dio: erp.dio,
              onUnauthorized: (rejected, _) => ref
                  .read(authProvider.notifier)
                  .sessionExpired(rejectedToken: rejected),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authProvider.notifier)
          .login('tech@example.com', 'pw');
      for (
        var i = 0;
        i < 20 && !erp.calls.contains('POST /push/register');
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        erp.calls,
        contains('POST /push/register'),
        reason:
            'service=${container.read(pushServiceProvider).runtimeType} calls=${erp.calls}',
      );

      final register = erp.requests.lastWhere(
        (r) => r.uri.path.endsWith('/push/register'),
      );
      expect(register.data, {'token': 'fcm-1'});
      expect(register.headers['Authorization'], 'Bearer tok');

      await container.read(authProvider.notifier).logout();
      final unregisterAt = erp.calls.indexOf('POST /push/unregister');
      final logoutAt = erp.calls.indexOf('POST /auth/logout');
      expect(unregisterAt, greaterThanOrEqualTo(0));
      expect(logoutAt, greaterThan(unregisterAt));
      expect(container.read(authProvider).signedIn, isFalse);
    });
  });

  group('tap', () {
    Future<void> pump(WidgetTester tester, FakePush push, FakeErp erp) async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            configuredProvider.overrideWithValue(true),
            secretStoreProvider.overrideWithValue(
              MemorySecretStore()..values[sessionTokenKey] = 'tok',
            ),
            connectivityProvider.overrideWith(
              (ref) => Stream.value([ConnectivityResult.wifi]),
            ),
            pushServiceProvider.overrideWithValue(push),
            apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
          ],
          child: const StaffApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a tapped assignment opens that ticket', (tester) async {
      final push = FakePush();
      await pump(
        tester,
        push,
        FakeErp({
          'GET /me': (_) => (200, {'user': _user}),
          'GET /tickets/41': (_) => (200, _ticket(41)),
        }),
      );

      push.emit(
        const PushMessage(
          type: 'ticket_assigned',
          ticketId: 41,
          priority: 'urgent',
          title: 'Ticket #41 assigned.',
          tapped: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ticket-detail')), findsOneWidget);
      expect(find.text('No internet'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('a helper tap says so', (tester) async {
      final push = FakePush();
      await pump(
        tester,
        push,
        FakeErp({
          'GET /me': (_) => (200, {'user': _user}),
          'GET /tickets/8': (_) => (200, _ticket(8, role: 'helper')),
        }),
      );
      push.emit(
        const PushMessage(type: 'ticket_helper', ticketId: 8, tapped: true),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-detail')), findsOneWidget);
      expect(find.text('Helper'), findsOneWidget);
    });

    testWidgets('an unassigned tap opens that ticket', (tester) async {
      final push = FakePush();
      await pump(
        tester,
        push,
        FakeErp({
          'GET /me': (_) => (200, {'user': _user}),
          'GET /tickets/41': (_) => (200, _ticket(41)),
        }),
      );
      push.emit(
        const PushMessage(
          type: 'ticket_unassigned',
          ticketId: 41,
          title: 'Ticket #41 unassigned',
          tapped: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticket-detail')), findsOneWidget);
      expect(find.text('No internet'), findsOneWidget);
    });

    testWidgets('a foreground offer waits for a tap', (tester) async {
      final push = FakePush();
      await pump(
        tester,
        push,
        FakeErp({
          'GET /me': (_) => (200, {'user': _user}),
        }),
      );
      push.emit(
        const PushMessage(
          type: 'ticket_offer',
          offerId: 5,
          ticketId: 41,
          title: 'Ticket #41 near you',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('push-offer-5')), findsNothing);
      expect(find.text('Ticket #41 near you'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('push-offer-5')), findsOneWidget);
      expect(find.text('A nearby ticket was offered to you.'), findsOneWidget);
    });

    testWidgets('an offer tap opens the offers list when it is allowed', (
      tester,
    ) async {
      final push = FakePush();
      final erp = FakeErp({
        'GET /me': (_) => (
          200,
          {
            'user': {
              ..._user,
              'permissions': ['staff_app.use', 'tickets.update'],
            },
          },
        ),
        'GET /offers': (_) => (200, {'offers': []}),
      });
      await pump(tester, push, erp);
      push.emit(
        const PushMessage(
          type: 'ticket_offer',
          offerId: 5,
          ticketId: 41,
          tapped: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Job offers'), findsOneWidget);
      expect(find.text('No offers waiting.'), findsOneWidget);
      expect(find.byKey(const ValueKey('push-offer-5')), findsNothing);
      expect(erp.calls, contains('GET /offers'));
    });

    testWidgets('a cold-start tap still opens the ticket', (tester) async {
      final push = FakePush()
        ..pending = const PushMessage(
          type: 'ticket_assigned',
          ticketId: 41,
          tapped: true,
        );
      await pump(
        tester,
        push,
        FakeErp({
          'GET /me': (_) => (200, {'user': _user}),
          'GET /tickets/41': (_) => (200, _ticket(41)),
        }),
      );
      expect(find.byKey(const ValueKey('ticket-detail')), findsOneWidget);
    });
  });
}
