import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../api/staff_api.dart';
import '../api/staff_map.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/providers.dart';
import 'common.dart';
import 'theme.dart';

/// The web Staff map (`staff.location.view`): staff on duty and open
/// tickets on OpenStreetMap, one person's route today when tapped. Same
/// colours and words as the web page; refreshes every 30 seconds as the web.
class StaffMapScreen extends ConsumerStatefulWidget {
  const StaffMapScreen({super.key});

  @override
  ConsumerState<StaffMapScreen> createState() => _StaffMapScreenState();
}

/// Web legend colours: free emerald-600, busy amber-500, stale slate-400,
/// ticket rose-600, route sky-600.
const _stateColors = {
  'free': Color(0xFF059669),
  'busy': Color(0xFFF59E0B),
  'stale': Color(0xFF94A3B8),
};
const _ticketColor = Color(0xFFE11D48);
const _routeColor = Color(0xFF0284C7);

class _StaffMapScreenState extends ConsumerState<StaffMapScreen> {
  final _map = MapController();
  StaffMapData? _data;
  Object? _error;
  bool _loading = true;
  int? _selected;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ref.read(apiProvider).staffMap(user: _selected);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
        // Someone who left duty is no longer selected (as the web).
        _selected = data.selected;
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

  Future<void> _select(MapStaff? person) async {
    setState(() => _selected = person?.id);
    if (person != null && person.onMap) {
      _map.move(LatLng(person.lat!, person.lng!), 14);
    }
    await _load();
  }

  String _stateLabel(AppLocalizations l, String state) => switch (state) {
    'free' => l.mapFree,
    'busy' => l.mapBusy,
    _ => l.mapStale,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.featureStaffMap),
        actions: [
          IconButton(
            key: const ValueKey('map-refresh'),
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
                        errorText(l, _error!, l.mapLoadFailed),
                        tone: BannerTone.error,
                      ),
                      FilledButton(onPressed: _load, child: Text(l.retry)),
                    ],
                  ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                key: const ValueKey('staff-map'),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    MessageBanner(
                      errorText(l, _error!, l.mapLoadFailed),
                      tone: BannerTone.warning,
                    ),
                  _mapCard(context, data),
                  _legend(context, l),
                  const SizedBox(height: 12),
                  if (_selectedPerson(data) case final person?)
                    _detail(context, l, data, person),
                  _list(context, l, data),
                  Text(
                    l.mapIntro,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }

  MapStaff? _selectedPerson(StaffMapData data) {
    for (final s in data.staff) {
      if (s.id == _selected) return s;
    }
    return null;
  }

  Widget _mapCard(BuildContext context, StaffMapData data) {
    final height = MediaQuery.sizeOf(context).height * 0.48;
    return Card(
      child: SizedBox(
        height: height.clamp(260, 520),
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: LatLng(data.centerLat, data.centerLng),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'net.mynet.staff',
            ),
            if (data.route.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [for (final (a, b) in data.route) LatLng(a, b)],
                    color: _routeColor.withValues(alpha: 0.8),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final t in data.tickets)
                  Marker(
                    point: LatLng(t.lat, t.lng),
                    width: 22,
                    height: 22,
                    child: GestureDetector(
                      key: ValueKey('map-ticket-${t.id}'),
                      onTap: () => _ticketTapped(t),
                      child: Center(
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _ticketColor,
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final s in data.staff)
                  if (s.onMap)
                    Marker(
                      point: LatLng(s.lat!, s.lng!),
                      width: 150,
                      height: 24,
                      alignment: const Alignment(0.78, 0),
                      child: GestureDetector(
                        key: ValueKey('map-staff-${s.id}'),
                        onTap: () => _select(s),
                        child: _StaffDot(
                          name: s.name ?? '',
                          color: _stateColors[s.state] ?? ErpColors.slate700,
                          selected: s.id == _selected,
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

  void _ticketTapped(MapTicket t) {
    final l = AppLocalizations.of(context);
    final open = NavTargets.ticket;
    if (open != null) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => open(t.id)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          [
            '${l.mapTicket} #${t.id}',
            ?t.subject,
            ?t.client,
            ?t.assignee,
          ].join(' · '),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, AppLocalizations l) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget dot(Color c, String text, {bool diamond = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: diamond ? 0.785398 : 0,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: c,
              shape: diamond ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: style),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(_stateColors['free']!, l.mapFree),
        dot(_stateColors['busy']!, l.mapBusy),
        dot(_stateColors['stale']!, l.mapStale),
        dot(_ticketColor, l.mapLegendTicket, diamond: true),
      ],
    );
  }

  Widget _list(BuildContext context, AppLocalizations l, StaffMapData data) {
    final theme = Theme.of(context);
    return SectionCard(
      title: l.mapOnDuty(data.staff.length),
      children: [
        if (data.staff.isEmpty)
          Text(l.mapNobody, style: theme.textTheme.bodyMedium)
        else
          for (final s in data.staff)
            InkWell(
              key: ValueKey('map-row-${s.id}'),
              onTap: () => _select(s.id == _selected ? null : s),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _stateColors[s.state] ?? ErpColors.slate700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: s.id == _selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            [
                              _stateLabel(l, s.state),
                              s.seenMinutes != null
                                  ? l.mapSeenAgo(s.seenMinutes!)
                                  : l.mapNoPoint,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _detail(
    BuildContext context,
    AppLocalizations l,
    StaffMapData data,
    MapStaff s,
  ) {
    String two(int v) => v.toString().padLeft(2, '0');
    final since = s.onDutySince;
    return SectionCard(
      key: const ValueKey('map-detail'),
      title: s.name ?? '—',
      trailing: TextButton(
        key: const ValueKey('map-show-all'),
        onPressed: () => _select(null),
        child: Text(l.mapShowAll),
      ),
      children: [
        if (s.ticketId != null)
          InfoRow(
            l.mapTicket,
            '#${s.ticketId}${s.ticketSubject != null ? ' · ${s.ticketSubject}' : ''}',
          ),
        InfoRow(
          l.mapDistance,
          s.distanceKm == null ? null : '${s.distanceKm} km',
        ),
        InfoRow(l.mapClosedToday, '${s.closedToday}'),
        InfoRow(
          l.mapOnDutySince,
          since == null ? null : '${two(since.hour)}:${two(since.minute)}',
        ),
        if (s.battery != null) InfoRow(l.mapBattery, '${s.battery}%'),
        if (data.suspiciousToday > 0) ...[
          const SizedBox(height: 8),
          MessageBanner(
            l.mapSuspicious(data.suspiciousToday),
            tone: BannerTone.warning,
          ),
        ],
      ],
    );
  }
}

/// A staff dot with a small name label beside it (web: circle + tooltip).
class _StaffDot extends StatelessWidget {
  const _StaffDot({
    required this.name,
    required this.color,
    required this.selected,
  });
  final String name;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 22 : 18,
          height: selected ? 22 : 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: ErpColors.slate300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: ErpColors.slate900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
