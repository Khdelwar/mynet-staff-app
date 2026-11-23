import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynet_staff/api/staff_api.dart';
import 'package:mynet_staff/l10n/app_localizations.dart';
import 'package:mynet_staff/state/providers.dart';
import 'package:mynet_staff/state/stores.dart';
import 'package:mynet_staff/ui/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_erp.dart';

void main() {
  testWidgets('opens a conversation and sends the reply', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final erp = FakeErp({
      'GET /me': (_) => (
        200,
        {
          'user': {'id': 1, 'name': 'Rahim'},
        },
      ),
      'GET /chats': (_) => (
        200,
        {
          'unread_conversations': 1,
          'conversations': [
            {
              'id': 4,
              'client': {'id': 9, 'name': 'Karim', 'code': 'C-1001'},
              'unread': 1,
              'preview': 'No internet',
            },
          ],
        },
      ),
      'GET /chats/4': (_) => (
        200,
        {
          'conversation': {
            'id': 4,
            'client': {'name': 'Karim'},
          },
          'messages': [
            {'id': 1, 'sender': 'client', 'body': 'No internet'},
          ],
        },
      ),
      'POST /chats/4/messages': (o) => (
        201,
        {
          'message': {
            'id': 2,
            'sender': 'staff',
            'body': o.data['body'],
            'staff': {'id': 1, 'name': 'Rahim'},
          },
        },
      ),
    });
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        secretStoreProvider.overrideWithValue(
          MemorySecretStore()..values[sessionTokenKey] = 'tok',
        ),
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
          home: ChatListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-4')));
    await tester.pumpAndSettle();
    expect(find.text('No internet'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chat-body')),
      'On the way',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    final sent = erp.requests.lastWhere(
      (r) => r.uri.path.endsWith('/messages'),
    );
    expect(sent.data['body'], 'On the way');
    expect(find.text('On the way'), findsOneWidget);
  });
}
