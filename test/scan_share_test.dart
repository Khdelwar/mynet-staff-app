import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/field/scanner.dart';
import 'package:mynet_staff/field/share.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/field.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/collection_screen.dart';
import 'package:mynet_staff/ui/work_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

/// Camera code scanning and sharing the payment receipt as a picture.

class _FixedScanner implements CodeScanner {
  _FixedScanner(this.code);
  final String code;

  @override
  Future<String?> scan(BuildContext context) async => code;
}

class _RecordingSharer implements ImageSharer {
  Uint8List? png;
  String? name;

  @override
  Future<void> sharePng(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    this.png = png;
    this.name = name;
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeErp erp,
  Widget home, {
  CodeScanner? scanner,
  ImageSharer? sharer,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
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
      codeScannerProvider.overrideWithValue(scanner ?? const NoScanner()),
      imageSharerProvider.overrideWithValue(sharer ?? const NoSharer()),
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

void main() {
  testWidgets('a code read by the camera goes to the ticket scan', (
    tester,
  ) async {
    Map? body;
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {
            'id': 1,
            'name': 'Rahim',
            'permissions': ['inventory.use'],
          },
        },
      ),
      'GET /tickets/41/materials': (_) => (
        200,
        {
          'materials': [],
          'parts': [],
          'purposes': ['repair'],
        },
      ),
      'POST /tickets/41/scan': (o) {
        body = o.data as Map;
        return (201, {'replayed': false, 'materials': []});
      },
    });
    await _pump(
      tester,
      erp,
      const MaterialsScreen(ticketId: 41, canScan: true),
      scanner: _FixedScanner('VSOL-77'),
    );

    await tester.tap(find.byKey(const ValueKey('scan-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ask-scan')));
    await tester.pumpAndSettle();

    expect(body!['code'], 'VSOL-77');
    expect((body!['request_key'] as String).isNotEmpty, isTrue);
  });

  testWidgets('the ERP receipt is shared as a picture', (tester) async {
    final sharer = _RecordingSharer();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {
            'id': 1,
            'name': 'Rakib',
            'permissions': ['collection.collect'],
          },
        },
      ),
      'GET /collection/clients': (_) => (
        200,
        {
          'clients': [
            {'id': 9, 'code': 'C-1001', 'name': 'Karim', 'due': 600},
          ],
        },
      ),
      'POST /collection/cash': (_) => (
        201,
        {
          'replayed': false,
          'payment': {
            'id': 812,
            'receipt_no': 'R-000812',
            'amount': 600,
            'method': 'cash',
            'approval_status': 'pending',
            'paid_sms': 'after_approval',
            'client': {'id': 9, 'name': 'Karim'},
          },
        },
      ),
    });
    await _pump(tester, erp, const CollectScreen(cash: true), sharer: sharer);

    await tester.enterText(find.byKey(const ValueKey('collect-search')), 'ka');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-client-9')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('collect-amount')), '600');
    await tester.tap(find.byKey(const ValueKey('collect-submit')));
    await tester.pumpAndSettle();
    expect(find.text('R-000812'), findsOne);

    // Drawing the picture takes real time, not the test clock.
    await tester.tap(find.byKey(const ValueKey('share-receipt')));
    for (var i = 0; i < 40 && sharer.png == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }

    expect(sharer.name, 'R-000812');
    // A real PNG: starts with the PNG signature.
    expect(sharer.png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });
}
