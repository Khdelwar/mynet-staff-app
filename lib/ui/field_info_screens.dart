import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/field_info.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/field.dart';
import '../state/providers.dart';
import 'common.dart';

/// STF-11: read-only field screens (stock, staff on duty, OLT, fiber near
/// me). Every list is what the ERP sent; a reseller gets only their own.

Future<void> _openMap(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _call(String phone) async {
  await launchUrl(
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), '')),
  );
}

/// Loads one ERP reply, refreshes `/me` on 403 (a permission was taken away).
mixin _Loader<W extends ConsumerStatefulWidget, T> on ConsumerState<W> {
  T? data;
  Object? error;
  bool loading = true;

  Future<T> fetch();

  Future<void> reload() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await fetch();
      if (!mounted) return;
      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  List<Widget> statusRows(AppLocalizations l) => [
    if (error != null)
      MessageBanner(errorText(l, error!, l.errGeneric), tone: BannerTone.error),
    if (loading)
      const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
  ];
}

Widget _heading(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
  child: Text(text, style: Theme.of(context).textTheme.titleMedium),
);

// --- Stock ----------------------------------------------------------------

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen>
    with _Loader<StockScreen, StockView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Future<StockView> fetch() => ref.read(apiProvider).stock(q: _search.text);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = data;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureStock)),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('stock'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const ValueKey('stock-search'),
                controller: _search,
                decoration: InputDecoration(labelText: l.stockSearch),
                onSubmitted: (_) => reload(),
              ),
            ),
            ...statusRows(l),
            if (view != null) ...[
              _heading(context, l.stockInHand),
              if (view.inHand.isEmpty)
                MessageBanner(l.stockEmpty)
              else
                for (final item in view.inHand)
                  ListTile(
                    key: ValueKey('hand-${item.id}'),
                    dense: true,
                    title: Text(
                      [
                        item.category,
                        item.model,
                      ].whereType<String>().join(' · '),
                    ),
                    subtitle: Text(
                      [item.serial, item.mac].whereType<String>().join(' · '),
                    ),
                  ),
              if (view.categories != null) ...[
                _heading(context, l.stockCategories),
                if (view.categories!.isEmpty)
                  MessageBanner(l.stockEmpty)
                else
                  for (final c in view.categories!)
                    ListTile(
                      dense: true,
                      title: Text(c.name),
                      trailing: Text('${c.inStock}'),
                    ),
              ],
              _heading(context, l.stockParts),
              if (view.parts.isEmpty)
                MessageBanner(l.stockEmpty)
              else
                for (final p in view.parts)
                  ListTile(
                    key: ValueKey('part-${p.id}'),
                    dense: true,
                    title: Text(p.name),
                    trailing: Text(
                      '${_qty(p.quantity)} ${p.unit ?? ''}'.trim() +
                          (p.low ? ' · ${l.stockLow}' : ''),
                      style: p.low
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            )
                          : null,
                    ),
                  ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  String _qty(num n) => n == n.roundToDouble() ? '${n.toInt()}' : '$n';
}

// --- Staff on duty --------------------------------------------------------

class StaffMapScreen extends ConsumerStatefulWidget {
  const StaffMapScreen({super.key});

  @override
  ConsumerState<StaffMapScreen> createState() => _StaffMapScreenState();
}

class _StaffMapScreenState extends ConsumerState<StaffMapScreen>
    with _Loader<StaffMapScreen, List<MapPerson>> {
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<List<MapPerson>> fetch() async {
    final here = await ref.read(locationReaderProvider).current();
    return ref
        .read(apiProvider)
        .staffMap(lat: here?.latitude, lng: here?.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final people = data;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureStaffMap)),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('staff-map'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ...statusRows(l),
            if (people != null && people.isEmpty) MessageBanner(l.staffNone),
            for (final p in people ?? const <MapPerson>[])
              ListTile(
                key: ValueKey('person-${p.id}'),
                leading: Icon(
                  Icons.circle,
                  size: 14,
                  color: switch (p.state) {
                    'free' => Colors.green,
                    'busy' => Colors.orange,
                    _ => scheme.outline,
                  },
                ),
                title: Text(p.name),
                subtitle: Text(
                  [
                    switch (p.state) {
                      'free' => l.staffStateFree,
                      'busy' => l.staffStateBusy,
                      _ => l.staffStateStale,
                    },
                    ?p.ticketSubject,
                    if (p.distanceM != null)
                      l.staffAway((p.distanceM! / 1000).toStringAsFixed(1)),
                    if (p.seenMinutes != null) l.staffSeen(p.seenMinutes!),
                    if (p.closedToday > 0) l.staffDoneToday(p.closedToday),
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.phone != null)
                      IconButton(
                        tooltip: l.fieldCall,
                        icon: const Icon(Icons.call_outlined),
                        onPressed: () => _call(p.phone!),
                      ),
                    if (p.lat != null && p.lng != null)
                      IconButton(
                        tooltip: l.fieldOpenMap,
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () => _openMap(p.lat!, p.lng!),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- OLT ------------------------------------------------------------------

String _oltStatus(AppLocalizations l, String status) => switch (status) {
  'online' => l.oltOnline,
  'offline' => l.oltOffline,
  _ => l.oltUnknown,
};

class OltListScreen extends ConsumerStatefulWidget {
  const OltListScreen({super.key});

  @override
  ConsumerState<OltListScreen> createState() => _OltListScreenState();
}

class _OltListScreenState extends ConsumerState<OltListScreen>
    with _Loader<OltListScreen, List<OltRow>> {
  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<List<OltRow>> fetch() => ref.read(apiProvider).olts();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final olts = data;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureOlt)),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('olts'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ...statusRows(l),
            if (olts != null && olts.isEmpty) MessageBanner(l.oltNone),
            for (final o in olts ?? const <OltRow>[])
              ListTile(
                key: ValueKey('olt-${o.id}'),
                leading: Icon(
                  Icons.router_outlined,
                  color: o.status == 'online'
                      ? Colors.green
                      : o.status == 'offline'
                      ? scheme.error
                      : scheme.outline,
                ),
                title: Text(o.name),
                subtitle: Text(
                  [
                    _oltStatus(l, o.status),
                    ?o.pop,
                    l.oltOnuSummary(
                      o.onuOnline,
                      o.onuTotal,
                      o.weak,
                      o.critical,
                    ),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OltDetailScreen(id: o.id, name: o.name),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OltDetailScreen extends ConsumerStatefulWidget {
  const OltDetailScreen({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  ConsumerState<OltDetailScreen> createState() => _OltDetailScreenState();
}

class _OltDetailScreenState extends ConsumerState<OltDetailScreen>
    with _Loader<OltDetailScreen, OltDetail> {
  bool _all = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<OltDetail> fetch() => ref.read(apiProvider).olt(widget.id, all: _all);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final detail = data;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('olt-detail'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ...statusRows(l),
            if (detail != null) ...[
              _heading(context, l.oltPorts),
              for (final p in detail.ports)
                ListTile(
                  dense: true,
                  title: Text(p.port),
                  trailing: Text(l.oltPortLine(p.online, p.total)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<bool>(
                  key: const ValueKey('onu-filter'),
                  segments: [
                    ButtonSegment(value: false, label: Text(l.oltProblemsOnly)),
                    ButtonSegment(value: true, label: Text(l.oltAllOnus)),
                  ],
                  selected: {_all},
                  onSelectionChanged: (v) {
                    setState(() => _all = v.first);
                    reload();
                  },
                ),
              ),
              if (detail.onus.isEmpty) MessageBanner(l.oltNoProblems),
              for (final o in detail.onus)
                ListTile(
                  key: ValueKey('onu-${o.id}'),
                  dense: true,
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: o.status != 'online' || o.level == 'critical'
                        ? scheme.error
                        : o.level == 'warning'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(
                    o.clientName != null
                        ? '${o.clientName} ${o.clientCode ?? ''}'.trim()
                        : (o.serial ?? '—'),
                  ),
                  subtitle: Text(
                    [
                      '${o.port}${o.onuIndex != null ? ':${o.onuIndex}' : ''}',
                      o.status,
                      ?o.downReason,
                    ].join(' · '),
                  ),
                  trailing: Text(
                    o.rxDbm != null
                        ? '${o.rxDbm!.toStringAsFixed(1)} dBm'
                        : '—',
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Fiber near me --------------------------------------------------------

class FiberNearbyScreen extends ConsumerStatefulWidget {
  const FiberNearbyScreen({super.key});

  @override
  ConsumerState<FiberNearbyScreen> createState() => _FiberNearbyScreenState();
}

class _FiberNearbyScreenState extends ConsumerState<FiberNearbyScreen>
    with _Loader<FiberNearbyScreen, List<FiberPlace>> {
  static const _radii = [500, 1000, 2500, 5000];
  int _radius = 1000;
  bool _noGps = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  Future<List<FiberPlace>> fetch() async {
    final here = await ref.read(locationReaderProvider).current();
    if (here == null) {
      if (mounted) setState(() => _noGps = true);
      return const [];
    }
    if (mounted) setState(() => _noGps = false);
    return ref
        .read(apiProvider)
        .fiberNearby(lat: here.latitude, lng: here.longitude, radiusM: _radius);
  }

  String _type(AppLocalizations l, String type) => switch (type) {
    'joint_box' => l.fiberJointBox,
    'splitter' => l.fiberSplitter,
    'pole' => l.fiberPole,
    'cut' => l.fiberCut,
    _ => type,
  };

  IconData _icon(String type) => switch (type) {
    'joint_box' => Icons.inventory_2_outlined,
    'splitter' => Icons.call_split,
    'pole' => Icons.vertical_align_top,
    'cut' => Icons.content_cut,
    _ => Icons.place_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final places = data;
    final wider = _radii.where((r) => r > _radius).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureFiber)),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          key: const ValueKey('fiber'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(l.fiberWithin(_radius)),
            ),
            ...statusRows(l),
            if (_noGps && !loading)
              MessageBanner(l.fiberNeedsGps, tone: BannerTone.warning)
            else if (places != null && places.isEmpty && !loading)
              MessageBanner(l.fiberNone),
            for (final p in places ?? const <FiberPlace>[])
              ListTile(
                key: ValueKey('fiber-${p.type}-${p.id}'),
                leading: Icon(
                  _icon(p.type),
                  color: p.type == 'cut' ? scheme.error : scheme.primary,
                ),
                title: Text([_type(l, p.type), ?p.code, ?p.name].join(' · ')),
                subtitle: Text(
                  [
                    l.fiberMeters(p.distanceM),
                    ?p.ratio,
                    if (p.portsFree != null && p.portsTotal != null)
                      l.fiberPortsFree(p.portsFree!, p.portsTotal!),
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: l.fieldOpenMap,
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => _openMap(p.lat, p.lng),
                ),
              ),
            if (wider != null && !loading && !_noGps)
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  key: const ValueKey('fiber-wider'),
                  onPressed: () {
                    setState(() => _radius = wider);
                    reload();
                  },
                  child: Text(l.fiberWider),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
