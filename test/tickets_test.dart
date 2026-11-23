import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/models.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/api/tickets.dart';
import 'package:mynet_staff/field/drafts.dart';
import 'package:mynet_staff/field/location.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/field.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/home_screen.dart';
import 'package:mynet_staff/ui/note_photo.dart';
import 'package:mynet_staff/ui/ticket_detail_screen.dart';
import 'package:mynet_staff/ui/tickets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

const _tech = {
  'id': 7,
  'name': 'Rahim',
  'roles': ['technician'],
  'permissions': ['staff_app.use', 'tickets.view', 'tickets.update'],
  'screens': ['tickets'],
};

Map<String, Object?> _summary() => {
  'id': 41,
  'subject': 'No internet',
  'priority': 'urgent',
  'status': 'assigned',
  'role': 'main',
  'overdue': true,
  'client': {
    'id': 9,
    'code': 'C-1001',
    'name': 'Karim',
    'phone': '01711000001',
  },
};

Map<String, Object?> _detail({
  bool update = true,
  bool comment = true,
  bool location = false,
  bool dbm = false,
  List<String> next = const ['on_the_way'],
}) => {
  'ticket': {
    ..._summary(),
    'type': 'support',
    'description': 'Light is red',
    'client': {
      'id': 9,
      'code': 'C-1001',
      'name': 'Karim',
      'phone': '01711000001',
      'address': 'House 1',
      'pppoe_username': 'karim',
      'onu': {'sn': 'HWTC123', 'last_rx_dbm': -22.1},
    },
    'comments': [
      {
        'id': 1,
        'body': 'Checked the ONU',
        'user': {'id': 7, 'name': 'Rahim'},
        'photos': const <Object?>[],
      },
    ],
    'can': {
      'update_status': update,
      'close': update,
      'comment': comment,
      'set_location': location,
      'check_dbm': dbm,
    },
    'next_statuses': next,
    'note_required_for': ['resolved', 'closed'],
    'outcomes': ['done', 'no_issue', 'duplicate', 'cancelled'],
    'finish_radius_m': 300,
  },
};

class FixedLocation implements LocationReader {
  const FixedLocation(this.fix);
  final GeoFix? fix;

  @override
  Future<GeoFix?> current() async => fix;
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('permissions', () {
    test('reads /me permissions and screens from the root', () {
      final user = StaffUser.fromJson({
        'user': {'id': 7, 'name': 'Rahim'},
        'roles': ['technician'],
        'permissions': ['tickets.view'],
        'screens': ['tickets', 'duty'],
      });
      expect(user.can('tickets.view'), isTrue);
      expect(user.can('collection.collect'), isFalse);
      expect(user.screens, {'tickets', 'duty'});
      expect(featuresFor(user).map((f) => f.permission), ['tickets.view']);
    });

    test('a screen the ERP left out stays hidden', () {
      final user = StaffUser.fromJson({
        'user': {'id': 1, 'name': 'Office'},
        'permissions': ['tickets.view', 'collection.collect', 'clients.view'],
        'screens': ['tickets'],
      });
      expect(featuresFor(user).map((f) => f.permission), ['tickets.view']);
    });

    test('ticket JSON keeps can flags and the photo url', () {
      final detail = TicketDetail.fromJson(_detail());
      expect(detail.can.updateStatus, isTrue);
      expect(detail.can.setLocation, isFalse);
      final withPhoto = TicketDetail.fromJson({
        'comments': [
          {
            'photos': [
              {'url': '/storage/a.jpg', 'is_image': true},
            ],
          },
        ],
      });
      expect(
        withPhoto.comments.single.photos.single.absoluteUrl,
        endsWith('/storage/a.jpg'),
      );
      final privatePhoto = TicketPhoto.fromJson({
        'download_url': '/api/staff/v1/attachments/9',
        'is_image': true,
      });
      expect(privatePhoto.authenticated, isTrue);
      expect(privatePhoto.displayUrl, endsWith('/attachments/9'));
      expect(privatePhoto.absoluteUrl, isNull);
      expect(detail.client?.onu?.sn, 'HWTC123');
    });
  });

  group('screens', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      FakeErp erp, {
      LocationReader? location,
      DraftStore? drafts,
      Widget? home,
      NotePhotoAttempt? photoAttempt,
      bool sessionFirst = false,
    }) async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final store = MemorySecretStore()..values[sessionTokenKey] = 'tok';
      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          secretStoreProvider.overrideWithValue(store),
          apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
          if (location != null)
            locationReaderProvider.overrideWithValue(location),
          draftStoreProvider.overrideWithValue(drafts ?? MemoryDraftStore()),
          if (photoAttempt != null)
            notePhotoAttemptProvider.overrideWithValue(photoAttempt),
        ],
      );
      addTearDown(container.dispose);
      if (sessionFirst) {
        container.read(authProvider);
        await tester.pump();
        await tester.pump();
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home ?? const TicketListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    FakeErp erpWith(Map<String, Object?> user) {
      return FakeErp({
        'GET /me': (_) => (200, {'user': user, ...user}),
        'GET /tickets': (_) => (
          200,
          {
            'scope': 'mine',
            'status': 'active',
            'page': 1,
            'last_page': 1,
            'total': 1,
            'tickets': [_summary()],
          },
        ),
        'GET /tickets/41': (_) => (200, _detail()),
      });
    }

    testWidgets('a technician sees their ticket and not everyone else', (
      tester,
    ) async {
      final erp = erpWith(_tech);
      await pump(tester, erp);
      expect(find.text('No internet'), findsOneWidget);
      expect(find.textContaining('Over SLA'), findsOneWidget);
      expect(find.byKey(const ValueKey('scope-all')), findsNothing);
      final query = erp.requests
          .firstWhere((r) => r.uri.path.endsWith('/tickets'))
          .uri
          .queryParameters;
      expect(query['scope'], 'mine');
      expect(query['status'], 'active');
    });

    test('a private photo is loaded with the session token', () async {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      final erp = FakeErp({
        'GET /storage/note.png': (o) {
          expect(o.headers['Authorization'], 'Bearer tok');
          return (200, png);
        },
      });
      final api = StaffApi(dio: erp.dio)..token = 'tok';
      final bytes = await api.authorizedBytes(
        'https://erp.test/storage/note.png',
      );
      expect(bytes, png);
    });

    testWidgets('a note photo falls back to the session token', (tester) async {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      final detail = _detail();
      final ticket = detail['ticket']! as Map<String, Object?>;
      final comments = ticket['comments']! as List;
      final comment = comments.first as Map<String, Object?>;
      comment['photos'] = [
        {'url': 'https://erp.test/storage/note.png', 'is_image': true},
      ];
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, detail),
        'GET /storage/note.png': (o) => (200, png),
      });
      final start = ValueNotifier(false);
      addTearDown(start.dispose);
      final container = await pump(
        tester,
        erp,
        home: const TicketDetailScreen(ticketId: 41),
        photoAttempt: (url, failed) {
          return ValueListenableBuilder<bool>(
            valueListenable: start,
            builder: (_, go, _) {
              if (go) {
                WidgetsBinding.instance.addPostFrameCallback((_) => failed());
              }
              return const SizedBox(key: ValueKey('note-photo-public'));
            },
          );
        },
      );
      container.read(authProvider);
      await tester.pumpAndSettle();
      expect(container.read(apiProvider).token, 'tok');
      start.value = true;
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('note-photo-bytes')));
      expect(find.byKey(const ValueKey('note-photo-bytes')), findsOneWidget);
      final photo = erp.requests.lastWhere(
        (r) => r.uri.path.endsWith('/note.png'),
      );
      expect(photo.headers['Authorization'], 'Bearer tok');
    });

    testWidgets('a private download_url is loaded with the session token', (
      tester,
    ) async {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      final detail = _detail();
      final ticket = detail['ticket']! as Map<String, Object?>;
      final comments = ticket['comments']! as List;
      final comment = comments.first as Map<String, Object?>;
      comment['photos'] = [
        {
          'download_url': 'https://erp.test/api/staff/v1/attachments/9',
          'is_image': true,
        },
      ];
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, detail),
        'GET /attachments/9': (o) => (200, png),
      });
      await pump(
        tester,
        erp,
        home: const TicketDetailScreen(ticketId: 41),
        sessionFirst: true,
      );
      await reveal(tester, find.byKey(const ValueKey('note-photo-bytes')));
      expect(find.byKey(const ValueKey('note-photo-public')), findsNothing);
      final photo = erp.requests.lastWhere(
        (r) => r.uri.path.endsWith('/attachments/9'),
      );
      expect(photo.headers['Authorization'], 'Bearer tok');
    });

    testWidgets('status buttons follow can and next_statuses', (tester) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (
          200,
          _detail(update: false, comment: false, next: const ['closed']),
        ),
      });
      await pump(tester, erp, home: const TicketDetailScreen(ticketId: 41));
      expect(find.text('Light is red'), findsOneWidget);
      expect(find.byKey(const ValueKey('status-closed')), findsNothing);
      expect(find.byKey(const ValueKey('comment-send')), findsNothing);
      expect(find.byKey(const ValueKey('save-location')), findsNothing);
      expect(find.byKey(const ValueKey('check-dbm')), findsNothing);
      await reveal(tester, find.text('Checked the ONU'));
      expect(find.text('Checked the ONU'), findsOneWidget);
    });

    testWidgets('on the way posts that status only', (tester) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail()),
        'POST /tickets/41/status': (o) => (200, _detail()),
      });
      await pump(
        tester,
        erp,
        location: FixedLocation(const GeoFix(latitude: 23.8, longitude: 90.4)),
        home: const TicketDetailScreen(ticketId: 41),
      );
      await reveal(tester, find.byKey(const ValueKey('status-on_the_way')));
      await tester.tap(find.byKey(const ValueKey('status-on_the_way')));
      await tester.pumpAndSettle();
      final body =
          erp.requests.lastWhere((r) => r.uri.path.endsWith('/status')).data
              as Map;
      expect(body['status'], 'on_the_way');
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('note'), isFalse);
    });

    testWidgets('closing asks for a note and an outcome', (tester) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail(next: const ['closed'])),
        'POST /tickets/41/status': (o) => (200, _detail(next: const [])),
      });
      await pump(
        tester,
        erp,
        location: const FixedLocation(null),
        home: const TicketDetailScreen(ticketId: 41),
      );
      await reveal(tester, find.byKey(const ValueKey('status-closed')));
      await tester.tap(find.byKey(const ValueKey('status-closed')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('status-note')),
        'PPPoE ok',
      );
      await tester.tap(find.byKey(const ValueKey('outcome-done')));
      await tester.tap(find.byKey(const ValueKey('status-save')));
      await tester.pumpAndSettle();
      final body =
          erp.requests.lastWhere((r) => r.uri.path.endsWith('/status')).data
              as Map;
      expect(body['status'], 'closed');
      expect(body['note'], 'PPPoE ok');
      expect(body['outcome'], 'done');
    });

    testWidgets('too far away asks why and sends it again', (tester) async {
      var posts = 0;
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail(next: const ['resolved'])),
        'POST /tickets/41/status': (o) {
          posts++;
          if (o.data['away_reason'] == null) {
            return (
              422,
              {
                'message': 'Too far',
                'errors': {
                  'away_reason': ['900 m from the house'],
                },
              },
            );
          }
          return (200, _detail(next: const []));
        },
      });
      await pump(
        tester,
        erp,
        location: FixedLocation(
          const GeoFix(latitude: 23.81, longitude: 90.41, accuracy: 8),
        ),
        home: const TicketDetailScreen(ticketId: 41),
      );
      await reveal(tester, find.byKey(const ValueKey('status-resolved')));
      await tester.tap(find.byKey(const ValueKey('status-resolved')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('status-note')),
        'Fixed at the pole',
      );
      await tester.tap(find.byKey(const ValueKey('status-save')));
      await tester.pumpAndSettle();
      expect(find.text('900 m from the house'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('away-reason')),
        'Parts were at the pole',
      );
      await tester.tap(find.byKey(const ValueKey('away-save')));
      await tester.pumpAndSettle();
      expect(posts, 2);
      final body =
          erp.requests.lastWhere((r) => r.uri.path.endsWith('/status')).data
              as Map;
      expect(body['latitude'], 23.81);
      expect(body['away_reason'], 'Parts were at the pole');
      expect(body['note'], 'Fixed at the pole');
    });

    testWidgets('a note is sent once, with its client ref', (tester) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail()),
        'POST /tickets/41/comments': (_) => (
          201,
          {
            'comment': {'id': 2, 'body': 'ONU replaced', 'photos': []},
          },
        ),
      });
      await pump(tester, erp, home: const TicketDetailScreen(ticketId: 41));
      await reveal(tester, find.byKey(const ValueKey('comment-body')));
      await tester.enterText(
        find.byKey(const ValueKey('comment-body')),
        'ONU replaced',
      );
      await reveal(tester, find.byKey(const ValueKey('comment-send')));
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await tester.pumpAndSettle();
      final form =
          erp.requests.lastWhere((r) => r.uri.path.endsWith('/comments')).data
              as FormData;
      expect(
        form.fields.firstWhere((f) => f.key == 'body').value,
        'ONU replaced',
      );
      expect(
        form.fields.firstWhere((f) => f.key == 'client_ref').value,
        isNotEmpty,
      );
    });

    testWidgets('an offline note is sent later with the same ref', (
      tester,
    ) async {
      final drafts = MemoryDraftStore();
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail()),
        'POST /tickets/41/comments': (_) => (
          201,
          {
            'comment': {'id': 3, 'body': 'later', 'photos': []},
          },
        ),
      });
      await pump(
        tester,
        erp,
        drafts: drafts,
        home: const TicketDetailScreen(ticketId: 41),
      );
      erp.offline = true;
      await reveal(tester, find.byKey(const ValueKey('comment-body')));
      await tester.enterText(
        find.byKey(const ValueKey('comment-body')),
        'later',
      );
      await reveal(tester, find.byKey(const ValueKey('comment-send')));
      await tester.tap(find.byKey(const ValueKey('comment-send')));
      await tester.pumpAndSettle();
      expect(drafts.items, hasLength(1));
      expect(
        find.text(
          'No internet. The note stays on this phone and will be sent later.',
        ),
        findsOneWidget,
      );

      erp.offline = false;
      final again = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          secretStoreProvider.overrideWithValue(
            MemorySecretStore()..values[sessionTokenKey] = 'tok',
          ),
          apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
          draftStoreProvider.overrideWithValue(drafts),
        ],
      );
      addTearDown(again.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: again,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TicketDetailScreen(
              key: ValueKey('retry'),
              ticketId: 41,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sent = erp.requests
          .where((r) => r.uri.path.endsWith('/comments') && r.data is FormData)
          .map((r) => r.data as FormData)
          .toList();
      expect(sent, hasLength(2));
      final first = sent.first.fields
          .firstWhere((f) => f.key == 'client_ref')
          .value;
      final second = sent.last.fields
          .firstWhere((f) => f.key == 'client_ref')
          .value;
      expect(second, first);
      expect(drafts.items, isEmpty);
    });

    testWidgets('house GPS is saved only when the permission allows it', (
      tester,
    ) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail(location: true)),
        'POST /clients/9/location': (o) => (
          200,
          {
            'ok': true,
            'location': {
              'latitude': o.data['latitude'],
              'longitude': o.data['longitude'],
              'accuracy_m': o.data['accuracy'],
            },
          },
        ),
      });
      await pump(
        tester,
        erp,
        location: FixedLocation(
          const GeoFix(latitude: 23.81, longitude: 90.41, accuracy: 8),
        ),
        home: const TicketDetailScreen(ticketId: 41),
      );
      await reveal(tester, find.byKey(const ValueKey('save-location')));
      await tester.tap(find.byKey(const ValueKey('save-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-location')));
      await tester.pumpAndSettle();
      final body =
          erp.requests.lastWhere((r) => r.uri.path.endsWith('/location')).data
              as Map;
      expect(body['latitude'], 23.81);
      expect(body['accuracy'], 8);
      expect(find.text('House location saved.'), findsOneWidget);
    });

    testWidgets('live dBm shows the reading from the OLT', (tester) async {
      final erp = FakeErp({
        'GET /me': (_) => (200, {'user': _tech}),
        'GET /tickets/41': (_) => (200, _detail(dbm: true)),
        'POST /clients/9/dbm': (_) => (
          200,
          {
            'ok': true,
            'rx_dbm': -19.4,
            'tx_dbm': 2.1,
            'level': 'good',
            'message': 'Signal is fine',
          },
        ),
      });
      await pump(tester, erp, home: const TicketDetailScreen(ticketId: 41));
      await reveal(tester, find.byKey(const ValueKey('check-dbm')));
      await tester.tap(find.byKey(const ValueKey('check-dbm')));
      await tester.pumpAndSettle();
      expect(find.text('-19.4'), findsOneWidget);
      expect(find.text('Signal is fine'), findsOneWidget);
    });
  });
}
