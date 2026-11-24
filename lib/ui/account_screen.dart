import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../config.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'devices_screen.dart';
import 'lock_gate.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _toggleLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var supported = false;
    try {
      supported = await LocalAuthentication().isDeviceSupported();
    } catch (_) {
      supported = false;
    }
    if (!supported) {
      messenger.showSnackBar(SnackBar(content: Text(l.appLockUnsupported)));
      return;
    }
    // Turning it on or off both need the owner of the phone.
    if (await confirmOwner(l.lockReason)) {
      ref.read(appLockProvider.notifier).set(enable);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.logout),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider.select((a) => a.user));
    final locked = ref.watch(appLockProvider);
    final server = ref.watch(serverProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.accountTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SectionCard(
          children: [
            InfoRow(l.email, user?.email),
            InfoRow(l.mobile, user?.phone ?? user?.staff?.mobile),
            InfoRow(
              l.serverLabel,
              server == null ? null : AppConfig.displayServer(server),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l.language),
                trailing: TextButton(
                  onPressed: ref.read(localeProvider.notifier).toggle,
                  child: Text(l.languageToggle),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(l.appLock),
                subtitle: Text(l.appLockHint),
                value: locked,
                onChanged: (v) => _toggleLock(context, ref, v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          key: const ValueKey('devices'),
          leading: const Icon(Icons.phonelink_outlined),
          title: Text(l.devicesTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DevicesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('logout'),
          onPressed: () => _logout(context, ref),
          icon: const Icon(Icons.logout),
          label: Text(l.logout),
        ),
      ],
    );
  }
}
