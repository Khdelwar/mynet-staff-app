import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'push/push.dart';
import 'state/providers.dart';
import 'ui/app_shell.dart';
import 'ui/lock_gate.dart';
import 'ui/login_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebasePush.instance.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      // Failed loads show a retry button instead of retrying on their own.
      retry: (_, _) => null,
      child: const StaffApp(),
    ),
  );
}

class StaffApp extends ConsumerWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: erpTheme(Brightness.light),
      darkTheme: erpTheme(Brightness.dark),
      home: !auth.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !auth.signedIn
          ? const LoginScreen()
          // A new key per sign-in so every screen reloads for that session.
          : LockGate(child: AppShell(key: ValueKey(auth.session))),
    );
  }
}
