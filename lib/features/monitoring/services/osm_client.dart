import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Identitas aplikasi untuk layanan OpenStreetMap (Nominatim dan tile).
/// Kebijakan OSM mewajibkan identitas yang jelas; User-Agent bawaan Dart
/// diblokir. Ganti dengan kontak resmi instansi sebelum rilis.
const String kOsmUserAgent =
    'SatuRumahV2/1.0 (aplikasi pengawasan perumahan Kota Tasikmalaya; Flutter)';

/// Atribusi yang wajib tampil di setiap peta berbasis data OSM.
const String kOsmAttribution = '© OpenStreetMap';

Dio newOsmDio({String? baseUrl, ResponseType? responseType}) => Dio(
  BaseOptions(
    baseUrl: baseUrl ?? '',
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 5),
    responseType: responseType,
    // Browser melarang skrip mengisi User-Agent; di web ia mengirim Referer.
    headers: kIsWeb ? null : {'User-Agent': kOsmUserAgent},
  ),
);
