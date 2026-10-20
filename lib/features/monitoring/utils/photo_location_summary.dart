import '../data/models/evidence_photo_item.dart';
import '../data/models/project_reference.dart';
import 'geo_distance.dart';

/// Ringkasan lokasi satu foto untuk dibaca pemeriksa (Berita Acara, draf, PDF).
///
/// Hanya menyatakan apa yang tercatat: titik pilihan petugas, sumbernya,
/// jaraknya ke titik proyek bila titik itu ada, dan alasan petugas. GPS yang
/// tertanam di foto ditampilkan terpisah dan tidak diverifikasi.
class PhotoLocationSummary {
  final bool hasLocation;
  final String coordinates;
  final String source;
  final String distance;
  final bool outsideTolerance;
  final String? note;
  final String? embeddedGps;

  const PhotoLocationSummary({
    required this.hasLocation,
    required this.coordinates,
    required this.source,
    required this.distance,
    required this.outsideTolerance,
    this.note,
    this.embeddedGps,
  });

  /// Baris teks berurutan, siap ditampilkan satu per baris.
  List<String> get lines => [
    if (hasLocation) ...[
      'Lokasi: $coordinates',
      'Sumber: $source',
      'Jarak ke proyek: $distance',
    ] else
      'Lokasi: belum ditentukan',
    if (note != null) 'Alasan petugas: $note',
    if (embeddedGps != null)
      'GPS tertanam di foto: $embeddedGps (tidak diverifikasi)',
  ];
}

String _sourceLabel(LocationMethod method) => switch (method) {
  LocationMethod.exifConfirmed => 'GPS foto, dikonfirmasi petugas',
  LocationMethod.manualPin => 'Penunjukan manual',
  LocationMethod.deviceAtEntry => 'Posisi petugas saat input',
};

PhotoLocationSummary summarizePhotoLocation(
  EvidencePhotoItem photo, {
  ProjectReference? reference,
}) {
  final location = photo.location;
  final exif = photo.exif;
  final embedded = exif == null
      ? null
      : '${formatCoordinate(exif.latitude)}, ${formatCoordinate(exif.longitude)}';
  if (location == null) {
    return PhotoLocationSummary(
      hasLocation: false,
      coordinates: '',
      source: '',
      distance: '',
      outsideTolerance: false,
      embeddedGps: embedded,
    );
  }
  final proximity = evaluatePhotoProximity(
    location: location,
    reference: reference,
  );
  final String distance;
  switch (proximity.status) {
    case ProximityStatus.noLocation:
    case ProximityStatus.noReference:
      distance = 'tidak dihitung (titik proyek belum tersedia)';
    case ProximityStatus.withinTolerance:
      distance =
          '${formatDistance(proximity.distanceMeters!)} '
          '(dalam batas awal ${kPhotoLocationToleranceMeters.round()} m)';
    case ProximityStatus.outsideTolerance:
      distance =
          '${formatDistance(proximity.distanceMeters!)} '
          '(di luar batas awal ${kPhotoLocationToleranceMeters.round()} m)';
  }
  return PhotoLocationSummary(
    hasLocation: true,
    coordinates:
        '${formatCoordinate(location.latitude)}, ${formatCoordinate(location.longitude)}',
    source: _sourceLabel(location.method),
    distance: distance,
    outsideTolerance: proximity.status == ProximityStatus.outsideTolerance,
    note: location.clarificationNote,
    embeddedGps: embedded,
  );
}
