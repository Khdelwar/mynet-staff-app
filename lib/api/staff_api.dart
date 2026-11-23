import 'package:dio/dio.dart';

import '../config.dart';
import 'json.dart';
import 'models.dart';
import 'tickets.dart';

/// A failed ERP call. [status] is 0 when the server was not reached.
class ApiException implements Exception {
  const ApiException(
    this.status,
    this.message, {
    this.path = '',
    this.code,
    this.errors = const {},
  });
  final int status;
  final String message;
  final String path;

  /// ERP's machine code (`failed`, `inactive`, `not_allowed`, `throttled`).
  final String? code;

  /// Laravel validation messages, keyed by field (`note`, `away_reason`, …).
  final Map<String, List<String>> errors;

  String? field(String name) {
    final messages = errors[name];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status $path)';
}

/// The single client for the MyNet ERP staff API (`/api/staff/v1`).
/// Paths follow mynet-erp `docs/STAFF_APP_API.md`; do not invent endpoints.
///
/// Tokens, codes and passwords are never logged; this class has no logging.
class StaffApi {
  StaffApi({Dio? dio, this.onUnauthorized})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              // Field staff are often on weak mobile data: fail visibly.
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  /// Called when ERP rejects the session token (HTTP 401) on a signed-in call.
  final void Function(String rejectedToken, String? code)? onUnauthorized;

  /// Session token; set by the auth controller.
  String? token;

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final sent = auth ? token : null;
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {if (sent != null) 'Authorization': 'Bearer $sent'},
        ),
      );
      return res;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final record = asMap(e.response?.data);
      final code = pickString(record, const ['code']);
      if (status == 401 && sent != null) onUnauthorized?.call(sent, code);
      throw ApiException(
        status,
        pickString(record, const ['message', 'error']) ?? '',
        path: path,
        code: code,
        errors: _fieldErrors(record['errors']),
      );
    }
  }

  Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, List<String>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List) {
        final messages = [
          for (final item in value)
            if (item != null && item.toString().trim().isNotEmpty)
              item.toString().trim(),
        ];
        if (messages.isNotEmpty) out[entry.key.toString()] = messages;
      } else if (value != null && value.toString().trim().isNotEmpty) {
        out[entry.key.toString()] = [value.toString().trim()];
      }
    }
    return out;
  }

  // --- Auth -------------------------------------------------------------

  Future<LoginOutcome> login(
    String identifier,
    String password, {
    String? device,
  }) async {
    final res = await _send(
      'POST',
      '/auth/login',
      auth: false,
      body: {
        'identifier': identifier.trim(),
        'password': password,
        'device': ?device,
      },
    );
    return _outcome(res as Response<dynamic>, '/auth/login');
  }

  Future<LoginOutcome> verifyTwoFactor(String challenge, String code) async {
    final res = await _send(
      'POST',
      '/auth/two-factor',
      auth: false,
      body: {'challenge': challenge, 'code': code.trim()},
    );
    return _outcome(res as Response<dynamic>, '/auth/two-factor');
  }

  LoginOutcome _outcome(Response<dynamic> res, String path) {
    final root = asMap(res.data);
    if (res.statusCode == 202 || root['code'] == 'two_factor_required') {
      final challenge = pickString(root, const ['challenge']);
      if (challenge == null) throw ApiException(200, '', path: path);
      return TwoFactorNeeded(
        challenge: challenge,
        channel: pickString(root, const ['channel']) ?? 'sms',
        message: pickString(root, const ['message']),
      );
    }
    final token = pickString(root, const ['token', 'access_token']);
    if (token == null) throw ApiException(200, '', path: path);
    return SignedIn(token, StaffUser.fromJson(root));
  }

  Future<StaffUser> me() async {
    final res = await _send('GET', '/me') as Response<dynamic>;
    return StaffUser.fromJson(res.data);
  }

  Future<void> logout() async => _send('POST', '/auth/logout');

  // --- Push (STF-02) ----------------------------------------------------

  /// Stores this phone's FCM token on the signed-in session.
  Future<void> registerPush(String token) async {
    await _send('POST', '/push/register', body: {'token': token});
  }

  /// Stops pushes to this phone. The user stays signed in.
  Future<void> unregisterPush() async {
    await _send('POST', '/push/unregister');
  }

  // --- Tickets (STF-03) -------------------------------------------------

  Future<TicketPage> tickets({
    String scope = 'mine',
    String status = 'active',
    String? q,
    int page = 1,
  }) async {
    final res = await _send(
      'GET',
      '/tickets',
      query: {
        'scope': scope,
        'status': status,
        'page': page,
        'per_page': 30,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    ) as Response<dynamic>;
    return TicketPage.fromJson(res.data);
  }

  Future<TicketDetail> ticket(int id) async {
    final res = await _send('GET', '/tickets/$id') as Response<dynamic>;
    return TicketDetail.fromJson(res.data);
  }

  Future<TicketDetail> setTicketStatus(
    int id, {
    required String status,
    String? note,
    String? outcome,
    double? latitude,
    double? longitude,
    String? awayReason,
  }) async {
    final res = await _send(
      'POST',
      '/tickets/$id/status',
      body: {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (outcome != null && outcome.isNotEmpty) 'outcome': outcome,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
        if (awayReason != null && awayReason.trim().isNotEmpty)
          'away_reason': awayReason.trim(),
      },
    ) as Response<dynamic>;
    return TicketDetail.fromJson(res.data);
  }

  /// [clientRef] is made on the phone. Sending the same note again returns
  /// the saved comment instead of a second copy.
  Future<TicketComment> addTicketComment(
    int id, {
    required String body,
    required String clientRef,
    List<String> photoPaths = const [],
  }) async {
    final form = FormData.fromMap({
      'body': body,
      'client_ref': clientRef,
      if (photoPaths.isNotEmpty)
        'photos': [
          for (final path in photoPaths)
            await MultipartFile.fromFile(path, filename: _fileName(path)),
        ],
    });
    final res = await _send(
      'POST',
      '/tickets/$id/comments',
      body: form,
    ) as Response<dynamic>;
    return TicketComment.fromJson(asMap(res.data)['comment']);
  }

  Future<GeoPoint> setClientLocation(
    int id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final res = await _send(
      'POST',
      '/clients/$id/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': ?accuracy,
      },
    ) as Response<dynamic>;
    final point = GeoPoint.fromJson(asMap(res.data)['location']);
    if (point == null) {
      throw ApiException(200, '', path: '/clients/$id/location');
    }
    return point;
  }

  Future<DbmReading> checkDbm(int id) async {
    final res = await _send('POST', '/clients/$id/dbm') as Response<dynamic>;
    return DbmReading.fromJson(res.data);
  }
}

String _fileName(String path) {
  final parts = path.split(RegExp(r'[/\\]'));
  final name = parts.isEmpty ? '' : parts.last;
  return name.isEmpty ? 'photo.jpg' : name;
}
