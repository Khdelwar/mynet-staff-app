import 'json.dart';

/// STF-11 read-only field screens: stock, staff map, OLT and fiber. Shapes
/// follow mynet-erp `docs/STAFF_APP_API.md` ("Field screens"). The ERP
/// decides what a reseller may see; the app only shows the reply.

int? _int(Object? v) => toNum(v)?.toInt();
double? _double(Object? v) => toNum(v)?.toDouble();

// --- Stock ----------------------------------------------------------------

class HandItem {
  const HandItem({
    required this.id,
    this.category,
    this.model,
    this.serial,
    this.mac,
  });

  final int id;
  final String? category;
  final String? model;
  final String? serial;
  final String? mac;

  factory HandItem.fromJson(Object? raw) {
    final m = asMap(raw);
    return HandItem(
      id: _int(m['id']) ?? 0,
      category: pickString(m, const ['category']),
      model: pickString(m, const ['model']),
      serial: pickString(m, const ['serial']),
      mac: pickString(m, const ['mac']),
    );
  }
}

class StorePart {
  const StorePart({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    this.low = false,
  });

  final int id;
  final String name;
  final num quantity;
  final String? unit;
  final bool low;

  factory StorePart.fromJson(Object? raw) {
    final m = asMap(raw);
    return StorePart(
      id: _int(m['id']) ?? 0,
      name: pickString(m, const ['name']) ?? '',
      quantity: toNum(m['quantity']) ?? 0,
      unit: pickString(m, const ['unit']),
      low: m['low'] == true,
    );
  }
}

class StockCategory {
  const StockCategory(this.name, this.inStock);
  final String name;
  final int inStock;
}

class StockView {
  const StockView({
    this.inHand = const [],
    this.parts = const [],
    this.categories,
  });

  final List<HandItem> inHand;
  final List<StorePart> parts;

  /// Null when the ERP did not send it (no `inventory.view`).
  final List<StockCategory>? categories;

  factory StockView.fromJson(Object? raw) {
    final m = asMap(raw);
    final cats = m['categories'];
    return StockView(
      inHand: [for (final r in asList(m['in_hand'])) HandItem.fromJson(r)],
      parts: [for (final r in asList(m['parts'])) StorePart.fromJson(r)],
      categories: cats is List
          ? [
              for (final r in cats)
                StockCategory(
                  pickString(asMap(r), const ['name']) ?? '',
                  _int(asMap(r)['in_stock']) ?? 0,
                ),
            ]
          : null,
    );
  }
}

// --- Staff map ------------------------------------------------------------

class MapPerson {
  const MapPerson({
    required this.id,
    required this.name,
    required this.state,
    this.phone,
    this.lat,
    this.lng,
    this.seenMinutes,
    this.distanceM,
    this.ticketSubject,
    this.closedToday = 0,
  });

  final int id;
  final String name;

  /// `free`, `busy` or `stale` (no fresh location).
  final String state;
  final String? phone;
  final double? lat;
  final double? lng;
  final int? seenMinutes;
  final int? distanceM;
  final String? ticketSubject;
  final int closedToday;

  factory MapPerson.fromJson(Object? raw) {
    final m = asMap(raw);
    return MapPerson(
      id: _int(m['id']) ?? 0,
      name: pickString(m, const ['name']) ?? '',
      state: pickString(m, const ['state']) ?? 'stale',
      phone: pickString(m, const ['phone']),
      lat: _double(m['lat']),
      lng: _double(m['lng']),
      seenMinutes: _int(m['seen_minutes']),
      distanceM: _int(m['distance_m']),
      ticketSubject: pickString(asMap(m['ticket']), const ['subject']),
      closedToday: _int(m['closed_today']) ?? 0,
    );
  }
}

// --- OLT ------------------------------------------------------------------

class OltRow {
  const OltRow({
    required this.id,
    required this.name,
    required this.status,
    this.pop,
    this.vendor,
    this.lastPolledAt,
    this.onuTotal = 0,
    this.onuOnline = 0,
    this.onuOffline = 0,
    this.weak = 0,
    this.critical = 0,
  });

  final int id;
  final String name;

  /// `online`, `offline` or `unknown`.
  final String status;
  final String? pop;
  final String? vendor;
  final DateTime? lastPolledAt;
  final int onuTotal;
  final int onuOnline;
  final int onuOffline;
  final int weak;
  final int critical;

  factory OltRow.fromJson(Object? raw) {
    final m = asMap(raw);
    final onu = asMap(m['onu']);
    return OltRow(
      id: _int(m['id']) ?? 0,
      name: pickString(m, const ['name']) ?? '',
      status: pickString(m, const ['status']) ?? 'unknown',
      pop: pickString(m, const ['pop']),
      vendor: pickString(m, const ['vendor']),
      lastPolledAt: DateTime.tryParse(
        pickString(m, const ['last_polled_at']) ?? '',
      ),
      onuTotal: _int(onu['total']) ?? 0,
      onuOnline: _int(onu['online']) ?? 0,
      onuOffline: _int(onu['offline']) ?? 0,
      weak: _int(onu['weak']) ?? 0,
      critical: _int(onu['critical']) ?? 0,
    );
  }
}

class PonPortRow {
  const PonPortRow({
    required this.port,
    this.total = 0,
    this.online = 0,
    this.offline = 0,
  });

  final String port;
  final int total;
  final int online;
  final int offline;

  factory PonPortRow.fromJson(Object? raw) {
    final m = asMap(raw);
    return PonPortRow(
      port: pickString(m, const ['port']) ?? '',
      total: _int(m['onu_total']) ?? 0,
      online: _int(m['onu_online']) ?? 0,
      offline: _int(m['onu_offline']) ?? 0,
    );
  }
}

class OnuRow {
  const OnuRow({
    required this.id,
    required this.port,
    required this.status,
    this.onuIndex,
    this.serial,
    this.rxDbm,
    this.level,
    this.downReason,
    this.clientId,
    this.clientName,
    this.clientCode,
  });

  final int id;
  final String port;
  final String status;
  final String? onuIndex;
  final String? serial;
  final double? rxDbm;
  final String? level;
  final String? downReason;
  final int? clientId;
  final String? clientName;
  final String? clientCode;

  factory OnuRow.fromJson(Object? raw) {
    final m = asMap(raw);
    final client = asMap(m['client']);
    return OnuRow(
      id: _int(m['id']) ?? 0,
      port: pickString(m, const ['port']) ?? '',
      status: pickString(m, const ['status']) ?? 'unknown',
      onuIndex: m['onu_index']?.toString(),
      serial: pickString(m, const ['serial_mac']),
      rxDbm: _double(m['rx_dbm']),
      level: pickString(m, const ['level']),
      downReason: pickString(m, const ['last_down_reason']),
      clientId: _int(client['id']),
      clientName: pickString(client, const ['name']),
      clientCode: pickString(client, const ['code']),
    );
  }
}

class OltDetail {
  const OltDetail({
    required this.name,
    required this.status,
    this.ports = const [],
    this.onus = const [],
  });

  final String name;
  final String status;
  final List<PonPortRow> ports;
  final List<OnuRow> onus;

  factory OltDetail.fromJson(Object? raw) {
    final m = asMap(raw);
    final olt = asMap(m['olt']);
    return OltDetail(
      name: pickString(olt, const ['name']) ?? '',
      status: pickString(olt, const ['status']) ?? 'unknown',
      ports: [for (final r in asList(m['ports'])) PonPortRow.fromJson(r)],
      onus: [for (final r in asList(m['onus'])) OnuRow.fromJson(r)],
    );
  }
}

// --- Fiber ----------------------------------------------------------------

class FiberPlace {
  const FiberPlace({
    required this.type,
    required this.id,
    required this.lat,
    required this.lng,
    required this.distanceM,
    this.code,
    this.name,
    this.status,
    this.ratio,
    this.portsFree,
    this.portsTotal,
  });

  /// `joint_box`, `splitter`, `pole` or `cut`.
  final String type;
  final int id;
  final double lat;
  final double lng;
  final int distanceM;
  final String? code;
  final String? name;
  final String? status;
  final String? ratio;
  final int? portsFree;
  final int? portsTotal;

  factory FiberPlace.fromJson(Object? raw) {
    final m = asMap(raw);
    return FiberPlace(
      type: pickString(m, const ['type']) ?? '',
      id: _int(m['id']) ?? 0,
      lat: _double(m['lat']) ?? 0,
      lng: _double(m['lng']) ?? 0,
      distanceM: _int(m['distance_m']) ?? 0,
      code: pickString(m, const ['code']),
      name: pickString(m, const ['name']),
      status: pickString(m, const ['status']),
      ratio: pickString(m, const ['ratio']),
      portsFree: _int(m['ports_free']),
      portsTotal: _int(m['ports_total']),
    );
  }
}
