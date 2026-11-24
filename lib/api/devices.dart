import 'json.dart';

/// One signed-in phone from `GET /devices`.
class StaffDevice {
  const StaffDevice({
    required this.id,
    this.name,
    this.appVersion,
    this.lastUsedAt,
    this.thisDevice = false,
  });

  final int id;
  final String? name;
  final String? appVersion;
  final String? lastUsedAt;
  final bool thisDevice;

  factory StaffDevice.fromJson(Object? raw) {
    final m = asMap(raw);
    return StaffDevice(
      id: toNum(m['id'])?.toInt() ?? 0,
      name: pickString(m, const ['device_name', 'name']),
      appVersion: pickString(m, const ['app_version']),
      lastUsedAt: pickString(m, const ['last_used_at']),
      thisDevice: m['this_device'] == true,
    );
  }
}
