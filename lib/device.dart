import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'state/stores.dart';

/// Install id for this phone. The ERP uses it so signing in again on the
/// same phone replaces that phone's token. Kept in secure storage and not
/// removed on sign-out.
const deviceIdKey = 'staff_device_id';

/// Matches `pubspec.yaml` `version` (the `+build` is not sent).
const staffAppVersion = '0.1.0';

Future<String> ensureDeviceId(SecretStore store) async {
  final existing = await store.read(deviceIdKey);
  if (existing != null && existing.isNotEmpty) return existing;
  final created = _newDeviceId();
  await store.write(deviceIdKey, created);
  return created;
}

/// Phone model (`Redmi 12`, …). The ERP stores this as `device_name`.
Future<String> deviceName() async {
  if (kIsWeb) return 'web';
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final model = (await info.androidInfo).model.trim();
      if (model.isNotEmpty) return model;
    } else if (Platform.isIOS) {
      final machine = (await info.iosInfo).utsname.machine.trim();
      if (machine.isNotEmpty) return machine;
    }
  } catch (_) {
    // Tests and a missing plugin still send a label, never a secret.
  }
  return Platform.operatingSystem;
}

/// UUID v4. One per install.
String _newDeviceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
