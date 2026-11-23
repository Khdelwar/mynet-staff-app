import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/devices.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  List<StaffDevice> _devices = const [];
  Object? _error;
  bool _loading = true;
  int? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await ref.read(apiProvider).devices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _revoke(StaffDevice device) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(
          device.thisDevice ? l.devicesSignOutThis : l.devicesSignOutOther,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.devicesSignOut),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = device.id);
    try {
      await ref.read(apiProvider).revokeDevice(device.id);
      if (!mounted) return;
      if (device.thisDevice) {
        await ref.read(authProvider.notifier).logout();
        return;
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(l, e, l.errGeneric))));
      setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.devicesTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('devices'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.errGeneric),
                tone: BannerTone.error,
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_devices.isEmpty)
              MessageBanner(l.devicesEmpty)
            else
              for (final device in _devices)
                Card(
                  key: ValueKey('device-${device.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(device.name ?? l.devicesUnnamed),
                    subtitle: Text(
                      [
                        if (device.thisDevice) l.devicesThisPhone,
                        if (device.appVersion != null) device.appVersion,
                        if (device.lastUsedAt != null) device.lastUsedAt,
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      key: ValueKey('revoke-${device.id}'),
                      tooltip: l.devicesSignOut,
                      onPressed: _busy == null ? () => _revoke(device) : null,
                      icon: const Icon(Icons.phonelink_erase),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
