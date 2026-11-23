import 'dart:io';
import 'dart:math';

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

String deviceName() {
  if (kIsWeb) return 'web';
  return Platform.operatingSystem;
}

String _newDeviceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  return bytes.map(hex).join();
}
