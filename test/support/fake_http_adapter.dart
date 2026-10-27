import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Penjawab HTTP palsu: antrean jawaban berurutan dan catatan permintaan.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody Function()> _replies = [];

  void reply(int status, Object body) => _replies.add(
    () => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_replies.isEmpty) {
      throw StateError('Tidak ada jawaban untuk ${options.method} ${options.path}');
    }
    return _replies.removeAt(0)();
  }

  @override
  void close({bool force = false}) {}
}
