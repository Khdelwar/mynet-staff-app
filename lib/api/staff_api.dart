import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config.dart';
import 'chats.dart';
import 'clients.dart';
import 'collection.dart';
import 'devices.dart';
import 'duty.dart';
import 'json.dart';
import 'models.dart';
import 'offers.dart';
import 'olt.dart';
import 'tickets.dart';
import 'work.dart';

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
  StaffApi({Dio? dio, String? server, this.onUnauthorized})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: server == null ? '' : AppConfig.apiBase(server),
              // Field staff are often on weak mobile data: fail visibly.
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  /// The ERP this client talks to (`https://host`), from the login screen.
  set server(String server) => _dio.options.baseUrl = AppConfig.apiBase(server);

  /// Called when ERP rejects the session token (HTTP 401) on a signed-in call.
  final Future<void> Function(
    String rejectedToken,
    String? code,
    String? message,
  )?
  onUnauthorized;

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
      final message = pickString(record, const ['message', 'error']);
      if (status == 401 && sent != null) {
        await onUnauthorized?.call(sent, code, message);
      }
      throw ApiException(
        status,
        message ?? '',
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
      body: {
        'challenge_token': challengeToken,
        'challenge': challengeToken,
        'code': code.trim(),
      },
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

  Future<List<StaffDevice>> devices() async {
    final res = await _send('GET', '/devices') as Response<dynamic>;
    return [
      for (final row in listFrom(res.data, const ['devices']))
        StaffDevice.fromJson(row),
    ];
  }

  /// Signs one of this user's phones out. Does not clear the local session.
  Future<void> revokeDevice(int id) async {
    await _send('DELETE', '/devices/$id');
  }

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

  /// The web client list: [filters] are the web list's own (directory,
  /// status, pop_id, zone_id, router_id, package_id, reseller_id,
  /// billing_policy, client_type, sort, sort_dir).
  Future<ClientPage> clients({
    String? q,
    String? status,
    Map<String, String> filters = const {},
    int page = 1,
  }) async {
    final query = q?.trim() ?? '';
    final res = await _send(
      'GET',
      '/clients',
      query: {
        if (query.length >= 2) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
        for (final e in filters.entries)
          if (e.value.isNotEmpty) e.key: e.value,
        'page': page,
      },
    ) as Response<dynamic>;
    return ClientPage.fromJson(res.data);
  }

  /// Suggestions while typing, as the web header search.
  Future<ClientSuggestions> clientSuggest(String q) async {
    final res = await _send(
      'GET',
      '/clients/suggest',
      query: {'q': q.trim()},
    ) as Response<dynamic>;
    return ClientSuggestions.fromJson(res.data);
  }

  /// The web list's filter choices, with the ERP's labels in [lang].
  Future<ClientFilterOptions> clientFilters({required String lang}) async {
    final res = await _send(
      'GET',
      '/clients/filters',
      query: {'lang': lang},
    ) as Response<dynamic>;
    return ClientFilterOptions.fromJson(res.data);
  }

  Future<ClientDetail> client(int id) async {
    final res = await _send('GET', '/clients/$id') as Response<dynamic>;
    return ClientDetail.fromJson(res.data);
  }

  Future<ClientConnection> clientConnection(int id) async {
    final res =
        await _send('GET', '/clients/$id/connection') as Response<dynamic>;
    return ClientConnection.fromJson(res.data);
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

  Future<CollectionSummary> collectionSummary() async {
    final res = await _send('GET', '/collection/summary') as Response<dynamic>;
    return CollectionSummary.fromJson(res.data);
  }

  Future<List<CollectionClient>> collectionClients(String q) async {
    final res = await _send(
      'GET',
      '/collection/clients',
      query: {'q': q.trim()},
    ) as Response<dynamic>;
    return [
      for (final row in listFrom(res.data, const ['clients']))
        CollectionClient.fromJson(row),
    ];
  }

  Future<PaymentReceipt> collectCash({
    required int clientId,
    required num amount,
    required String requestKey,
    String? note,
  }) async {
    final res = await _send(
      'POST',
      '/collection/cash',
      body: {
        'client_id': clientId,
        'amount': amount,
        'request_key': requestKey,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ) as Response<dynamic>;
    return PaymentReceipt.fromJson(res.data);
  }

  Future<PaymentReceipt> collectGateway({
    required int clientId,
    required num amount,
    required String gateway,
    required String txnId,
    required String requestKey,
    String? note,
  }) async {
    final res = await _send(
      'POST',
      '/collection/gateway',
      body: {
        'client_id': clientId,
        'amount': amount,
        'gateway': gateway,
        'txn_id': txnId.trim(),
        'request_key': requestKey,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ) as Response<dynamic>;
    return PaymentReceipt.fromJson(res.data);
  }

  /// [receiptPath] is a photo of the receipt on the phone (STF-06b).
  Future<void> addExpense({
    required num amount,
    required String note,
    required String requestKey,
    String? receiptPath,
  }) async {
    final fields = {
      'amount': amount,
      'note': note.trim(),
      'request_key': requestKey,
    };
    await _send(
      'POST',
      '/collection/expenses',
      body: receiptPath == null
          ? fields
          : FormData.fromMap({
              ...fields,
              'receipt': await MultipartFile.fromFile(
                receiptPath,
                filename: _fileName(receiptPath),
              ),
            }),
    );
  }

  Future<void> handover({
    required String owner,
    required String requestKey,
    num? amount,
    String? note,
  }) {
    return _send(
      'POST',
      '/collection/handover',
      body: {
        'owner': owner,
        'request_key': requestKey,
        'amount': ?amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<DuePage> dueList({String? q, int page = 1}) async {
    final query = q?.trim() ?? '';
    final res = await _send(
      'GET',
      '/due-list',
      query: {if (query.length >= 2) 'q': query, 'page': page},
    ) as Response<dynamic>;
    return DuePage.fromJson(res.data);
  }

  Future<({List<CashHandoverItem> handovers, List<ExpenseItem> expenses})>
  collectionApprovals() async {
    final res =
        await _send('GET', '/collection/approvals') as Response<dynamic>;
    final root = asMap(res.data);
    return (
      handovers: [
        for (final row in listFrom(root, const ['handovers']))
          CashHandoverItem.fromJson(row),
      ],
      expenses: [
        for (final row in listFrom(root, const ['expenses']))
          ExpenseItem.fromJson(row),
      ],
    );
  }

  Future<void> approveHandover(int id, {required num amount, String? note}) {
    return _send(
      'POST',
      '/collection/handovers/$id/approve',
      body: {
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<void> rejectHandover(int id, {required String note}) {
    return _send(
      'POST',
      '/collection/handovers/$id/reject',
      body: {'note': note.trim()},
    );
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

  // --- STF-03b: materials and install on a ticket ------------------------

  Future<MaterialsView> ticketMaterials(int ticketId) async {
    final res =
        await _send('GET', '/tickets/$ticketId/materials') as Response<dynamic>;
    return MaterialsView.fromJson(res.data);
  }

  /// Parts from the office stock. The same [requestKey] twice takes stock once.
  Future<List<UsedMaterial>> useMaterials(
    int ticketId, {
    required Map<int, num> lines,
    required String purpose,
    required String requestKey,
    String? note,
  }) async {
    final res = await _send(
      'POST',
      '/tickets/$ticketId/materials',
      body: {
        'lines': [
          for (final e in lines.entries)
            {'consumable_id': e.key, 'quantity': e.value},
        ],
        'purpose': purpose,
        'request_key': requestKey,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ) as Response<dynamic>;
    return UsedMaterial.list(asMap(res.data)['materials']);
  }

  /// A serial / barcode (issued to the ticket's client) or a part's SKU.
  Future<List<UsedMaterial>> scanForTicket(
    int ticketId, {
    required String code,
    required String requestKey,
  }) async {
    final res = await _send(
      'POST',
      '/tickets/$ticketId/scan',
      body: {'code': code.trim(), 'request_key': requestKey},
    ) as Response<dynamic>;
    return UsedMaterial.list(asMap(res.data)['materials']);
  }

  Future<InstallForm> installForm(int ticketId, {int? popId}) async {
    final res = await _send(
      'GET',
      '/tickets/$ticketId/install',
      query: {'pop_id': ?popId},
    ) as Response<dynamic>;
    return InstallForm.fromJson(res.data);
  }

  /// The new line's install (the ERP turns the line on and resolves the ticket).
  Future<void> recordInstall(
    int ticketId, {
    required int popId,
    int? routerId,
    String? onuSn,
    String? onuMac,
    String? ponPort,
    int? cableM,
    String? note,
  }) {
    String? t(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    return _send(
      'POST',
      '/tickets/$ticketId/install',
      body: {
        'pop_id': popId,
        'router_id': ?routerId,
        'onu_sn': ?t(onuSn),
        'onu_mac': ?t(onuMac),
        'pon_port': ?t(ponPort),
        'cable_m': ?cableM,
        'note': ?t(note),
      },
    );
  }

  // --- STF-06b: product sales -------------------------------------------

  Future<SalesView> sales() async {
    final res = await _send('GET', '/sales') as Response<dynamic>;
    return SalesView.fromJson(res.data);
  }

  Future<ScannedProduct> scanProduct(String code) async {
    final res = await _send(
      'POST',
      '/sales/scan',
      body: {'code': code.trim()},
    ) as Response<dynamic>;
    return ScannedProduct.fromJson(res.data);
  }

  /// Either [clientId] or [newConnection]. The ERP refuses a price below cost.
  Future<SaleItem> sell({
    required String code,
    required num price,
    required String payment,
    required String requestKey,
    String? paymentMethod,
    num? quantity,
    int? clientId,
    bool newConnection = false,
    String? note,
  }) async {
    final res = await _send(
      'POST',
      '/sales',
      body: {
        'code': code,
        'price': price,
        'payment': payment,
        'payment_method': ?paymentMethod,
        'quantity': ?quantity,
        if (newConnection) 'new_connection': true else 'client_id': clientId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'request_key': requestKey,
      },
    ) as Response<dynamic>;
    return SaleItem.fromJson(asMap(res.data)['sale']);
  }

  Future<void> giveSaleClient(int saleId, int clientId) =>
      _send('POST', '/sales/$saleId/client', body: {'client_id': clientId});

  // --- STF-08: reseller and recharge ------------------------------------

  Future<ResellerWallet> resellerWallet() async {
    final res = await _send('GET', '/reseller/wallet') as Response<dynamic>;
    return ResellerWallet.fromJson(res.data);
  }

  Future<List<ExpiringClient>> expiringClients({int days = 3}) async {
    final res = await _send(
      'GET',
      '/reseller/expiring',
      query: {'days': days},
    ) as Response<dynamic>;
    return [
      for (final row in listFrom(res.data, const ['clients']))
        ExpiringClient.fromJson(row),
    ];
  }

  Future<RechargeQuote> rechargeQuote(int clientId, {int months = 1}) async {
    final res = await _send(
      'GET',
      '/clients/$clientId/recharge-quote',
      query: {'months': months},
    ) as Response<dynamic>;
    return RechargeQuote.fromJson(res.data);
  }

  /// Returns the client's new expiry date. The same [requestKey] twice recharges once.
  Future<String?> recharge(
    int clientId, {
    required int months,
    required String method,
    required String requestKey,
    String? remarks,
  }) async {
    final res = await _send(
      'POST',
      '/clients/$clientId/recharge',
      body: {
        'months': months,
        'method': method,
        'request_key': requestKey,
        if (remarks != null && remarks.trim().isNotEmpty)
          'remarks': remarks.trim(),
      },
    ) as Response<dynamic>;
    return pickString(asMap(asMap(res.data)['client']), const ['expiry_date']);
  }

  // --- STF-09: dashboard and own HR -------------------------------------

  Future<OltList> olts() async {
    final res = await _send('GET', '/olts') as Response<dynamic>;
    return OltList.fromJson(res.data);
  }

  Future<OltPorts> oltPorts(int id) async {
    final res = await _send('GET', '/olts/$id') as Response<dynamic>;
    return OltPorts.fromJson(res.data);
  }

  Future<OnuPage> ponOnus(
    int oltId,
    String port, {
    String filter = 'all',
    String sort = 'pon',
    String dir = 'asc',
    int page = 1,
  }) async {
    final res = await _send(
      'GET',
      '/olts/$oltId/onus',
      query: {
        'port': port,
        'filter': filter,
        'sort': sort,
        'dir': dir,
        'page': page,
      },
    ) as Response<dynamic>;
    return OnuPage.fromJson(res.data);
  }

  Future<OnuPage> unmatchedOnus({String? q, int page = 1}) async {
    final res = await _send(
      'GET',
      '/olts/unmatched',
      query: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page,
      },
    ) as Response<dynamic>;
    return OnuPage.fromJson(res.data);
  }

  Future<List<Kpi>> dashboard() async {
    final res = await _send('GET', '/dashboard') as Response<dynamic>;
    return [
      for (final k in listFrom(res.data, const ['kpis'])) Kpi.fromJson(k),
    ];
  }

  Future<HrView> myHr({String? month}) async {
    final res = await _send(
      'GET',
      '/hr/me',
      query: {'month': ?month},
    ) as Response<dynamic>;
    return HrView.fromJson(res.data);
  }

  Future<void> askLeave({
    required String startDate,
    required String endDate,
    required String reason,
    bool unpaid = false,
  }) => _send(
    'POST',
    '/hr/leaves',
    body: {
      'pay': unpaid ? 'unpaid' : 'paid',
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason.trim(),
    },
  );

  Future<void> cancelLeave(int id) => _send('POST', '/hr/leaves/$id/cancel');

  Future<void> askAdvance({
    required num amount,
    required String month,
    String? note,
  }) => _send(
    'POST',
    '/hr/advances',
    body: {
      'amount': amount,
      'month': month,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Own payslips, newest month first (owner: everyone sees their own).
  Future<List<Payslip>> payslips() async {
    final res = await _send('GET', '/hr/payslips') as Response<dynamic>;
    return [
      for (final row in listFrom(res.data, const ['payslips']))
        Payslip.fromJson(row),
    ];
  }

  Future<void> cancelAdvance(int id) =>
      _send('POST', '/hr/advances/$id/cancel');

  // --- STF-06: expense decisions, clients near me ------------------------

  /// Another person's expense (never one's own: R5, the ERP refuses it).
  Future<void> decideExpense(int id, {required bool approve, String? note}) =>
      _send(
        'POST',
        '/collection/expenses/$id/${approve ? 'approve' : 'reject'}',
        body: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      );

  /// Clients with a due near the phone, nearest first (the ERP measures).
  Future<List<CollectionClient>> collectionClientsNear({
    required double latitude,
    required double longitude,
  }) async {
    final res = await _send(
      'GET',
      '/collection/clients',
      query: {'lat': latitude, 'lng': longitude, 'due_only': 1},
    ) as Response<dynamic>;
    return [
      for (final row in listFrom(res.data, const ['clients']))
        CollectionClient.fromJson(row),
    ];
  }

  // --- STF-07: new client, contact, new ticket ---------------------------

  Future<ClientFormOptions> clientFormOptions() async {
    final res =
        await _send('GET', '/clients/form-options') as Response<dynamic>;
    return ClientFormOptions.fromJson(res.data);
  }

  /// Quick add, as on the web. Without a POP the client waits as pending.
  /// Returns the new client's id.
  Future<int> createClient({
    required String pppoeUsername,
    required String pppoePassword,
    required int packageId,
    String? name,
    String? phone,
    int? popId,
    int? routerId,
  }) async {
    String? t(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final res = await _send(
      'POST',
      '/clients',
      body: {
        'pppoe_username': pppoeUsername.trim(),
        'pppoe_password': pppoePassword,
        'package_id': packageId,
        'name': ?t(name),
        'phone': ?t(phone),
        'pop_id': ?popId,
        'router_id': ?routerId,
      },
    ) as Response<dynamic>;
    return toNum(asMap(asMap(res.data)['client'])['id'])?.toInt() ?? 0;
  }

  /// [field] is `phone`, `address` or `nid` (the ERP audits old / new).
  Future<void> updateClientContact(int id, String field, String value) => _send(
    'PATCH',
    '/clients/$id/contact',
    body: {'field': field, 'value': value.trim()},
  );

  Future<TicketOptions> ticketOptions() async {
    final res = await _send('GET', '/tickets/options') as Response<dynamic>;
    return TicketOptions.fromJson(res.data);
  }

  /// Opens a ticket (the ERP runs the nearest-technician dispatch).
  /// Returns the new ticket's id.
  Future<int> createTicket({
    required int clientId,
    required String subject,
    String? description,
    String? priority,
    int? categoryId,
  }) async {
    final res = await _send(
      'POST',
      '/tickets',
      body: {
        'client_id': clientId,
        'subject': subject.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'priority': ?priority,
        'ticket_category_id': ?categoryId,
      },
    ) as Response<dynamic>;
    return toNum(asMap(asMap(res.data)['ticket'])['id'])?.toInt() ?? 0;
  }
}

String _fileName(String path) {
  final parts = path.split(RegExp(r'[/\\]'));
  final name = parts.isEmpty ? '' : parts.last;
  return name.isEmpty ? 'photo.jpg' : name;
}
