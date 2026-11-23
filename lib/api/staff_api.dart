import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config.dart';
import 'chats.dart';
import 'duty.dart';
import 'json.dart';
import 'models.dart';
import 'offers.dart';
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

  /// Laravel validation messages, keyed by field (`note`, `away_reason`, `duty`, `offer`, …).
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
    String email,
    String password, {
    required String deviceId,
    String? deviceName,
    String? appVersion,
  }) async {
    final res = await _send(
      'POST',
      '/auth/login',
      auth: false,
      body: {
        'identifier': email.trim(),
        'password': password,
        'device_id': deviceId,
        'device_name': ?deviceName,
        'app_version': ?appVersion,
      },
    );
    return _outcome(res as Response<dynamic>, '/auth/login');
  }

  Future<LoginOutcome> verifyTwoFactor(
    String challengeToken,
    String code,
  ) async {
    final res = await _send(
      'POST',
      '/auth/two-factor',
      auth: false,
      body: {'challenge_token': challengeToken, 'code': code.trim()},
    );
    return _outcome(res as Response<dynamic>, '/auth/two-factor');
  }

  LoginOutcome _outcome(Response<dynamic> res, String path) {
    final root = asMap(res.data);
    if (res.statusCode == 202 || root['code'] == 'two_factor_required') {
      final challenge = pickString(root, const [
        'challenge_token',
        'challenge',
      ]);
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

  // --- Duty (STF-04) ----------------------------------------------------

  Future<DutySnapshot> duty() async {
    final res = await _send('GET', '/duty') as Response<dynamic>;
    return DutySnapshot.fromJson(res.data);
  }

  Future<DutySnapshot> startDuty({double? latitude, double? longitude}) async {
    final res = await _send(
      'POST',
      '/duty/start',
      body: {'latitude': ?latitude, 'longitude': ?longitude},
    ) as Response<dynamic>;
    return DutySnapshot.fromJson(res.data);
  }

  Future<DutySnapshot> endDuty() async {
    final res = await _send('POST', '/duty/end') as Response<dynamic>;
    return DutySnapshot.fromJson(res.data);
  }

  Future<LocationResult> sendLocations(List<LocationPoint> points) async {
    final res = await _send(
      'POST',
      '/locations',
      body: {
        'points': [for (final point in points) point.toJson()],
      },
    ) as Response<dynamic>;
    return LocationResult.fromJson(res.data);
  }

  /// True when one of this person's open tickets is `on_the_way`.
  /// A 403 means they cannot see tickets; location then uses the moving
  /// or still interval only.
  Future<bool> anyTicketOnTheWay() async {
    try {
      final res = await _send(
        'GET',
        '/tickets',
        query: {'scope': 'mine', 'status': 'active', 'per_page': 30},
      ) as Response<dynamic>;
      return asList(asMap(res.data)['tickets'])
          .any((row) => asMap(row)['status'] == 'on_the_way');
    } on ApiException catch (e) {
      if (e.status == 403) return false;
      rethrow;
    }
  }

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

  Future<({List<ChatThread> threads, int unread})> chats({String? q}) async {
    final query = q?.trim() ?? '';
    final res = await _send(
      'GET',
      '/chats',
      query: {if (query.isNotEmpty) 'q': query},
    ) as Response<dynamic>;
    final root = asMap(res.data);
    return (
      threads: [
        for (final row in listFrom(root, const ['conversations']))
          ChatThread.fromJson(row),
      ],
      unread: toNum(root['unread_conversations'])?.toInt() ?? 0,
    );
  }

  Future<({String? clientName, List<ChatMessage> messages})> chat(
    int id,
  ) async {
    final res = await _send('GET', '/chats/$id') as Response<dynamic>;
    final root = asMap(res.data);
    final conversation = asMap(root['conversation']);
    return (
      clientName: pickString(asMap(conversation['client']), const ['name']),
      messages: [
        for (final row in listFrom(root, const ['messages']))
          ChatMessage.fromJson(row),
      ],
    );
  }

  Future<ChatMessage> sendChat(int id, String body) async {
    final res = await _send(
      'POST',
      '/chats/$id/messages',
      body: {'body': body.trim()},
    ) as Response<dynamic>;
    return ChatMessage.fromJson(asMap(res.data)['message']);
  }

  /// Loads a note photo when the public URL refuses an unauthenticated GET.
  /// A 401 here is the file, not the session, so it does not sign the staff out.
  Future<Uint8List> authorizedBytes(String url) async {
    final sent = token;
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*',
            if (sent != null) 'Authorization': 'Bearer $sent',
          },
        ),
      );
      final data = res.data;
      if (data == null || data.isEmpty) {
        throw ApiException(res.statusCode ?? 0, '', path: url);
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      throw ApiException(e.response?.statusCode ?? 0, '', path: url);
    }
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
