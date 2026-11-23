import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'account_screen.dart';
import 'home_screen.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Roles and permissions belong to the ERP: re-read them on return.
    if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final connection = ref.watch(connectivityProvider).value;
    final offline =
        connection != null &&
        connection.every((c) => c == ConnectivityResult.none);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (offline)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 18),
                      const SizedBox(width: 8),
                      Text(l.offlineBanner),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [HomeScreen(), AccountScreen()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: l.tabAccount,
          ),
        ],
      ),
    );
  }
}
