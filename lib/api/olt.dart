import 'json.dart';

/// `GET /olts`: the web OLT page (read-only).
class OltList {
  const OltList({
    this.olts = const [],
    this.alerts = const [],
    this.unmatched = 0,
  });
  final List<OltRow> olts;
  final List<OltAlertRow> alerts;
  final int unmatched;

  factory OltList.fromJson(Object? raw) {
    final m = asMap(raw);
    return OltList(
      olts: [for (final o in asList(m['olts'])) OltRow.fromJson(o)],
      alerts: [for (final a in asList(m['alerts'])) OltAlertRow.fromJson(a)],
      unmatched: toNum(m['unmatched'])?.toInt() ?? 0,
    );
  }
}

class OltRow {
  const OltRow({
    required this.id,
    required this.name,
    this.type,
    this.pop,
    this.isActive = true,
    this.reachable,
    this.lastError,
    this.onus = 0,
    this.online = 0,
    this.offline = 0,
    this.weakRx = 0,
  });
  final int id;
  final String name;
  final String? type;
  final String? pop;
  final bool isActive;
  final bool? reachable;
  final String? lastError;
  final int onus;
  final int online;
  final int offline;
  final int weakRx;

  factory OltRow.fromJson(Object? raw) {
    final m = asMap(raw);
    return OltRow(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      type: pickString(m, const ['type']),
      pop: pickString(m, const ['pop']),
      isActive: m['is_active'] != false,
      reachable: m['reachable'] is bool ? m['reachable'] as bool : null,
      lastError: pickString(m, const ['last_error']),
      onus: toNum(m['onus'])?.toInt() ?? 0,
      online: toNum(m['online'])?.toInt() ?? 0,
      offline: toNum(m['offline'])?.toInt() ?? 0,
      weakRx: toNum(m['weak_rx'])?.toInt() ?? 0,
    );
  }
}

class OltAlertRow {
  const OltAlertRow({this.olt, this.message, this.level, this.at});
  final String? olt;
  final String? message;
  final String? level;
  final DateTime? at;

  factory OltAlertRow.fromJson(Object? raw) {
    final m = asMap(raw);
    return OltAlertRow(
      olt: pickString(m, const ['olt']),
      message: pickString(m, const ['message']),
      level: pickString(m, const ['level']),
      at: DateTime.tryParse(pickString(m, const ['at']) ?? '')?.toLocal(),
    );
  }
}

/// `GET /olts/{id}`: PON ports, problems first.
class OltPorts {
  const OltPorts({
    required this.name,
    this.pop,
    this.ports = const [],
    this.onus = 0,
    this.online = 0,
    this.offline = 0,
    this.weakRx = 0,
  });
  final String name;
  final String? pop;
  final List<PonPortRow> ports;
  final int onus;
  final int online;
  final int offline;
  final int weakRx;

  factory OltPorts.fromJson(Object? raw) {
    final m = asMap(raw);
    final olt = asMap(m['olt']);
    final t = asMap(m['totals']);
    return OltPorts(
      name: pickString(olt, const ['name']) ?? '',
      pop: pickString(olt, const ['pop']),
      ports: [for (final p in asList(m['ports'])) PonPortRow.fromJson(p)],
      onus: toNum(t['onus'])?.toInt() ?? 0,
      online: toNum(t['online'])?.toInt() ?? 0,
      offline: toNum(t['offline'])?.toInt() ?? 0,
      weakRx: toNum(t['weak_rx'])?.toInt() ?? 0,
    );
  }
}

class PonPortRow {
  const PonPortRow({
    required this.port,
    required this.label,
    this.onus = 0,
    this.online = 0,
    this.offline = 0,
    this.weakRx,
  });
  final String port;
  final String label;
  final int onus;
  final int online;
  final int offline;
  final int? weakRx;

  bool get dead => onus > 0 && online == 0 && offline > 0;

  factory PonPortRow.fromJson(Object? raw) {
    final m = asMap(raw);
    final port = pickString(m, const ['port']) ?? '';
    return PonPortRow(
      port: port,
      label: pickString(m, const ['label']) ?? port,
      onus: toNum(m['onus'])?.toInt() ?? 0,
      online: toNum(m['online'])?.toInt() ?? 0,
      offline: toNum(m['offline'])?.toInt() ?? 0,
      weakRx: toNum(m['weak_rx'])?.toInt(),
    );
  }
}

/// `GET /olts/{id}/onus` and `/olts/unmatched`: one page of ONUs.
class OnuPage {
  const OnuPage({
    this.onus = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.avgRx,
    this.label,
  });
  final List<OnuRow> onus;
  final int page;
  final int lastPage;
  final int total;
  final num? avgRx;
  final String? label;

  bool get hasMore => page < lastPage;

  factory OnuPage.fromJson(Object? raw) {
    final m = asMap(raw);
    return OnuPage(
      onus: [for (final o in asList(m['onus'])) OnuRow.fromJson(o)],
      page: toNum(m['page'])?.toInt() ?? 1,
      lastPage: toNum(m['last_page'])?.toInt() ?? 1,
      total: toNum(m['total'])?.toInt() ?? 0,
      avgRx: toNum(m['avg_rx']),
      label: pickString(m, const ['label']),
    );
  }
}

class OnuRow {
  const OnuRow({
    required this.id,
    this.serial,
    this.onu,
    this.description,
    this.status = 'unknown',
    this.statusLabel,
    this.signalLevel,
    this.rxDbm,
    this.distanceM,
    this.uptime,
    this.clientName,
    this.clientCode,
    this.olt,
  });
  final int id;
  final String? serial;
  final String? onu;
  final String? description;
  final String status;
  final String? statusLabel;
  final String? signalLevel;
  final num? rxDbm;
  final int? distanceM;
  final String? uptime;
  final String? clientName;
  final String? clientCode;
  final String? olt;

  factory OnuRow.fromJson(Object? raw) {
    final m = asMap(raw);
    final client = asMap(m['client']);
    return OnuRow(
      id: toNum(m['id'])?.toInt() ?? 0,
      serial: pickString(m, const ['serial']),
      onu: pickString(m, const ['onu', 'pon_port']),
      description: pickString(m, const ['description']),
      status: pickString(m, const ['status']) ?? 'unknown',
      statusLabel: pickString(m, const ['status_label']),
      signalLevel: pickString(m, const ['signal_level']),
      rxDbm: toNum(m['rx_dbm']),
      distanceM: toNum(m['distance_m'])?.toInt(),
      uptime: pickString(m, const ['uptime']),
      clientName: pickString(client, const ['name']),
      clientCode: pickString(client, const ['code']),
      olt: pickString(m, const ['olt']),
    );
  }
}
