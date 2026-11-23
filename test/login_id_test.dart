import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/login_id.dart';
import 'package:mynet_staff/main.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

void main() {
  test('email and a Bangladeshi mobile are login ids', () {
    expect(isStaffLoginId('tech@mynet.local'), isTrue);
    expect(isStaffLoginId('01711000001'), isTrue);
    expect(isStaffLoginId('01711-000001'), isTrue);
    expect(isStaffLoginId('+8801711000001'), isTrue);
    expect(isStaffLoginId('8801711000001'), isTrue);
    expect(isStaffLoginId('hello'), isFalse);
    expect(isStaffLoginId('017'), isFalse);
    expect(isStaffLoginId(''), isFalse);
  });

  testWidgets('a mobile number is sent as identifier', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final erp = FakeErp({
      'POST /auth/login': (o) => o.data['identifier'] == '01711-000001'
          ? (
              200,
              {
                'token': 'tok',
                'user': {'id': 1, 'name': 'Rahim'},
              },
            )
          : (401, {'code': 'invalid', 'message': 'nope'}),
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1, 'name': 'Rahim'},
        },
      ),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          configuredProvider.overrideWithValue(true),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          apiProvider.overrideWith((ref) => StaffApi(dio: erp.dio)),
        ],
        child: const StaffApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('identifier')), 'hello');
    await tester.enterText(find.byKey(const ValueKey('password')), 'pw');
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();
    expect(
      find.text('Enter the ERP email, or a mobile like 01711000001.'),
      findsOneWidget,
    );
    expect(erp.calls, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('identifier')),
      '01711-000001',
    );
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    expect(erp.calls, contains('POST /auth/login'));
    expect(erp.requests.single.data['identifier'], '01711-000001');
  });
}
