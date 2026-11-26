import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../api/fiber.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/providers.dart';
import 'common.dart';
import 'theme.dart';

/// The web Fiber & GIS map (`fiber.view`), read-only: poles, joint boxes,
/// splitters, routes, open cuts and client pins in the web's colours, layer
/// switches, tap for details, and the open cuts as a list.
class FiberMapScreen extends ConsumerStatefulWidget {
  const FiberMapScreen({super.key});

  @override
  ConsumerState<FiberMapScreen> createState() => _FiberMapScreenState();
}

/// Web map colours (fiber-gis-desk.blade.php).
const fiberColors = {
  'pole': Color(0xFFD97706),
  'joint_box': Color(0xFF7C3AED),
  'splitter': Color(0xFF0891B2),
  'client': Color(0xFF059669),
  'cut': Color(0xFFE11D48),
  'route': Color(0xFF0284C7),
};

class _FiberMapScreenState extends ConsumerState<FiberMapScreen> {
  final _map = MapController();
  final LayerHitNotifier<FiberFeature> _routeHits = ValueNotifier(null);
  FiberMap? _data;
  Object? _error;
  bool _loading = true;
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _routeHits.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(apiProvider).fiberMap();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _typeLabel(AppLocalizations l, String type) => switch (type) {
    'pole' => l.fiberPole,
    'joint_box' => l.fiberJoint,
    'splitter' => l.fiberSplitter,
    'client' => l.fiberClient,
    'cut' => l.fiberCut,
    'route' => l.fiberRoute,
    _ => type,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.featureFiber),
        actions: [
          IconButton(
            tooltip: l.retry,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: data == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      MessageBanner(
                        errorText(l, _error!, l.fiberLoadFailed),
                        tone: BannerTone.error,
                      ),
                      FilledButton(onPressed: _load, child: Text(l.retry)),
                    ],
                  ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: const ValueKey('fiber-map'),
                padding: const EdgeInsets.all(16),
                children: [
                  PageHero(
                    title: l.featureFiber,
                    help: l.fiberHelp,
                    icon: Icons.cable_outlined,
                    section: ErpSection.network,
                  ),
                  _layers(l),
                  const SizedBox(height: 10),
                  _mapCard(context, l, data),
                  if (data.clientsTotal > data.clientsShown)
                    MessageBanner(
                      l.fiberClientsLimit(data.clientsShown, data.clientsTotal),
                    ),
                  _cuts(context, l, data),
                ],
              ),
            ),
    );
  }

  /// Layer switches, one per web legend entry, in its colour.
  Widget _layers(AppLocalizations l) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final type in fiberColors.keys)
        FilterChip(
          key: ValueKey('fiber-layer-$type'),
          avatar: Container(
            width: 10,
            height: type == 'route' ? 3 : 10,
            decoration: BoxDecoration(
              color: fiberColors[type],
              shape: type == 'route' ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
          label: Text(_typeLabel(l, type)),
          selected: !_hidden.contains(type),
          showCheckmark: false,
          onSelected: (on) =>
              setState(() => on ? _hidden.remove(type) : _hidden.add(type)),
        ),
    ],
  );

  Widget _mapCard(BuildContext context, AppLocalizations l, FiberMap data) {
    final height = (MediaQuery.sizeOf(context).height * 0.5).clamp(
      280.0,
      560.0,
    );
    final shown = data.features.where((f) => !_hidden.contains(f.type));
    // Clients first, so poles, boxes and cuts sit on top of them.
    const order = ['client', 'pole', 'joint_box', 'splitter', 'cut'];
    final points = shown.where((f) => f.lat != null && f.lng != null).toList()
      ..sort((a, b) => order.indexOf(a.type).compareTo(order.indexOf(b.type)));
    return Card(
      child: SizedBox(
        height: height,
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: LatLng(data.centerLat, data.centerLng),
            initialZoom: data.zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'net.mynet.staff',
            ),
            // Tap a route line for its details, as a point (web: route popup).
            GestureDetector(
              key: const ValueKey('fiber-routes'),
              onTap: () {
                final hit = _routeHits.value?.hitValues;
                if (hit != null && hit.isNotEmpty) _details(hit.first);
              },
              child: PolylineLayer<FiberFeature>(
                hitNotifier: _routeHits,
                minimumHitbox: 16,
                polylines: [
                  for (final r in shown)
                    if (r.type == 'route' && r.path.length > 1)
                      Polyline<FiberFeature>(
                        points: [for (final (a, b) in r.path) LatLng(a, b)],
                        color: fiberColors['route']!.withValues(alpha: 0.85),
                        strokeWidth: 4,
                        hitValue: r,
                      ),
                ],
              ),
            ),
            MarkerLayer(
              markers: [
                for (final f in points)
                  Marker(
                    point: LatLng(f.lat!, f.lng!),
                    width: f.type == 'client' ? 14 : 20,
                    height: f.type == 'client' ? 14 : 20,
                    child: GestureDetector(
                      key: ValueKey('fiber-${f.type}-${f.id}'),
                      onTap: () => _details(f),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fiberColors[f.type] ?? ErpColors.slate700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap')],
            ),
          ],
        ),
      ),
    );
  }

  void _details(FiberFeature f) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          key: const ValueKey('fiber-details'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(
              children: [
                StatusBadge(_typeLabel(l, f.type)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.code,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final (label, value) in _rows(l, f)) InfoRow(label, value),
          ],
        ),
      ),
    );
  }

  /// The web popup's fields, in words.
  List<(String, String?)> _rows(AppLocalizations l, FiberFeature f) {
    final d = f.details;
    final status = switch (d['status']) {
      'active' => l.fiberActive,
      'inactive' => l.fiberInactive,
      'planned' => l.fiberPlanned,
      final other => d['status_label'] ?? other,
    };
    final reported = DateTime.tryParse(d['reported_at'] ?? '')?.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return [
      if (d['name'] != null) (l.fiberName, d['name']),
      if (d['pppoe'] != null) (l.fiberPppoe, d['pppoe']),
      if (status != null) (l.fiberStatus, status),
      if (d['ratio'] != null) (l.fiberRatio, d['ratio']),
      if (d['olt'] != null) (l.fiberOlt, d['olt']),
      if (d['pon'] != null) (l.fiberPon, d['pon']),
      if (d['ports'] != null) (l.fiberPorts, d['ports']),
      if (d['from'] != null) (l.fiberFrom, d['from']),
      if (d['to'] != null) (l.fiberTo, d['to']),
      if (d['length_m'] != null) (l.fiberLength, '${d['length_m']} m'),
      if (reported != null)
        (
          l.fiberReported,
          '${reported.year}-${two(reported.month)}-${two(reported.day)} '
              '${two(reported.hour)}:${two(reported.minute)}',
        ),
    ];
  }

  Widget _cuts(BuildContext context, AppLocalizations l, FiberMap data) {
    final theme = Theme.of(context);
    final openTicket = NavTargets.ticket;
    return SectionCard(
      key: const ValueKey('fiber-cuts'),
      title: l.fiberOpenCuts(data.cuts.length),
      children: [
        if (data.cuts.isEmpty) Text(l.fiberNoCuts),
        for (final c in data.cuts)
          Padding(
            key: ValueKey('fiber-cut-${c.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [c.code, ?c.route].join(' · '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (c.notes != null)
                        Text(c.notes!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (c.statusLabel != null)
                  StatusBadge(c.statusLabel!, tone: BadgeTone.danger),
                if (c.lat != null && c.lng != null)
                  IconButton(
                    tooltip: l.fiberShowOnMap,
                    onPressed: () => _map.move(LatLng(c.lat!, c.lng!), 17),
                    icon: const Icon(Icons.place_outlined),
                  ),
                if (c.ticketId != null && openTicket != null)
                  IconButton(
                    tooltip: l.fiberOpenTicket,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => openTicket(c.ticketId!),
                      ),
                    ),
                    icon: const Icon(Icons.confirmation_number_outlined),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
