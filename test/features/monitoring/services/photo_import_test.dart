import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/services/photo_import.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

import '../../../support/camera_fakes.dart';

void main() {
  final stamp = GeoStamp(
    latitude: -7.3274,
    longitude: 108.2207,
    capturedAt: DateTime.utc(2026, 10, 20, 2, 30),
    address: 'Jl. Contoh',
  );

  test('foto bergeotag sah diterima', () {
    final bytes = GeoStampSigner.embed(plainJpeg(), stamp);
    final result = verifyGalleryPhoto('a.jpg', bytes);
    expect(result.isAccepted, isTrue);
    expect(result.stamp, stamp);
  });

  test('foto tanpa geotag ditolak', () {
    final result = verifyGalleryPhoto('b.jpg', plainJpeg());
    expect(result.isAccepted, isFalse);
    expect(result.error, contains('Tidak ada geotag'));
  });

  test('foto yang pikselnya diubah ditolak', () {
    final bytes = GeoStampSigner.embed(plainJpeg(), stamp);
    final altered = Uint8List.fromList(bytes)..[bytes.length - 20] ^= 0xFF;
    final result = verifyGalleryPhoto('c.jpg', altered);
    expect(result.isAccepted, isFalse);
    expect(result.error, contains('diubah'));
  });

  test('berkas bukan JPEG ditolak', () {
    final result = verifyGalleryPhoto('d.png', Uint8List.fromList([1, 2, 3]));
    expect(result.isAccepted, isFalse);
    expect(result.error, contains('Bukan berkas JPEG'));
  });

  test('foto lebih dari 10 MB ditolak', () {
    final result = verifyGalleryPhoto('e.jpg', Uint8List(kMaxImportBytes + 1));
    expect(result.isAccepted, isFalse);
    expect(result.error, contains('10 MB'));
  });
}
