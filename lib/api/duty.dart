import 'json.dart';

class DutySession {
  const DutySession({
    required this.id,
    required this.startedAt,
    required this.distanceM,
  });

  final int id;
  final String startedAt;
  final int distanceM;

  factory DutySession.fromJson(Object? raw) {
    final m = asMap(raw);
    return DutySession(
      id: toNum(m['id'])?.toInt() ?? 0,
      startedAt: pickString(m, const ['started_at']) ?? '',
      distanceM: toNum(m['distance_m'])?.toInt() ?? 0,
    );
  }
}

class DutyTracking {
  const DutyTracking({
    this.dutyStart = '08:00',
    this.dutyEnd = '22:00',
    this.timezone = 'Asia/Dhaka',
    this.intervalMovingS = 60,
    this.intervalStillS = 600,
    this.intervalOnTheWayS = 30,
    this.maxBatch = 200,
  });

  final String dutyStart;
  final String dutyEnd;
  final String timezone;
  final int intervalMovingS;
  final int intervalStillS;
  final int intervalOnTheWayS;
  final int maxBatch;

  factory DutyTracking.fromJson(Object? raw) {
    final m = asMap(raw);
    int n(String key, int fallback) => toNum(m[key])?.toInt() ?? fallback;
    return DutyTracking(
      dutyStart: pickString(m, const ['duty_start']) ?? '08:00',
      dutyEnd: pickString(m, const ['duty_end']) ?? '22:00',
      timezone: pickString(m, const ['timezone']) ?? 'Asia/Dhaka',
      intervalMovingS: n('interval_moving_s', 60),
      intervalStillS: n('interval_still_s', 600),
      intervalOnTheWayS: n('interval_on_the_way_s', 30),
      maxBatch: n('max_batch', 200),
    );
  }
}

class DutySnapshot {
  const DutySnapshot({
    required this.onDuty,
    this.session,
    this.withinDutyHours = true,
    this.tracking = const DutyTracking(),
  });

  final bool onDuty;
  final DutySession? session;
  final bool withinDutyHours;
  final DutyTracking tracking;

  factory DutySnapshot.fromJson(Object? raw) {
    final m = asMap(raw);
    final session = m['session'];
    return DutySnapshot(
      onDuty: m['on_duty'] == true,
      session: session is Map ? DutySession.fromJson(session) : null,
      withinDutyHours: m['within_duty_hours'] != false,
      tracking: DutyTracking.fromJson(m['tracking']),
    );
  }
}

class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.speed,
    this.heading,
    this.battery,
    this.isMock = false,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracy;
  final double? speed;
  final int? heading;
  final int? battery;
  final bool isMock;

  bool get moving => (speed ?? 0) >= 0.5;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'recorded_at': recordedAt.toIso8601String(),
    'accuracy': ?accuracy,
    'speed': ?speed,
    'heading': ?heading,
    'battery': ?battery,
    'is_mock': isMock,
  };
}

class LocationResult {
  const LocationResult({
    required this.onDuty,
    this.accepted = 0,
    this.duplicate = 0,
    this.dropped = 0,
    this.suspicious = 0,
  });

  final bool onDuty;
  final int accepted;
  final int duplicate;
  final int dropped;
  final int suspicious;

  factory LocationResult.fromJson(Object? raw) {
    final m = asMap(raw);
    int n(String key) => toNum(m[key])?.toInt() ?? 0;
    return LocationResult(
      onDuty: m['on_duty'] == true,
      accepted: n('accepted'),
      duplicate: n('duplicate'),
      dropped: n('dropped'),
      suspicious: n('suspicious'),
    );
  }
}
