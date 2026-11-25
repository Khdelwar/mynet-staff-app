import 'json.dart';

/// `GET /staff-map`: the web Staff map's payload (StaffMapPayload).
class StaffMapData {
  const StaffMapData({
    required this.centerLat,
    required this.centerLng,
    this.staff = const [],
    this.tickets = const [],
    this.route = const [],
    this.selected,
    this.suspiciousToday = 0,
  });

  final double centerLat;
  final double centerLng;
  final List<MapStaff> staff;
  final List<MapTicket> tickets;

  /// The selected person's good points today, oldest first, `[lat, lng]`.
  final List<(double, double)> route;
  final int? selected;
  final int suspiciousToday;

  factory StaffMapData.fromJson(Object? raw) {
    final m = asMap(raw);
    final center = asMap(m['center']);
    return StaffMapData(
      centerLat: toNum(center['lat'])?.toDouble() ?? 23.8103,
      centerLng: toNum(center['lng'])?.toDouble() ?? 90.4125,
      staff: [for (final s in asList(m['staff'])) MapStaff.fromJson(s)],
      tickets: [for (final t in asList(m['tickets'])) MapTicket.fromJson(t)],
      route: [
        for (final p in asList(m['route']))
          if (asList(p).length == 2 &&
              toNum(asList(p)[0]) != null &&
              toNum(asList(p)[1]) != null)
            (toNum(asList(p)[0])!.toDouble(), toNum(asList(p)[1])!.toDouble()),
      ],
      selected: toNum(m['selected'])?.toInt(),
      suspiciousToday: toNum(m['suspicious_today'])?.toInt() ?? 0,
    );
  }
}

class MapStaff {
  const MapStaff({
    required this.id,
    this.name,
    this.phone,
    this.lat,
    this.lng,
    this.battery,
    this.seenMinutes,
    this.state = 'stale',
    this.ticketId,
    this.ticketSubject,
    this.onDutySince,
    this.distanceKm,
    this.closedToday = 0,
  });

  final int id;
  final String? name;
  final String? phone;
  final double? lat;
  final double? lng;
  final int? battery;
  final int? seenMinutes;

  /// `free`, `busy` or `stale`, as the ERP decided it.
  final String state;
  final int? ticketId;
  final String? ticketSubject;
  final DateTime? onDutySince;
  final num? distanceKm;
  final int closedToday;

  bool get onMap => lat != null && lng != null;

  factory MapStaff.fromJson(Object? raw) {
    final m = asMap(raw);
    final ticket = asMap(m['ticket']);
    return MapStaff(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']),
      phone: pickString(m, const ['phone']),
      lat: toNum(m['lat'])?.toDouble(),
      lng: toNum(m['lng'])?.toDouble(),
      battery: toNum(m['battery'])?.toInt(),
      seenMinutes: toNum(m['seen_minutes'])?.toInt(),
      state: pickString(m, const ['state']) ?? 'stale',
      ticketId: toNum(ticket['id'])?.toInt(),
      ticketSubject: pickString(ticket, const ['subject']),
      onDutySince: DateTime.tryParse(
        pickString(m, const ['on_duty_since']) ?? '',
      )?.toLocal(),
      distanceKm: toNum(m['distance_km']),
      closedToday: toNum(m['closed_today'])?.toInt() ?? 0,
    );
  }
}

class MapTicket {
  const MapTicket({
    required this.id,
    required this.lat,
    required this.lng,
    this.subject,
    this.priority,
    this.status,
    this.client,
    this.assignee,
  });

  final int id;
  final double lat;
  final double lng;
  final String? subject;
  final String? priority;
  final String? status;
  final String? client;
  final String? assignee;

  factory MapTicket.fromJson(Object? raw) {
    final m = asMap(raw);
    return MapTicket(
      id: toNum(m['id'])?.toInt() ?? 0,
      lat: toNum(m['lat'])?.toDouble() ?? 0,
      lng: toNum(m['lng'])?.toDouble() ?? 0,
      subject: pickString(m, const ['subject']),
      priority: pickString(m, const ['priority']),
      status: pickString(m, const ['status']),
      client: pickString(m, const ['client']),
      assignee: pickString(m, const ['assignee']),
    );
  }
}
