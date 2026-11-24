import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/main.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/app_shell.dart';
import 'package:mynet_staff/ui/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Work screens (STF-03 … STF-09) against a fake ERP: the app sends what the
/// API asks for and shows what the ERP answers.

Map<String, dynamic> _user(List<String> screens, List<String> permissions) => {
  'id': 7,
  'name': 'Rahim',
  'roles': ['manager'],
  'is_super_admin': false,
  'permissions': ['staff_app.use', ...permissions],
  'screens': screens,
};

const _client = {
  'id': 9,
  'code': 'C-1001',
  'name': 'Karim',
  'phone': '01710000000',
  'due': 600,
};

Map<String, dynamic> _ticket({String status = 'assigned'}) => {
  'id': 41,
  'subject': 'No internet',
  'status': status,
  'priority': 'high',
  'role': 'main',
  'client': _client,
  'can': {
    'update_status': true,
    'comment': true,
    'use_materials': true,
    'scan_items': true,
    'install': false,
  },
  'next_statuses': ['on_the_way', 'resolved'],
  'note_required_for': ['resolved', 'closed'],
  'outcomes': ['done', 'no_issue'],
  'comments': [],
};

Future<void> _pumpSignedIn(
  WidgetTester tester,
  FakeErp erp,
  Map<String, dynamic> user,
) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final store = MemorySecretStore()..values[sessionTokenKey] = 'tok';
  erp.routes['GET /me'] = (_) => (200, {'user': user});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        configuredProvider.overrideWithValue(true),
        secretStoreProvider.overrideWithValue(store),
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
        apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
        locatorProvider.overrideWithValue(
          () async => (latitude: 23.81, longitude: 90.41, accuracy: 8.0),
        ),
      ],
      child: const StaffApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _typeInDialog(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    ),
    text,
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows only the screens the ERP lists', (tester) async {
    final erp = FakeErp({});
    await _pumpSignedIn(
      tester,
      erp,
      _user(['tickets', 'hr', 'olt'], ['tickets.view', 'hr.self']),
    );

    expect(find.text('Tickets'), findsOne);
    expect(find.text('Attendance, leave & advance'), findsOne);
    expect(find.text('Bill collection'), findsNothing);
  });

  testWidgets('a ticket step is sent; finishing far away asks why', (
    tester,
  ) async {
    final bodies = <Map>[];
    final erp = FakeErp({
      'GET /tickets': (_) => (
        200,
        {
          'tickets': [_ticket()],
          'page': 1,
          'last_page': 1,
        },
      ),
      'GET /tickets/41': (_) => (200, {'ticket': _ticket()}),
      'POST /tickets/41/status': (o) {
        final body = o.data as Map;
        bodies.add(body);
        if (body['status'] == 'resolved' && body['away_reason'] == null) {
          return (
            422,
            {
              'message': 'Far',
              'errors': {
                'away_reason': ['You are 900 m from the house. Why?'],
              },
            },
          );
        }
        return (200, {'ticket': _ticket(status: body['status'] as String)});
      },
    });
    await _pumpSignedIn(tester, erp, _user(['tickets'], ['tickets.view']));

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('No internet'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'On the way'));
    await tester.pumpAndSettle();
    expect(bodies.last['status'], 'on_the_way');

    await tester.tap(find.widgetWithText(FilledButton, 'Resolved'));
    await tester.pumpAndSettle();
    await _typeInDialog(tester, 'Cable joined');
    // The ERP's question comes back; the reason goes with the same step.
    expect(find.text('You are 900 m from the house. Why?'), findsOne);
    await _typeInDialog(tester, 'Client met me at the shop');

    expect(bodies.last['status'], 'resolved');
    expect(bodies.last['note'], 'Cable joined');
    expect(bodies.last['away_reason'], 'Client met me at the shop');
    // Finishing sends the phone's location; a plain step does not.
    expect(bodies.last['latitude'], 23.81);
    expect(bodies.first.containsKey('latitude'), isFalse);
  });

  testWidgets('parts used on a ticket carry a request key', (tester) async {
    Map? sent;
    final erp = FakeErp({
      'GET /tickets/41': (_) => (200, {'ticket': _ticket()}),
      'GET /tickets': (_) => (
        200,
        {
          'tickets': [_ticket()],
        },
      ),
      'GET /tickets/41/materials': (_) => (
        200,
        {
          'materials': [],
          'parts': [
            {'id': 4, 'name': 'Patch cord', 'unit': 'pcs', 'in_stock': 5},
          ],
          'purposes': ['repair', 'new_connection'],
          'default_purpose': 'repair',
        },
      ),
      'POST /tickets/41/materials': (o) {
        sent = o.data as Map;
        return (
          201,
          {
            'replayed': false,
            'materials': [
              {'id': 1, 'name': 'Patch cord', 'quantity': 2, 'unit': 'pcs'},
            ],
          },
        );
      },
    });
    await _pumpSignedIn(tester, erp, _user(['tickets'], ['tickets.view']));

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('No internet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Materials used'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use parts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Qty'), '2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(sent!['lines'], [
      {'consumable_id': 4, 'quantity': 2},
    ]);
    expect(sent!['purpose'], 'repair');
    expect((sent!['request_key'] as String).length, 32);
  });

  testWidgets('cash retried after a failure sends the same request key', (
    tester,
  ) async {
    final keys = <String>[];
    var fail = true;
    final erp = FakeErp({
      'GET /collection/summary': (_) => (
        200,
        {
          'collected_today': 0,
          'in_hand': 0,
          'handover_due': 0,
          'expense_available': 0,
          'owners': {'cash': 'Imran', 'digital': 'Milon'},
          'can': {
            'cash': true,
            'gateway': false,
            'expense': true,
            'handover': true,
          },
        },
      ),
      'GET /collection/clients': (_) => (
        200,
        {
          'clients': [_client],
        },
      ),
      'POST /collection/cash': (o) {
        keys.add((o.data as Map)['request_key'] as String);
        if (fail) {
          fail = false;
          return (503, {'message': 'Busy'});
        }
        return (
          201,
          {
            'replayed': false,
            'payment': {
              'id': 812,
              'receipt_no': 'R-000812',
              'client': _client,
              'amount': 600,
              'method': 'cash',
              'date': '2026-11-24',
              'new_expiry': '2026-12-24',
            },
          },
        );
      },
    });
    await _pumpSignedIn(
      tester,
      erp,
      _user(['collection'], ['collection.collect']),
    );

    await tester.tap(find.text('Bill collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose client'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Karim');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('C-1001'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '600');

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    // The receipt the ERP sent back.
    expect(find.text('Receipt R-000812'), findsOne);
    expect(keys, hasLength(2));
    expect(keys.first, keys.last);
  });

  testWidgets(
    'a scanned product is sold to a client with the ERP price rules',
    (tester) async {
      Map? sale;
      final erp = FakeErp({
        'GET /sales': (_) => (
          200,
          {
            'awaiting_client': [],
            'recent': [],
            'digital_methods': ['bkash'],
          },
        ),
        'POST /sales/scan': (_) => (
          200,
          {
            'found': {
              'kind': 'item',
              'id': 3,
              'code': 'ONU-1',
              'name': 'ONU ONU-1',
            },
          },
        ),
        'GET /collection/clients': (_) => (
          200,
          {
            'clients': [_client],
          },
        ),
        'POST /sales': (o) {
          sale = o.data as Map;
          return (
            201,
            {
              'replayed': false,
              'sale': {'id': 1, 'status': 'done', 'cash_to_handover': true},
            },
          );
        },
      });
      await _pumpSignedIn(tester, erp, _user(['sales'], ['inventory.sell']));

      await tester.tap(find.text('Sell products'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sell'));
      await tester.pumpAndSettle();
      await _typeInDialog(tester, 'ONU-1');
      expect(find.text('ONU ONU-1'), findsOne);

      await tester.enterText(find.widgetWithText(TextField, 'Price'), '2200');
      await tester.tap(find.text('Choose client'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Karim');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('C-1001'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sell'));
      await tester.pumpAndSettle();

      expect(sale!['code'], 'ONU-1');
      expect(sale!['price'], 2200);
      expect(sale!['payment'], 'cash');
      expect(sale!['client_id'], 9);
      expect(
        find.text('Sold. The cash goes into your day-end handover.'),
        findsOne,
      );
    },
  );
}
