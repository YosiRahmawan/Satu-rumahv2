import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/utils/photo_location_summary.dart';

const _project = ProjectReference(latitude: -7.3274, longitude: 108.2207);

EvidencePhotoItem _photo({
  double lat = -7.32745,
  double lng = 108.2207,
  LocationMethod method = LocationMethod.manualPin,
  String? note,
  ExifGeo? exif,
  bool located = true,
}) {
  return EvidencePhotoItem.fromPath('a.jpg').copyWith(
    exif: exif,
    location: located
        ? OfficerLocation(
            latitude: lat,
            longitude: lng,
            method: method,
            selectedAt: DateTime(2026, 10, 20),
            clarificationNote: note,
          )
        : null,
  );
}

void main() {
  test('belum berlokasi: hanya menyatakan belum ditentukan', () {
    final summary = summarizePhotoLocation(_photo(located: false));
    expect(summary.hasLocation, isFalse);
    expect(summary.lines, ['Lokasi: belum ditentukan']);
  });

  test('tanpa titik proyek, jarak dinyatakan tidak dihitung', () {
    final summary = summarizePhotoLocation(_photo());
    expect(summary.lines, [
      'Lokasi: -7.327450, 108.220700',
      'Sumber: Penunjukan manual',
      'Jarak ke proyek: tidak dihitung (titik proyek belum tersedia)',
    ]);
    expect(summary.outsideTolerance, isFalse);
  });

  test('dalam batas awal: jarak tercatat tanpa peringatan', () {
    final summary = summarizePhotoLocation(_photo(), reference: _project);
    expect(summary.distance, contains('dalam batas awal 50 m'));
    expect(summary.outsideTolerance, isFalse);
  });

  test('di luar batas awal: ditandai dan alasan petugas ikut tercatat', () {
    final summary = summarizePhotoLocation(
      _photo(lat: -7.3350, note: 'Dari gerbang utama'),
      reference: _project,
    );
    expect(summary.outsideTolerance, isTrue);
    expect(summary.distance, contains('di luar batas awal 50 m'));
    expect(summary.lines, contains('Alasan petugas: Dari gerbang utama'));
  });

  test('GPS foto ditampilkan terpisah dan ditandai tidak diverifikasi', () {
    final summary = summarizePhotoLocation(
      _photo(exif: const ExifGeo(latitude: -7.3, longitude: 108.2)),
    );
    expect(
      summary.lines.last,
      'GPS tertanam di foto: -7.300000, 108.200000 (tidak diverifikasi)',
    );
    // Foto belum berlokasi tetap menampilkan GPS foto tanpa mengisinya.
    final unlocated = summarizePhotoLocation(
      _photo(
        located: false,
        exif: const ExifGeo(latitude: -7.3, longitude: 108.2),
      ),
    );
    expect(unlocated.hasLocation, isFalse);
    expect(unlocated.lines.first, 'Lokasi: belum ditentukan');
    expect(unlocated.lines.last, contains('tidak diverifikasi'));
  });

  test('sumber GPS foto dinyatakan dikonfirmasi petugas', () {
    final summary = summarizePhotoLocation(
      _photo(method: LocationMethod.exifConfirmed),
    );
    expect(summary.source, 'GPS foto, dikonfirmasi petugas');
  });
}
