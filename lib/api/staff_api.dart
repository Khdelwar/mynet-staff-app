import 'package:dio/dio.dart';

import '../config.dart';
import 'json.dart';
import 'models.dart';
import 'offers.dart';

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

  // --- Nearest technician (STF-05) --------------------------------------

  Future<List<JobOffer>> offers() async {
    final res = await _send('GET', '/offers') as Response<dynamic>;
    return [
      for (final row in asList(asMap(res.data)['offers']))
        JobOffer.fromJson(row),
    ];
  }

  Future<OfferTicket> acceptOffer(int id) async {
    final res = await _send('POST', '/offers/$id/accept') as Response<dynamic>;
    return OfferTicket.fromJson(asMap(res.data)['ticket']);
  }

  Future<void> rejectOffer(int id) async {
    await _send('POST', '/offers/$id/reject');
  }

  Future<List<TechnicianSuggestion>> suggestions(int ticketId) async {
    final res = await _send(
      'GET',
      '/tickets/$ticketId/suggestions',
    ) as Response<dynamic>;
    return [
      for (final row in asList(asMap(res.data)['suggestions']))
        TechnicianSuggestion.fromJson(row),
    ];
  }

  Future<void> assignTicket(int ticketId, int userId) async {
    await _send('POST', '/tickets/$ticketId/assign', body: {'user_id': userId});
  }

  Future<OfferResult> offerTicket(int ticketId) async {
    final res =
        await _send('POST', '/tickets/$ticketId/offer') as Response<dynamic>;
    return OfferResult.fromJson(res.data);
  }

  /// Active tickets for someone who may assign. Technicians are limited to
  /// their own by the ERP; the office asks for `scope=all`.
  Future<List<OfferTicket>> assignableTickets() async {
    final res = await _send(
      'GET',
      '/tickets',
      query: {'scope': 'all', 'status': 'active', 'per_page': 30},
    ) as Response<dynamic>;
    return [
      for (final row in asList(asMap(res.data)['tickets']))
        OfferTicket.fromJson(row),
    ];
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
