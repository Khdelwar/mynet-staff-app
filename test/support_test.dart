import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/field/location.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/field.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/approvals_screen.dart';
import 'package:mynet_staff/ui/client_detail_screen.dart';
import 'package:mynet_staff/ui/collection_screen.dart';
import 'package:mynet_staff/ui/support_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Approvals (handover part / reject, others' expenses), support work (new
/// client, contact, new ticket) and "near me with due", against a fake ERP.

class _HereLocation implements LocationReader {
  @override
  Future<GeoFix?> current() async =>
      const GeoFix(latitude: 23.81, longitude: 90.41, accuracy: 8);
}

Map<String, dynamic> _me(List<String> permissions) => {
  'user': {'id': 1, 'name': 'Rakib', 'permissions': permissions},
};

Future<void> _pump(WidgetTester tester, FakeErp erp, Widget home) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      secretStoreProvider.overrideWithValue(
        MemorySecretStore()..values[sessionTokenKey] = 'tok',
      ),
      apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
      locationReaderProvider.overrideWithValue(_HereLocation()),
    ],
  );
  addTearDown(container.dispose);
  container.read(authProvider);
  await tester.pump();
  await tester.pump();
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

Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('approval-input')), text);
  await tester.tap(find.byKey(const ValueKey('approval-ok')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('approvals: part of a handover, rejecting an expense needs why', (
    tester,
  ) async {
    final posts = <String, Map>{};
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['collection.approve'])),
      'GET /collection/approvals': (_) => (
        200,
        {
          'handovers': [
            {
              'id': 5,
              'collector': {'name': 'Sumon'},
              'amount': 1200,
            },
          ],
          'expenses': [
            {
              'id': 8,
              'collector': {'name': 'Sumon'},
              'amount': 80,
              'note': 'Fuel',
            },
          ],
        },
      ),
      'POST /collection/handovers/5/approve': (o) {
        posts['handover'] = o.data as Map;
        return (200, {'ok': true});
      },
      'POST /collection/expenses/8/reject': (o) {
        posts['expense'] = o.data as Map;
        return (200, {'ok': true});
      },
    });
    await _pump(tester, erp, const ApprovalsScreen());

    expect(find.text('Fuel'), findsOne);

    await tester.tap(find.byKey(const ValueKey('approve-5')));
    await tester.pumpAndSettle();
    await _answer(tester, '1000');
    expect(posts['handover']!['amount'], 1000);

    await tester.tap(find.byKey(const ValueKey('expense-reject-8')));
    await tester.pumpAndSettle();
    // An empty reason is not sent.
    await tester.tap(find.byKey(const ValueKey('approval-ok')));
    await tester.pumpAndSettle();
    expect(posts.containsKey('expense'), isFalse);
    await _answer(tester, 'No receipt');
    expect(posts['expense']!['note'], 'No receipt');
  });

  testWidgets('quick-add a client shows the ERP field error', (tester) async {
    Map? body;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['clients.create'])),
      'GET /clients/form-options': (_) => (
        200,
        {
          'packages': [
            {'id': 3, 'name': 'Home 20', 'price': 800},
          ],
          'pops': [],
        },
      ),
      'POST /clients': (o) {
        body = o.data as Map;
        return (
          422,
          {
            'message': 'Taken',
            'errors': {
              'pppoe_username': ['This PPPoE ID is already used.'],
            },
          },
        );
      },
    });
    await _pump(tester, erp, const NewClientScreen());

    await tester.enterText(find.byKey(const ValueKey('nc-user')), 'karim5');
    await tester.enterText(
      find.byKey(const ValueKey('nc-password')),
      'pass1234',
    );
    await tester.tap(find.byKey(const ValueKey('nc-package')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home 20 (800)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nc-save')));
    await tester.pumpAndSettle();

    expect(body!['pppoe_username'], 'karim5');
    expect(body!['package_id'], 3);
    expect(body!.containsKey('pop_id'), isFalse);
    expect(find.text('This PPPoE ID is already used.'), findsOne);
  });

  testWidgets('client page: fix the phone, open a ticket, see suggestions', (
    tester,
  ) async {
    Map? contact;
    Map? ticket;
    var clientPhone = '01710000000';
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        _me([
          'clients.view',
          'clients.update',
          'tickets.create',
          'tickets.assign',
        ]),
      ),
      'GET /clients/9': (_) => (
        200,
        {
          'client': {
            'id': 9,
            'code': 'C-1001',
            'name': 'Karim',
            'phone': clientPhone,
            'can': {'update': true, 'open_ticket': true},
          },
        },
      ),
      'PATCH /clients/9/contact': (o) {
        contact = o.data as Map;
        clientPhone = contact!['value'] as String;
        return (200, {'ok': true});
      },
      'GET /tickets/options': (_) => (
        200,
        {
          'categories': [],
          'priorities': ['low', 'high'],
        },
      ),
      'POST /tickets': (o) {
        ticket = o.data as Map;
        return (
          201,
          {
            'ticket': {'id': 77, 'subject': 'No internet'},
            'suggestions': [],
          },
        );
      },
      'GET /tickets/77/suggestions': (_) => (
        200,
        {
          'suggestions': [
            {
              'user': {'id': 7, 'name': 'Rahim'},
              'score': 71,
            },
          ],
        },
      ),
      'GET /tickets': (_) => (200, {'tickets': []}),
    });
    await _pump(tester, erp, const ClientDetailScreen(clientId: 9));

    await tester.tap(find.byKey(const ValueKey('edit-phone')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('contact-value')),
      '01799999999',
    );
    await tester.tap(find.byKey(const ValueKey('contact-save')));
    await tester.pumpAndSettle();
    expect(contact, {'field': 'phone', 'value': '01799999999'});
    expect(find.text('01799999999'), findsOne);

    await tester.tap(find.byKey(const ValueKey('client-new-ticket')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nt-subject')),
      'No internet',
    );
    await tester.tap(find.byKey(const ValueKey('nt-save')));
    await tester.pumpAndSettle();

    expect(ticket!['client_id'], 9);
    expect(ticket!['subject'], 'No internet');
    // People who assign land on the nearest technicians for the new ticket.
    expect(erp.calls, contains('GET /tickets/77/suggestions'));
    expect(find.text('Rahim'), findsOne);
  });

  testWidgets('near me with due sends the phone position', (tester) async {
    Map<String, dynamic>? query;
    final erp = FakeErp({
      'GET /me': (_) => (200, _me(['collection.collect', 'billing.collect'])),
      'GET /collection/clients': (o) {
        query = o.queryParameters;
        return (
          200,
          {
            'clients': [
              {
                'id': 9,
                'code': 'C-1001',
                'name': 'Karim',
                'due': 600,
                'distance_m': 640,
              },
            ],
          },
        );
      },
    });
    await _pump(tester, erp, const CollectScreen(cash: true));

    await tester.tap(find.byKey(const ValueKey('collect-near-me')));
    await tester.pumpAndSettle();

    expect(query!['lat'], 23.81);
    expect(query!['lng'], 90.41);
    expect(query!['due_only'], 1);
    expect(find.textContaining('640 m away'), findsOne);
  });
}
