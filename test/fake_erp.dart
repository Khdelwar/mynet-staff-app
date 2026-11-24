import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mynet_staff/state/providers.dart';

/// Answers ERP calls from a table of `METHOD /path` → handler.
class FakeErp implements HttpClientAdapter {
  FakeErp(this.routes);

  /// Handler returns `(status, jsonBody)`.
  final Map<String, (int, Object?) Function(RequestOptions)> routes;
  final List<String> calls = [];
  final List<RequestOptions> requests = [];
  bool offline = false;

  Dio get dio =>
      Dio(BaseOptions(baseUrl: 'https://erp.test/api/staff/v1'))
        ..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key =
        '${options.method} ${options.uri.path.replaceFirst('/api/staff/v1', '')}';
    calls.add(key);
    requests.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final (status, body) =
        (routes[key] ?? (_) => (404, {'message': 'Not found'}))(options);
    if (body is Uint8List) {
      return ResponseBody.fromBytes(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The phone already has `https://erp.test` saved as its ERP address.
class FixedServer extends ServerController {
  @override
  String? build() => 'https://erp.test';
}
