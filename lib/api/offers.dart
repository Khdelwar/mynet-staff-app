import 'json.dart';

class OfferTicket {
  const OfferTicket({
    required this.id,
    required this.subject,
    this.priority,
    this.status,
    this.clientName,
  });

  final int id;
  final String subject;
  final String? priority;
  final String? status;
  final String? clientName;

  factory OfferTicket.fromJson(Object? raw) {
    final m = asMap(raw);
    final client = asMap(m['client']);
    return OfferTicket(
      id: toNum(m['id'])?.toInt() ?? 0,
      subject: pickString(m, const ['subject']) ?? '',
      priority: pickString(m, const ['priority']),
      status: pickString(m, const ['status']),
      clientName: pickString(client, const ['name']),
    );
  }
}

class JobOffer {
  const JobOffer({
    required this.id,
    this.distanceM,
    this.expiresAt,
    this.secondsLeft = 0,
    this.ticket,
  });

  final int id;
  final int? distanceM;
  final String? expiresAt;
  final int secondsLeft;
  final OfferTicket? ticket;

  factory JobOffer.fromJson(Object? raw) {
    final m = asMap(raw);
    final ticket = m['ticket'];
    return JobOffer(
      id: toNum(m['id'])?.toInt() ?? 0,
      distanceM: toNum(m['distance_m'])?.toInt(),
      expiresAt: pickString(m, const ['expires_at']),
      secondsLeft: toNum(m['seconds_left'])?.toInt() ?? 0,
      ticket: ticket is Map ? OfferTicket.fromJson(ticket) : null,
    );
  }
}

class SuggestionReasons {
  const SuggestionReasons({
    this.distance = 0,
    this.workload = 0,
    this.area = 0,
    this.freshness = 0,
    this.experience = 0,
  });

  final double distance;
  final double workload;
  final double area;
  final double freshness;
  final double experience;

  factory SuggestionReasons.fromJson(Object? raw) {
    final m = asMap(raw);
    double n(String key) => toNum(m[key])?.toDouble() ?? 0;
    return SuggestionReasons(
      distance: n('distance'),
      workload: n('workload'),
      area: n('area'),
      freshness: n('freshness'),
      experience: n('experience'),
    );
  }
}

class TechnicianSuggestion {
  const TechnicianSuggestion({
    required this.userId,
    required this.name,
    this.phone,
    this.score = 0,
    this.distanceM,
    this.etaMin,
    this.openTickets = 0,
    this.busy = false,
    this.sameArea = false,
    this.seenMinutes,
    this.reasons = const SuggestionReasons(),
  });

  final int userId;
  final String name;
  final String? phone;
  final double score;
  final int? distanceM;
  final int? etaMin;
  final int openTickets;
  final bool busy;
  final bool sameArea;
  final int? seenMinutes;
  final SuggestionReasons reasons;

  factory TechnicianSuggestion.fromJson(Object? raw) {
    final m = asMap(raw);
    final user = asMap(m['user']);
    return TechnicianSuggestion(
      userId: toNum(user['id'])?.toInt() ?? 0,
      name: pickString(user, const ['name']) ?? '',
      phone: pickString(user, const ['phone']),
      score: toNum(m['score'])?.toDouble() ?? 0,
      distanceM: toNum(m['distance_m'])?.toInt(),
      etaMin: toNum(m['eta_min'])?.toInt(),
      openTickets: toNum(m['open_tickets'])?.toInt() ?? 0,
      busy: m['busy'] == true,
      sameArea: m['same_area'] == true,
      seenMinutes: toNum(m['seen_minutes'])?.toInt(),
      reasons: SuggestionReasons.fromJson(m['reasons']),
    );
  }
}

class OfferResult {
  const OfferResult({required this.ok, this.offeredTo, this.distanceM});

  final bool ok;
  final String? offeredTo;
  final int? distanceM;

  factory OfferResult.fromJson(Object? raw) {
    final m = asMap(raw);
    final person = asMap(m['offered_to']);
    return OfferResult(
      ok: m['ok'] == true,
      offeredTo: pickString(person, const ['name']),
      distanceM: toNum(person['distance_m'])?.toInt(),
    );
  }
}
