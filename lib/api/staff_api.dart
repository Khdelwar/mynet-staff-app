import 'package:dio/dio.dart';

import '../config.dart';
import 'json.dart';
import 'models.dart';

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

  /// Laravel validation errors (`422`), field → messages.
  final Map<String, List<String>> errors;

  /// The first message for [field], if the ERP refused that field.
  String? errorFor(String field) {
    final list = errors[field];
    return list == null || list.isEmpty ? null : list.first;
  }

  /// ERP's machine code (`failed`, `inactive`, `not_allowed`, `throttled`).
  final String? code;

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
        errors: {
          for (final e in asMap(record['errors']).entries)
            e.key: [
              for (final m in asList(e.value))
                if (m is String) m,
            ],
        },
      );
    }
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

  // --- Work screens (STF-03 … STF-09) ----------------------------------
  //
  // Each screen calls the paths in mynet-erp `docs/STAFF_APP_API.md` through
  // these; the reply is the ERP's JSON object, read with `json.dart`.

  Future<Json> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _send('GET', path, query: query) as Response<dynamic>;
    return asMap(res.data);
  }

  Future<Json> post(String path, [Object? body]) async {
    final res = await _send('POST', path, body: body) as Response<dynamic>;
    return asMap(res.data);
  }

  Future<Json> patch(String path, Object? body) async {
    final res = await _send('PATCH', path, body: body) as Response<dynamic>;
    return asMap(res.data);
  }

  /// Multipart POST: [fields] plus files as `field → local paths`
  /// (a list field is sent as `name[]`).
  Future<Json> postFiles(
    String path,
    Map<String, Object?> fields, {
    Map<String, List<String>> files = const {},
  }) async {
    final form = FormData();
    for (final f in fields.entries) {
      if (f.value != null) form.fields.add(MapEntry(f.key, '${f.value}'));
    }
    for (final f in files.entries) {
      for (final file in f.value) {
        form.files.add(MapEntry(f.key, await MultipartFile.fromFile(file)));
      }
    }
    final res = await _send('POST', path, body: form) as Response<dynamic>;
    return asMap(res.data);
  }

  /// Headers for an image the ERP serves only with the Bearer token
  /// (note photos, receipt photos).
  Map<String, String> get imageHeaders => {
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
