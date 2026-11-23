import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../push/message.dart';
import '../state/providers.dart';
import 'account_screen.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'push_pages.dart';

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

  void _present(PushMessage message) {
    if (!message.tapped) {
      final l = AppLocalizations.of(context);
      final text = message.title ?? message.body ?? l.pushNotice;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          action: message.opensTicket || message.opensOffer || message.opensChat
              ? SnackBarAction(
                  label: l.pushOpen,
                  onPressed: () => _open(message),
                )
              : null,
        ),
      );
      return;
    }
    _open(message);
  }

  void _open(PushMessage message) {
    final Widget page;
    if (message.opensTicket) {
      final id = message.ticketId!;
      page =
          NavTargets.ticket?.call(id) ??
          PushTicketPage(
            ticketId: id,
            title: message.title,
            body: message.body,
            priority: message.priority,
            helper: message.type == 'ticket_helper',
            unassigned: message.type == 'ticket_unassigned',
          );
    } else if (message.opensOffer) {
      page =
          NavTargets.offers?.call(message.offerId, message.ticketId) ??
          PushOfferPage(offerId: message.offerId, ticketId: message.ticketId);
    } else if (message.opensChat) {
      page = ChatThreadScreen(conversationId: message.conversationId!);
    } else {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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
    ref.listen(pushInboxProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _present(next);
      });
    });
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
