import 'package:flutter/foundation.dart';

/// Build-time configuration. Nothing here is a secret; values come from
/// `--dart-define` so no ERP host is hardcoded in source.
///
///   flutter build apk --release --dart-define=ERP_BASE_URL=https://erp.example.com
class AppConfig {
  const AppConfig._();

  static const String _erpBaseUrl = String.fromEnvironment('ERP_BASE_URL');

  static const bool _debugApiDefine = bool.fromEnvironment('DEBUG_API');

  /// Shows API paths / HTTP codes on screen. Forced off in release builds.
  static bool get debugApi => !kReleaseMode && _debugApiDefine;

  static String get erpBaseUrl => _erpBaseUrl.replaceFirst(RegExp(r'/+$'), '');

  /// The ERP carries staff tokens and money, so only https is accepted.
  static bool get isConfigured => erpBaseUrl.startsWith('https://');

  /// Staff API (mynet-erp `docs/STAFF_APP_API.md`).
  static String get apiBaseUrl => '$erpBaseUrl/api/staff/v1';
}
