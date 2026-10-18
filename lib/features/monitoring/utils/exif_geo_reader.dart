import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

import '../data/models/evidence_photo_item.dart';
import 'geo_distance.dart';

/// Mengambil koordinat GPS yang tertanam di berkas foto, bila ada.
///
/// Hasilnya hanyalah klaim yang tertulis di berkas foto: tidak diverifikasi
/// dan dapat diubah pihak lain. Fungsi ini tidak pernah melempar; foto tanpa
/// EXIF, EXIF rusak, atau format yang tidak didukung menghasilkan `null`.
Future<ExifGeo?> readExifGeo(Uint8List bytes) async {
  if (bytes.isEmpty) return null;
  try {
    final data = await readExifFromBytes(bytes);
    return parseExifGeo(data);
  } catch (error) {
    debugPrint('readExifGeo: $error');
    return null;
  }
}

/// Menerjemahkan tag EXIF GPS (derajat-menit-detik + referensi arah) menjadi
/// koordinat desimal. Terpisah dari pembacaan berkas agar mudah diuji.
ExifGeo? parseExifGeo(Map<String, IfdTag> data) {
  final latitude = _coordinate(
    data['GPS GPSLatitude'],
    data['GPS GPSLatitudeRef'],
    negativeRef: 'S',
  );
  final longitude = _coordinate(
    data['GPS GPSLongitude'],
    data['GPS GPSLongitudeRef'],
    negativeRef: 'W',
  );
  if (latitude == null || longitude == null) return null;
  if (!isValidLatLng(latitude, longitude)) return null;
  // Titik (0, 0) hampir selalu berarti GPS tidak terkunci, bukan lokasi nyata.
  if (latitude == 0 && longitude == 0) return null;
  return ExifGeo(latitude: latitude, longitude: longitude);
}

double? _coordinate(IfdTag? tag, IfdTag? ref, {required String negativeRef}) {
  if (tag == null) return null;
  final values = tag.values;
  if (values is! IfdRatios || values.ratios.length < 3) return null;
  final parts = [
    for (final ratio in values.ratios.take(3))
      if (ratio.denominator == 0) double.nan else ratio.toDouble(),
  ];
  if (parts.any((part) => part.isNaN || part.isInfinite || part < 0)) {
    return null;
  }
  final degrees = parts[0] + parts[1] / 60 + parts[2] / 3600;
  final hemisphere = ref?.printable.trim().toUpperCase();
  return hemisphere == negativeRef ? -degrees : degrees;
}
