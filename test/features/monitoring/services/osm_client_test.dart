import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/services/geocoding_service.dart';
import 'package:satu_rumah/features/monitoring/services/osm_client.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final String body;
  _RecordingAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(NominatimGeocodingService.resetForTest);

  test('permintaan OSM membawa identitas aplikasi', () {
    final dio = newOsmDio(baseUrl: 'https://nominatim.openstreetmap.org');
    expect(dio.options.headers['User-Agent'], kOsmUserAgent);
    expect(kOsmUserAgent, isNot(contains('Dart/')));
  });

  test(
    'geocoding memakai bahasa lewat query dan meng-cache per titik',
    () async {
      final adapter = _RecordingAdapter(
        jsonEncode({'display_name': 'Jl. Uji'}),
      );
      final dio = newOsmDio(baseUrl: 'https://nominatim.openstreetmap.org')
        ..httpClientAdapter = adapter;
      final service = NominatimGeocodingService(dio: dio);

      expect(await service.reverse(-7.32741, 108.22071), 'Jl. Uji');
      // Titik yang sama (dibulatkan ~11 m) tidak meminta ulang.
      expect(await service.reverse(-7.32742, 108.22072), 'Jl. Uji');

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.queryParameters['accept-language'], 'id');
      expect(adapter.requests.single.headers['User-Agent'], kOsmUserAgent);
    },
  );

  test('kegagalan tidak di-cache dan mengembalikan null', () async {
    final adapter = _RecordingAdapter('{}');
    final dio = newOsmDio(baseUrl: 'https://nominatim.openstreetmap.org')
      ..httpClientAdapter = adapter;
    final service = NominatimGeocodingService(dio: dio);
    expect(await service.reverse(1, 1), isNull);
    expect(await service.reverse(1, 1), isNull);
    expect(adapter.requests, hasLength(2));
  });
}
