import '../config.dart';
import 'json.dart';

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyM;
  final String? capturedAt;

  static GeoPoint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = asMap(raw);
    final lat = toNum(m['latitude']);
    final lng = toNum(m['longitude']);
    if (lat == null || lng == null) return null;
    return GeoPoint(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      accuracyM: toNum(m['accuracy_m'] ?? m['accuracy'])?.toDouble(),
      capturedAt: pickString(m, const ['captured_at']),
    );
  }
}

class OnuReading {
  const OnuReading({this.sn, this.mac, this.ponPort, this.lastRxDbm});

  final String? sn;
  final String? mac;
  final String? ponPort;
  final double? lastRxDbm;

  factory OnuReading.fromJson(Object? raw) {
    final m = asMap(raw);
    return OnuReading(
      sn: pickString(m, const ['sn']),
      mac: pickString(m, const ['mac']),
      ponPort: pickString(m, const ['pon_port']),
      lastRxDbm: toNum(m['last_rx_dbm'])?.toDouble(),
    );
  }
}

class TicketClient {
  const TicketClient({
    required this.id,
    this.code,
    this.name,
    this.phone,
    this.address,
    this.pppoeUsername,
    this.status,
    this.location,
    this.onu,
  });

  final int id;
  final String? code;
  final String? name;
  final String? phone;
  final String? address;
  final String? pppoeUsername;
  final String? status;
  final GeoPoint? location;
  final OnuReading? onu;

  factory TicketClient.fromJson(Object? raw) {
    final m = asMap(raw);
    final onu = m['onu'];
    return TicketClient(
      id: toNum(m['id'])?.toInt() ?? 0,
      code: pickString(m, const ['code']),
      name: pickString(m, const ['name']),
      phone: pickString(m, const ['phone']),
      address: pickString(m, const ['address']),
      pppoeUsername: pickString(m, const ['pppoe_username']),
      status: pickString(m, const ['status']),
      location: GeoPoint.fromJson(m['location']),
      onu: onu is Map ? OnuReading.fromJson(onu) : null,
    );
  }
}

class TicketPerson {
  const TicketPerson({required this.id, required this.name, this.phone});

  final int id;
  final String name;
  final String? phone;

  factory TicketPerson.fromJson(Object? raw) {
    final m = asMap(raw);
    return TicketPerson(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['name']) ?? '',
      phone: pickString(m, const ['phone']),
    );
  }
}

class TicketPhoto {
  const TicketPhoto({
    this.url,
    this.downloadUrl,
    this.name,
    this.isImage = false,
  });

  final String? url;
  final String? downloadUrl;
  final String? name;
  final bool isImage;

  /// Public disk URL. Often host-relative (`/storage/...`).
  String? get absoluteUrl => _absolute(url);

  /// Always present for a private file: `GET /attachments/{id}` with Bearer.
  String? get absoluteDownloadUrl => _absolute(downloadUrl);

  /// Private files use [downloadUrl]. A public `url` is the fallback.
  String? get displayUrl => absoluteDownloadUrl ?? absoluteUrl;

  bool get authenticated => absoluteDownloadUrl != null;

  static String? _absolute(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final server = AppConfig.activeServer;
    if (server == null) return value;
    final path = value.startsWith('/') ? value : '/$value';
    return '$server$path';
  }

  factory TicketPhoto.fromJson(Object? raw) {
    final m = asMap(raw);
    return TicketPhoto(
      url: pickString(m, const ['url']),
      downloadUrl: pickString(m, const ['download_url']),
      name: pickString(m, const ['name']),
      isImage: m['is_image'] == true,
    );
  }
}

class TicketComment {
  const TicketComment({
    required this.id,
    required this.body,
    this.clientRef,
    this.author,
    this.createdAt,
    this.photos = const [],
  });

  final int id;
  final String body;
  final String? clientRef;
  final String? author;
  final String? createdAt;
  final List<TicketPhoto> photos;

  factory TicketComment.fromJson(Object? raw) {
    final m = asMap(raw);
    final user = asMap(m['user']);
    return TicketComment(
      id: toNum(m['id'])?.toInt() ?? 0,
      body: pickString(m, const ['body']) ?? '',
      clientRef: pickString(m, const ['client_ref']),
      author: pickString(user, const ['name']),
      createdAt: pickString(m, const ['created_at']),
      photos: [
        for (final photo in asList(m['photos'])) TicketPhoto.fromJson(photo),
      ],
    );
  }
}

class TicketCan {
  const TicketCan({
    this.updateStatus = false,
    this.close = false,
    this.comment = false,
    this.setLocation = false,
    this.checkDbm = false,
    this.useMaterials = false,
    this.scanItems = false,
    this.install = false,
  });

  final bool updateStatus;
  final bool useMaterials;
  final bool scanItems;

  /// A new connection's install form (assigned technician, client pending).
  final bool install;
  final bool close;
  final bool comment;
  final bool setLocation;
  final bool checkDbm;

  factory TicketCan.fromJson(Object? raw) {
    final m = asMap(raw);
    return TicketCan(
      updateStatus: m['update_status'] == true,
      close: m['close'] == true,
      comment: m['comment'] == true,
      setLocation: m['set_location'] == true,
      checkDbm: m['check_dbm'] == true,
      useMaterials: m['use_materials'] == true,
      scanItems: m['scan_items'] == true,
      install: m['install'] == true,
    );
  }
}

class TicketSummary {
  const TicketSummary({
    required this.id,
    required this.subject,
    this.type,
    this.category,
    this.priority,
    this.status,
    this.role,
    this.overdue = false,
    this.slaDueAt,
    this.visitScheduledAt,
    this.assignee,
    this.client,
  });

  final int id;
  final String subject;
  final String? type;
  final String? category;
  final String? priority;
  final String? status;
  final String? role;
  final bool overdue;
  final String? slaDueAt;
  final String? visitScheduledAt;
  final TicketPerson? assignee;
  final TicketClient? client;

  factory TicketSummary.fromJson(Object? raw) {
    final m = asMap(raw);
    final assignee = m['assignee'];
    final client = m['client'];
    return TicketSummary(
      id: toNum(m['id'])?.toInt() ?? 0,
      subject: pickString(m, const ['subject']) ?? '',
      type: pickString(m, const ['type']),
      category: pickString(m, const ['category']),
      priority: pickString(m, const ['priority']),
      status: pickString(m, const ['status']),
      role: pickString(m, const ['role']),
      overdue: m['overdue'] == true,
      slaDueAt: pickString(m, const ['sla_due_at']),
      visitScheduledAt: pickString(m, const ['visit_scheduled_at']),
      assignee: assignee is Map ? TicketPerson.fromJson(assignee) : null,
      client: client is Map ? TicketClient.fromJson(client) : null,
    );
  }
}

class TicketDetail extends TicketSummary {
  const TicketDetail({
    required super.id,
    required super.subject,
    super.type,
    super.category,
    super.priority,
    super.status,
    super.role,
    super.overdue,
    super.slaDueAt,
    super.visitScheduledAt,
    super.assignee,
    super.client,
    this.description,
    this.helpers = const [],
    this.comments = const [],
    this.can = const TicketCan(),
    this.nextStatuses = const [],
    this.noteRequiredFor = const [],
    this.outcomes = const [],
    this.finishRadiusM,
    this.finishDistanceM,
    this.finishAwayReason,
  });

  final String? description;
  final List<TicketPerson> helpers;
  final List<TicketComment> comments;
  final TicketCan can;
  final List<String> nextStatuses;
  final List<String> noteRequiredFor;
  final List<String> outcomes;
  final int? finishRadiusM;
  final int? finishDistanceM;
  final String? finishAwayReason;

  bool needsNote(String status) => noteRequiredFor.contains(status);

  factory TicketDetail.fromJson(Object? raw) {
    final root = asMap(raw);
    final m = root['ticket'] is Map ? asMap(root['ticket']) : root;
    final summary = TicketSummary.fromJson(m);
    return TicketDetail(
      id: summary.id,
      subject: summary.subject,
      type: summary.type,
      category: summary.category,
      priority: summary.priority,
      status: summary.status,
      role: summary.role,
      overdue: summary.overdue,
      slaDueAt: summary.slaDueAt,
      visitScheduledAt: summary.visitScheduledAt,
      assignee: summary.assignee,
      client: summary.client,
      description: pickString(m, const ['description']),
      helpers: [
        for (final helper in asList(m['helpers']))
          TicketPerson.fromJson(helper),
      ],
      comments: [
        for (final comment in asList(m['comments']))
          TicketComment.fromJson(comment),
      ],
      can: TicketCan.fromJson(m['can']),
      nextStatuses: [
        for (final status in asList(m['next_statuses']))
          if (status is String && status.isNotEmpty) status,
      ],
      noteRequiredFor: [
        for (final status in asList(m['note_required_for']))
          if (status is String && status.isNotEmpty) status,
      ],
      outcomes: [
        for (final outcome in asList(m['outcomes']))
          if (outcome is String && outcome.isNotEmpty) outcome,
      ],
      finishRadiusM: toNum(m['finish_radius_m'])?.toInt(),
      finishDistanceM: toNum(m['finish_distance_m'])?.toInt(),
      finishAwayReason: pickString(m, const ['finish_away_reason']),
    );
  }
}

class TicketPage {
  const TicketPage({
    required this.scope,
    required this.status,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.tickets,
  });

  final String scope;
  final String status;
  final int page;
  final int lastPage;
  final int total;
  final List<TicketSummary> tickets;

  factory TicketPage.fromJson(Object? raw) {
    final m = asMap(raw);
    return TicketPage(
      scope: pickString(m, const ['scope']) ?? 'mine',
      status: pickString(m, const ['status']) ?? 'active',
      page: toNum(m['page'])?.toInt() ?? 1,
      lastPage: toNum(m['last_page'])?.toInt() ?? 1,
      total: toNum(m['total'])?.toInt() ?? 0,
      tickets: [
        for (final ticket in asList(m['tickets']))
          TicketSummary.fromJson(ticket),
      ],
    );
  }
}

class DbmReading {
  const DbmReading({
    required this.ok,
    this.rxDbm,
    this.txDbm,
    this.level,
    this.message,
  });

  final bool ok;
  final double? rxDbm;
  final double? txDbm;
  final String? level;
  final String? message;

  factory DbmReading.fromJson(Object? raw) {
    final m = asMap(raw);
    return DbmReading(
      ok: m['ok'] == true,
      rxDbm: toNum(m['rx_dbm'])?.toDouble(),
      txDbm: toNum(m['tx_dbm'])?.toDouble(),
      level: pickString(m, const ['level']),
      message: pickString(m, const ['message']),
    );
  }
}
