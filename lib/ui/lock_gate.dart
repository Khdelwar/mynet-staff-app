import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';

/// Asks the phone to confirm it is the owner (fingerprint, face or the
/// phone's own screen lock). The app never sees or stores any of these.
Future<bool> confirmOwner(String reason) async {
  try {
    final auth = LocalAuthentication();
    if (!await auth.isDeviceSupported()) return false;
    return await auth.authenticate(localizedReason: reason);
  } catch (_) {
    return false;
  }
}

/// Covers the app until the owner unlocks it, when app lock is on: at start
/// and after the app has been in the background for a minute.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  late bool _locked = ref.read(appLockProvider);
  DateTime? _leftAt;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_asking) return; // the system prompt itself pauses the app
    if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (ref.read(appLockProvider) &&
          left != null &&
          DateTime.now().difference(left) > const Duration(minutes: 1)) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_asking || !mounted) return;
    _asking = true;
    final ok = await confirmOwner(AppLocalizations.of(context).lockReason);
    _asking = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(l.lockTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _unlock,
              icon: const Icon(Icons.fingerprint),
              label: Text(l.unlock),
            ),
          ],
        ),
      ),
    );
  }
}
