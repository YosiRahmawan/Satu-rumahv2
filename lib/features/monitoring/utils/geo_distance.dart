import 'dart:math';

import '../data/models/evidence_photo_item.dart';
import '../data/models/project_reference.dart';

/// Ambang awal untuk diuji lapangan. Bukan aturan penolakan otomatis: hanya
/// menentukan kapan petugas perlu memberi alasan dan Admin perlu memeriksa.
const double kPhotoLocationToleranceMeters = 50;

/// Akurasi di atas nilai ini membuat status "dalam toleransi" tidak boleh
/// dinyatakan tanpa peringatan (mis. GPS laptop di Web).
const double kLowAccuracyMeters = 100;

const double _earthRadiusMeters = 6371000;

/// Jarak lingkaran besar antara dua koordinat WGS84, dalam meter.
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  double rad(double deg) => deg * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * _earthRadiusMeters * asin(min(1, sqrt(a)));
}

bool isValidLatLng(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

enum ProximityStatus {
  /// Jarak dihitung dan tidak melebihi toleransi.
  withinTolerance,

  /// Jarak dihitung dan melebihi toleransi.
  outsideTolerance,

  /// Foto sudah berlokasi, tetapi titik proyek belum tersedia.
  noReference,

  /// Foto belum memiliki lokasi pilihan petugas.
  noLocation,
}

class PhotoProximity {
  final ProximityStatus status;
  final double? distanceMeters;

  /// Akurasi lokasi (meter) bila dicatat; terpisah dari jarak.
  final double? accuracyMeters;

  const PhotoProximity({
    required this.status,
    this.distanceMeters,
    this.accuracyMeters,
  });

  bool get lowAccuracy =>
      accuracyMeters != null && accuracyMeters! > kLowAccuracyMeters;
}

/// Menghitung kedekatan lokasi pilihan petugas terhadap titik proyek.
/// Jarak tidak pernah dihitung dari koordinat selain `location`.
PhotoProximity evaluatePhotoProximity({
  required OfficerLocation? location,
  required ProjectReference? reference,
  double toleranceMeters = kPhotoLocationToleranceMeters,
}) {
  if (location == null) {
    return const PhotoProximity(status: ProximityStatus.noLocation);
  }
  if (reference == null) {
    return PhotoProximity(
      status: ProximityStatus.noReference,
      accuracyMeters: location.accuracyMeters,
    );
  }
  final distance = haversineMeters(
    location.latitude,
    location.longitude,
    reference.latitude,
    reference.longitude,
  );
  return PhotoProximity(
    status: distance <= toleranceMeters
        ? ProximityStatus.withinTolerance
        : ProximityStatus.outsideTolerance,
    distanceMeters: distance,
    accuracyMeters: location.accuracyMeters,
  );
}
