import 'dart:async';

import 'package:dio/dio.dart';

import 'osm_client.dart';

/// Mengubah koordinat menjadi alamat yang bisa dibaca.
abstract class GeocodingService {
  /// Alamat singkat untuk koordinat ini, atau null bila gagal/offline.
  Future<String?> reverse(double latitude, double longitude);
}

/// Geocoding lewat OpenStreetMap Nominatim.
///
/// Mengikuti kebijakan Nominatim: User-Agent yang mengenali aplikasi, paling
/// banyak 1 permintaan per detik, dan hasil di-cache per titik (~11 m) agar
/// foto berurutan di lokasi yang sama tidak meminta ulang. Koordinat petugas
/// dikirim ke layanan pihak ketiga; gagal berarti cap geotag hanya memuat
/// koordinat.
class NominatimGeocodingService implements GeocodingService {
  static const Duration _minInterval = Duration(seconds: 1);
  static final Map<String, String> _cache = {};
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  final Dio _dio;

  NominatimGeocodingService({Dio? dio})
    : _dio = dio ?? newOsmDio(baseUrl: 'https://nominatim.openstreetmap.org');

  /// Hanya untuk tes.
  static void resetForTest() {
    _cache.clear();
    _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Future<String?> reverse(double latitude, double longitude) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final wait = _minInterval - DateTime.now().difference(_lastRequest);
      if (!wait.isNegative) await Future<void>.delayed(wait);
      _lastRequest = DateTime.now();
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude,
          'lon': longitude,
          'zoom': 18,
          'addressdetails': 0,
          // Lewat query, bukan header, agar browser tidak memicu preflight CORS.
          'accept-language': 'id',
        },
      );
      final name = response.data?['display_name'];
      if (name is! String) return null;
      final trimmed = name.trim();
      if (trimmed.isEmpty) return null;
      return _cache[key] = trimmed;
    } catch (_) {
      return null;
    }
  }
}
