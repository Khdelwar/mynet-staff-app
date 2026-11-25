import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/olt.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';
import 'theme.dart';

/// The ERP's OLT pages, read-only: OLT list → PON ports → a port's ONUs,
/// and unmatched ONUs. The ERP scopes a reseller to their own OLTs.

/// Web `x-olt.rx-value`: green / orange / red by the ERP's signal level,
/// else by -25 / -28 dBm.
Color rxColor(num? rx, String? level) {
  if (rx == null) return ErpColors.slate500;
  return switch (level) {
    'ok' || 'good' => ErpColors.accent700,
    'warning' => const Color(0xFFEA580C),
    'critical' => ErpColors.rose700,
    'unknown' => ErpColors.slate500,
    _ =>
      rx >= -25
          ? ErpColors.accent700
          : (rx >= -28 ? const Color(0xFFEA580C) : ErpColors.rose700),
  };
}

String rxText(num? rx) => rx == null ? '—' : '${rx.toStringAsFixed(2)} dBm';

BadgeTone onuTone(String status) => switch (status) {
  'online' => BadgeTone.success,
  'offline' || 'los' || 'dying_gasp' => BadgeTone.danger,
  _ => BadgeTone.neutral,
};

/// Loads once, shows the error with a retry, refreshes on pull.
class _Load<T> extends ConsumerStatefulWidget {
  const _Load({required this.load, required this.builder});
  final Future<T> Function(StaffApi api) load;
  final Widget Function(BuildContext, T, Future<void> Function()) builder;

  @override
  ConsumerState<_Load<T>> createState() => _LoadState<T>();
}

class _LoadState<T> extends ConsumerState<_Load<T>> {
  T? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await widget.load(ref.read(apiProvider));
      if (mounted) setState(() => (_data = data, _error = null));
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = _data;
    if (data == null) {
      if (_error == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MessageBanner(
            errorText(l, _error!, l.oltLoadFailed),
            tone: BannerTone.error,
          ),
          FilledButton(onPressed: _reload, child: Text(l.retry)),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, data, _reload),
    );
  }
}

/// Small "label: number" figure used on OLT and port rows.
class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {this.color});
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: theme.textTheme.bodySmall),
          TextSpan(
            text: '$value',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class OltListScreen extends StatelessWidget {
  const OltListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureOlt)),
      body: _Load<OltList>(
        load: (api) => api.olts(),
        builder: (context, data, _) => ListView(
          key: const ValueKey('olt-list'),
          padding: const EdgeInsets.all(16),
          children: [
            PageHero(
              title: l.featureOlt,
              help: l.oltHelp,
              icon: Icons.router_outlined,
              section: ErpSection.network,
            ),
            if (data.unmatched > 0)
              Card(
                child: ListTile(
                  key: const ValueKey('olt-unmatched'),
                  leading: const Icon(Icons.link_off),
                  title: Text(l.oltUnmatched(data.unmatched)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UnmatchedOnusScreen(),
                    ),
                  ),
                ),
              ),
            if (data.olts.isEmpty) MessageBanner(l.oltNone),
            for (final o in data.olts) _OltCard(olt: o),
            if (data.alerts.isNotEmpty)
              SectionCard(
                title: l.oltAlerts,
                children: [
                  for (final a in data.alerts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: a.level == 'critical'
                                ? ErpColors.rose700
                                : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [?a.olt, ?a.message].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OltCard extends StatelessWidget {
  const _OltCard({required this.olt});
  final OltRow olt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        key: ValueKey('olt-${olt.id}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OltPortsScreen(oltId: olt.id, name: olt.name),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(olt.name, style: theme.textTheme.titleSmall),
                  ),
                  if (!olt.isActive)
                    StatusBadge(l.oltInactive)
                  else if (olt.reachable == false)
                    StatusBadge(l.oltUnreachable, tone: BadgeTone.danger),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              if (olt.type != null || olt.pop != null)
                Text(
                  [?olt.type, ?olt.pop].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _Figure(l.oltOnus, olt.onus),
                  _Figure(l.oltOnline, olt.online, color: ErpColors.accent700),
                  _Figure(
                    l.oltOffline,
                    olt.offline,
                    color: olt.offline > 0 ? ErpColors.rose700 : null,
                  ),
                  _Figure(
                    l.oltWeak,
                    olt.weakRx,
                    color: olt.weakRx > 0 ? const Color(0xFFEA580C) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OltPortsScreen extends StatelessWidget {
  const OltPortsScreen({super.key, required this.oltId, required this.name});
  final int oltId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: _Load<OltPorts>(
        load: (api) => api.oltPorts(oltId),
        builder: (context, data, _) => ListView(
          key: const ValueKey('olt-ports'),
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: [data.name, ?data.pop].join(' · '),
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _Figure(l.oltOnus, data.onus),
                    _Figure(
                      l.oltOnline,
                      data.online,
                      color: ErpColors.accent700,
                    ),
                    _Figure(
                      l.oltOffline,
                      data.offline,
                      color: data.offline > 0 ? ErpColors.rose700 : null,
                    ),
                  ],
                ),
              ],
            ),
            SectionLabel(l.oltPorts),
            for (final p in data.ports)
              Card(
                child: ListTile(
                  key: ValueKey('port-${p.port}'),
                  title: Text(p.label, style: theme.textTheme.titleSmall),
                  subtitle: Wrap(
                    spacing: 12,
                    children: [
                      _Figure(l.oltOnus, p.onus),
                      _Figure(
                        l.oltOnline,
                        p.online,
                        color: ErpColors.accent700,
                      ),
                      _Figure(
                        l.oltOffline,
                        p.offline,
                        color: p.offline > 0 ? ErpColors.rose700 : null,
                      ),
                      if (p.weakRx != null) _Figure(l.oltWeak, p.weakRx!),
                    ],
                  ),
                  trailing: p.dead
                      ? StatusBadge(l.oltPortDead, tone: BadgeTone.danger)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PonOnusScreen(
                        oltId: oltId,
                        port: p.port,
                        title: '${data.name} · ${p.label}',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnuTile extends StatelessWidget {
  const _OnuTile({required this.onu});
  final OnuRow onu;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final client = onu.clientName == null
        ? l.oltNoClient
        : [?onu.clientName, ?onu.clientCode].join(' · ');
    final sub = [
      ?onu.olt,
      ?onu.onu,
      ?onu.serial,
      if (onu.distanceM != null) '${onu.distanceM} m',
      ?onu.uptime,
    ].join(' · ');
    return Padding(
      key: ValueKey('onu-${onu.id}'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty) Text(sub, style: theme.textTheme.bodySmall),
                if (onu.description != null)
                  Text(onu.description!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                onu.statusLabel ?? onu.status,
                tone: onuTone(onu.status),
              ),
              const SizedBox(height: 4),
              Text(
                rxText(onu.rxDbm),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: rxColor(onu.rxDbm, onu.signalLevel),
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PonOnusScreen extends ConsumerStatefulWidget {
  const PonOnusScreen({
    super.key,
    required this.oltId,
    required this.port,
    required this.title,
  });
  final int oltId;
  final String port;
  final String title;

  @override
  ConsumerState<PonOnusScreen> createState() => _PonOnusScreenState();
}

class _PonOnusScreenState extends ConsumerState<PonOnusScreen> {
  String _filter = 'all';
  String _sort = 'pon';
  String _dir = 'asc';
  OnuPage? _page;
  List<OnuRow> _rows = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() => _loading = true);
    try {
      final next = await ref
          .read(apiProvider)
          .ponOnus(
            widget.oltId,
            widget.port,
            filter: _filter,
            sort: _sort,
            dir: _dir,
            page: more ? (_page?.page ?? 0) + 1 : 1,
          );
      if (!mounted) return;
      setState(() {
        _page = next;
        _rows = more ? [..._rows, ...next.onus] : [...next.onus];
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = _page;
    final filters = {
      'all': l.oltFilterAll,
      'good': l.oltFilterGood,
      'warning': l.oltFilterWarning,
      'critical': l.oltFilterCritical,
      'down': l.oltFilterDown,
      'weak_rx': l.oltFilterWeak,
    };
    final sorts = {
      'pon': l.oltSortPon,
      'rx': l.oltSortRx,
      'distance': l.oltSortDistance,
      'uptime': l.oltSortUptime,
      'status': l.oltSortStatus,
    };
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('pon-onus'),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(:key, :value) in filters.entries)
                  ChoiceChip(
                    key: ValueKey('onu-filter-$key'),
                    label: Text(value),
                    selected: _filter == key,
                    onSelected: (_) {
                      setState(() => _filter = key);
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('onu-sort'),
                    initialValue: _sort,
                    decoration: InputDecoration(labelText: l.oltSort),
                    items: [
                      for (final MapEntry(:key, :value) in sorts.entries)
                        DropdownMenuItem(value: key, child: Text(value)),
                    ],
                    onChanged: (v) {
                      setState(() => _sort = v ?? 'pon');
                      _load();
                    },
                  ),
                ),
                IconButton(
                  key: const ValueKey('onu-dir'),
                  onPressed: () {
                    setState(() => _dir = _dir == 'asc' ? 'desc' : 'asc');
                    _load();
                  },
                  icon: Icon(
                    _dir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.oltLoadFailed),
                tone: BannerTone.error,
              ),
            if (page != null)
              SectionCard(
                title: '${l.oltOnus} (${page.total})',
                trailing: page.avgRx == null
                    ? null
                    : Text(
                        l.oltAvgRx(page.avgRx!.toStringAsFixed(2)),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: rxColor(page.avgRx, null)),
                      ),
                children: [
                  if (_rows.isEmpty) Text(l.oltNoOnus),
                  for (final o in _rows) _OnuTile(onu: o),
                  if (page.hasMore)
                    TextButton(
                      key: const ValueKey('onu-more'),
                      onPressed: _loading ? null : () => _load(more: true),
                      child: Text(l.oltMore),
                    ),
                ],
              ),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class UnmatchedOnusScreen extends ConsumerStatefulWidget {
  const UnmatchedOnusScreen({super.key});

  @override
  ConsumerState<UnmatchedOnusScreen> createState() =>
      _UnmatchedOnusScreenState();
}

class _UnmatchedOnusScreenState extends ConsumerState<UnmatchedOnusScreen> {
  final _search = TextEditingController();
  OnuPage? _page;
  List<OnuRow> _rows = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() => _loading = true);
    try {
      final next = await ref
          .read(apiProvider)
          .unmatchedOnus(
            q: _search.text,
            page: more ? (_page?.page ?? 0) + 1 : 1,
          );
      if (!mounted) return;
      setState(() {
        _page = next;
        _rows = more ? [..._rows, ...next.onus] : [...next.onus];
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = _page;
    return Scaffold(
      appBar: AppBar(title: Text(l.oltUnmatched(page?.total ?? 0))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('unmatched-onus'),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const ValueKey('unmatched-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                labelText: l.oltSearchOnu,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.oltLoadFailed),
                tone: BannerTone.error,
              ),
            if (page != null)
              SectionCard(
                children: [
                  if (_rows.isEmpty) Text(l.oltNoOnus),
                  for (final o in _rows) _OnuTile(onu: o),
                  if (page.hasMore)
                    TextButton(
                      key: const ValueKey('unmatched-more'),
                      onPressed: _loading ? null : () => _load(more: true),
                      child: Text(l.oltMore),
                    ),
                ],
              ),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
