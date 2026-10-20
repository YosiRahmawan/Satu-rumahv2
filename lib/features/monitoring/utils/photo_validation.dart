import 'package:flutter/foundation.dart';

/// Batas ukuran satu foto dokumentasi, sama dengan yang tertulis di layar.
const int kMaxPhotoBytes = 10 * 1024 * 1024;

enum PhotoFormat { jpeg, png, webp }

/// Mengenali format dari byte awal berkas (bukan dari nama atau ekstensi).
PhotoFormat? detectPhotoFormat(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return PhotoFormat.jpeg;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return PhotoFormat.png;
  }
  if (bytes.length >= 12 &&
      _ascii(bytes, 0, 'RIFF') &&
      _ascii(bytes, 8, 'WEBP')) {
    return PhotoFormat.webp;
  }
  return null;
}

bool _ascii(Uint8List bytes, int offset, String text) {
  for (var i = 0; i < text.length; i++) {
    if (bytes[offset + i] != text.codeUnitAt(i)) return false;
  }
  return true;
}

/// Alasan penolakan dalam bahasa pengguna, atau null bila foto dapat dipakai.
String? validatePhotoBytes(Uint8List bytes) {
  if (bytes.isEmpty) return 'berkas kosong';
  if (bytes.length > kMaxPhotoBytes) return 'lebih dari 10 MB';
  if (detectPhotoFormat(bytes) != null) return null;
  final isHeif =
      bytes.length >= 12 &&
      _ascii(bytes, 4, 'ftyp') &&
      (_ascii(bytes, 8, 'heic') ||
          _ascii(bytes, 8, 'heix') ||
          _ascii(bytes, 8, 'mif1') ||
          _ascii(bytes, 8, 'heif'));
  if (isHeif) return 'format HEIC belum didukung, simpan sebagai JPG';
  return 'format tidak didukung, gunakan JPG, PNG, atau WebP';
}

/// Sidik isi foto untuk mendeteksi foto yang sama dipilih dua kali.
String photoDigest(Uint8List bytes) =>
    '${bytes.length}:${Object.hashAll(bytes)}';
