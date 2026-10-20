import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/utils/photo_validation.dart';

Uint8List _bytes(List<int> head, {int total = 32}) {
  final data = Uint8List(total);
  data.setRange(0, head.length, head);
  return data;
}

void main() {
  final jpeg = _bytes([0xFF, 0xD8, 0xFF, 0xE0]);
  final png = _bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final webp = _bytes([
    0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, //
  ]);
  final heic = _bytes([
    0,
    0,
    0,
    0x18,
    0x66,
    0x74,
    0x79,
    0x70,
    0x68,
    0x65,
    0x69,
    0x63,
  ]);

  group('detectPhotoFormat', () {
    test('mengenali JPEG, PNG, dan WebP dari byte awal', () {
      expect(detectPhotoFormat(jpeg), PhotoFormat.jpeg);
      expect(detectPhotoFormat(png), PhotoFormat.png);
      expect(detectPhotoFormat(webp), PhotoFormat.webp);
    });

    test('byte lain atau terlalu pendek tidak dikenali', () {
      expect(detectPhotoFormat(Uint8List.fromList([1, 2, 3])), isNull);
      expect(detectPhotoFormat(Uint8List(0)), isNull);
      expect(detectPhotoFormat(heic), isNull);
    });
  });

  group('validatePhotoBytes', () {
    test('foto JPEG, PNG, dan WebP diterima', () {
      expect(validatePhotoBytes(jpeg), isNull);
      expect(validatePhotoBytes(png), isNull);
      expect(validatePhotoBytes(webp), isNull);
    });

    test('berkas kosong ditolak', () {
      expect(validatePhotoBytes(Uint8List(0)), 'berkas kosong');
    });

    test('lebih dari 10 MB ditolak', () {
      final big = Uint8List(kMaxPhotoBytes + 1)
        ..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
      expect(validatePhotoBytes(big), 'lebih dari 10 MB');
      final limit = Uint8List(kMaxPhotoBytes)
        ..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
      expect(validatePhotoBytes(limit), isNull);
    });

    test('HEIC ditolak dengan petunjuk yang jelas', () {
      expect(validatePhotoBytes(heic), contains('HEIC'));
    });

    test('format lain ditolak', () {
      expect(
        validatePhotoBytes(Uint8List.fromList([1, 2, 3, 4, 5])),
        contains('format tidak didukung'),
      );
    });
  });

  group('photoDigest', () {
    test('isi sama menghasilkan sidik sama, isi beda berbeda', () {
      final a = Uint8List.fromList([1, 2, 3, 4]);
      final b = Uint8List.fromList([1, 2, 3, 4]);
      final c = Uint8List.fromList([1, 2, 3, 5]);
      expect(photoDigest(a), photoDigest(b));
      expect(photoDigest(a), isNot(photoDigest(c)));
    });
  });
}
