import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'state/providers.dart';
import 'ui/app_shell.dart';
import 'ui/lock_gate.dart';
import 'ui/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // MyNet blue (same as the customer app).
  static const _brand = Color(0xFF0A7AC1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ThemeData themed(Brightness brightness) {
      final scheme = ColorScheme.fromSeed(
        seedColor: _brand,
        brightness: brightness,
      );
      return ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surfaceContainerLowest,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
      );
    }

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themed(Brightness.light),
      darkTheme: themed(Brightness.dark),
      home: !auth.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !auth.signedIn
          ? const LoginScreen()
          // A new key per sign-in so every screen reloads for that session.
          : LockGate(child: AppShell(key: ValueKey(auth.session))),
    );
  }
}
