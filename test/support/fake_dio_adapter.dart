import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A captured outgoing HTTP request, exposed to tests for assertions.
class CapturedRequest {
  CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final dynamic body;

  /// Convenience accessor for JSON object bodies.
  Map<String, dynamic> get json => body as Map<String, dynamic>;
}

/// A deterministic [HttpClientAdapter] for unit tests.
///
/// It records every outgoing request so tests can assert on the exact path,
/// method, and payload the repository sends, and returns a canned response
/// (status code + JSON/empty body) so error paths like HTTP 409 can be
/// reproduced without a real backend.
class FakeDioAdapter implements HttpClientAdapter {
  FakeDioAdapter({
    required this.statusCode,
    this.responseJson,
    this.responseList,
  });

  /// The HTTP status code every request resolves to.
  final int statusCode;

  /// JSON object body returned to the client (mutually exclusive with [responseList]).
  final Map<String, dynamic>? responseJson;

  /// JSON array body returned to the client.
  final List<dynamic>? responseList;

  /// All requests that passed through this adapter, in order.
  final List<CapturedRequest> requests = <CapturedRequest>[];

  CapturedRequest get lastRequest => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      CapturedRequest(
        method: options.method,
        path: options.path,
        body: options.data,
      ),
    );

    final String payload;
    if (responseList != null) {
      payload = jsonEncode(responseList);
    } else if (responseJson != null) {
      payload = jsonEncode(responseJson);
    } else {
      payload = '';
    }

    return ResponseBody.fromString(
      payload,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a [Dio] wired to a [FakeDioAdapter] for tests.
Dio buildFakeDio(FakeDioAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.httpClientAdapter = adapter;
  return dio;
}
