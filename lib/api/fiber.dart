import 'json.dart';

/// `GET /fiber-map`: the web Fiber & GIS map's payload (read-only).
class FiberMap {
  const FiberMap({
    required this.centerLat,
    required this.centerLng,
    this.zoom = 13,
    this.features = const [],
    this.cuts = const [],
    this.clientsTotal = 0,
    this.clientsShown = 0,
  });

  final double centerLat;
  final double centerLng;
  final double zoom;
  final List<FiberFeature> features;
  final List<FiberCutRow> cuts;
  final int clientsTotal;
  final int clientsShown;

  factory FiberMap.fromJson(Object? raw) {
    final m = asMap(raw);
    final center = asMap(m['center']);
    return FiberMap(
      centerLat: toNum(center['lat'])?.toDouble() ?? 23.8103,
      centerLng: toNum(center['lng'])?.toDouble() ?? 90.4125,
      zoom: toNum(m['zoom'])?.toDouble() ?? 13,
      features: [
        for (final f in asList(m['features'])) FiberFeature.fromJson(f),
      ],
      cuts: [for (final c in asList(m['cuts'])) FiberCutRow.fromJson(c)],
      clientsTotal: toNum(m['clients_total'])?.toInt() ?? 0,
      clientsShown: toNum(m['clients_shown'])?.toInt() ?? 0,
    );
  }
}

/// One map feature: `pole`, `joint_box`, `splitter`, `route`, `cut`, `client`.
class FiberFeature {
  const FiberFeature({
    required this.type,
    required this.id,
    required this.code,
    this.lat,
    this.lng,
    this.path = const [],
    this.details = const {},
  });

  final String type;
  final int id;
  final String code;
  final double? lat;
  final double? lng;

  /// Route line, `(lat, lng)` points.
  final List<(double, double)> path;

  /// Everything else the ERP sent (name, status, ratio, olt, pon, ports,
  /// from, to, length_m, status_label, pppoe, client_id …), as text.
  final Map<String, String> details;

  factory FiberFeature.fromJson(Object? raw) {
    final m = asMap(raw);
    const known = {'type', 'id', 'code', 'lat', 'lng', 'coordinates'};
    return FiberFeature(
      type: pickString(m, const ['type']) ?? '',
      id: toNum(m['id'])?.toInt() ?? 0,
      code: pickString(m, const ['code']) ?? '',
      lat: toNum(m['lat'])?.toDouble(),
      lng: toNum(m['lng'])?.toDouble(),
      path: [
        for (final p in asList(m['coordinates']))
          if (asList(p).length == 2 &&
              toNum(asList(p)[0]) != null &&
              toNum(asList(p)[1]) != null)
            (toNum(asList(p)[0])!.toDouble(), toNum(asList(p)[1])!.toDouble()),
      ],
      details: {
        for (final e in m.entries)
          if (!known.contains(e.key) &&
              e.value != null &&
              '${e.value}'.isNotEmpty)
            e.key: '${e.value}',
      },
    );
  }
}

class FiberCutRow {
  const FiberCutRow({
    required this.id,
    required this.code,
    this.statusLabel,
    this.route,
    this.ticketId,
    this.notes,
    this.reportedAt,
    this.lat,
    this.lng,
  });

  final int id;
  final String code;
  final String? statusLabel;
  final String? route;
  final int? ticketId;
  final String? notes;
  final DateTime? reportedAt;
  final double? lat;
  final double? lng;

  factory FiberCutRow.fromJson(Object? raw) {
    final m = asMap(raw);
    return FiberCutRow(
      id: toNum(m['id'])?.toInt() ?? 0,
      code: pickString(m, const ['code']) ?? '',
      statusLabel: pickString(m, const ['status_label', 'status']),
      route: pickString(m, const ['route']),
      ticketId: toNum(m['ticket_id'])?.toInt(),
      notes: pickString(m, const ['notes']),
      reportedAt: DateTime.tryParse(pickString(m, const ['reported_at']) ?? '')
          ?.toLocal(),
      lat: toNum(m['lat'])?.toDouble(),
      lng: toNum(m['lng'])?.toDouble(),
    );
  }
}
