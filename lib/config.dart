import 'package:flutter/foundation.dart';

/// Build-time configuration. Nothing here is a secret.
///
/// One app serves every ISP that runs the ERP: staff type their ERP address
/// on the login screen (kept on the phone). A build may still set a default:
///
///   flutter build apk --release --dart-define=ERP_BASE_URL=https://erp.example.com
class AppConfig {
  const AppConfig._();

  static const String _erpBaseUrl = String.fromEnvironment('ERP_BASE_URL');

  static const bool _debugApiDefine = bool.fromEnvironment('DEBUG_API');

  /// Shows API paths / HTTP codes on screen. Forced off in release builds.
  static bool get debugApi => !kReleaseMode && _debugApiDefine;

  /// The build's default ERP address, or null when the build has none.
  static String? get defaultServer => normalizeServer(_erpBaseUrl);

  /// The ERP this app is talking to right now (set by the server and auth
  /// controllers). Used to turn host-relative file links into full URLs.
  static String? activeServer;

  /// Staff API (mynet-erp `docs/STAFF_APP_API.md`) on [server].
  static String apiBase(String server) => '$server/api/staff/v1';

  /// Turns what staff type (`bill.example.com`, `https://bill.example.com/`)
  /// into `https://bill.example.com`. The ERP carries staff tokens and money,
  /// so plain http and anything that is not a host name are refused (null).
  static String? normalizeServer(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower.startsWith('http://')) return null;
    if (!lower.startsWith('https://')) {
      if (text.contains('://')) return null;
      text = 'https://$text';
    }
    final Uri uri;
    try {
      uri = Uri.parse(text);
    } catch (_) {
      return null;
    }
    final host = uri.host.toLowerCase();
    final validHost =
        host.contains('.') &&
        RegExp(r'^[a-z0-9.-]+$').hasMatch(host) &&
        !host.startsWith('.') &&
        !host.endsWith('.');
    if (!validHost || uri.userInfo.isNotEmpty || uri.hasQuery) return null;
    // Someone may paste the API address itself: keep only the ERP root.
    var path = uri.path.replaceFirst(RegExp(r'/api/staff/v1.*$'), '');
    path = path.replaceFirst(RegExp(r'/+$'), '');
    final port = uri.hasPort ? ':${uri.port}' : '';
    return 'https://$host$port$path';
  }

  /// `https://bill.example.com` → `bill.example.com`, for display.
  static String displayServer(String server) =>
      server.replaceFirst(RegExp(r'^https://'), '');
}
