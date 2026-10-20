import 'package:dio/dio.dart';

/// Mengubah koordinat menjadi alamat yang bisa dibaca.
abstract class GeocodingService {
  /// Alamat singkat untuk koordinat ini, atau null bila gagal/offline.
  Future<String?> reverse(double latitude, double longitude);
}

/// Geocoding lewat OpenStreetMap Nominatim.
///
/// Koordinat petugas dikirim ke layanan pihak ketiga. Kebijakan Nominatim
/// membatasi penggunaan (maks. 1 permintaan/detik, wajib identitas aplikasi);
/// di sini hanya dipanggil saat petugas memotret. Gagal berarti cap geotag
/// hanya memuat koordinat.
class NominatimGeocodingService implements GeocodingService {
  final Dio _dio;

  NominatimGeocodingService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 5),
              headers: const {'Accept-Language': 'id'},
            ),
          );

  @override
  Future<String?> reverse(double latitude, double longitude) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude,
          'lon': longitude,
          'zoom': 18,
          'addressdetails': 0,
        },
      );
      final name = response.data?['display_name'];
      if (name is! String) return null;
      final trimmed = name.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }
}
