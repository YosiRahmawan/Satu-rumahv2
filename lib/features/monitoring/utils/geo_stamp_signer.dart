import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../data/models/geo_stamp.dart';

/// Hasil pemeriksaan tanda tangan geotag pada sebuah berkas foto.
enum GeoStampFailure {
  /// Berkas bukan JPEG.
  notJpeg,

  /// Tidak ada tanda geotag aplikasi (foto bukan dari kamera aplikasi).
  missing,

  /// Tanda ada tetapi tidak cocok: foto diubah, disimpan ulang, atau dipalsukan.
  tampered,
}

class GeoStampVerification {
  final GeoStamp? stamp;
  final GeoStampFailure? failure;

  const GeoStampVerification.valid(GeoStamp this.stamp) : failure = null;
  const GeoStampVerification.invalid(GeoStampFailure this.failure)
    : stamp = null;

  bool get isValid => stamp != null;
}

/// Menanam dan memeriksa tanda geotag di dalam berkas JPEG.
///
/// Tanda disimpan sebagai segmen komentar JPEG (COM) berisi data geotag dan
/// HMAC-SHA256 atas data itu beserta sidik isi foto (tanpa segmen tandanya).
/// Menyimpan ulang foto, memotong, atau menyalin tanda ke foto lain membuat
/// pemeriksaan gagal.
///
/// Batasan yang jujur: kuncinya ada di dalam aplikasi, jadi ini penanda
/// anti-ubah yang dasar, bukan bukti kriptografis terhadap pihak yang membongkar
/// aplikasi. Bukti yang kuat memerlukan penandatanganan di server.
class GeoStampSigner {
  GeoStampSigner._();

  static const String _prefix = 'SATURUMAH-GEO1:';
  static const String _key = 'satu-rumah.geostamp.v1';

  /// Mengembalikan salinan [jpeg] yang memuat tanda geotag untuk [stamp].
  static Uint8List embed(Uint8List jpeg, GeoStamp stamp) {
    if (!_isJpeg(jpeg)) {
      throw ArgumentError('Berkas bukan JPEG.');
    }
    final clean = _stripStamp(jpeg).bytes;
    final payload = base64Url.encode(utf8.encode(jsonEncode(stamp.toJson())));
    final signature = _sign(payload, clean);
    final comment = utf8.encode('$_prefix$payload.$signature');
    // Segmen COM: 0xFF 0xFE, panjang (2 byte, termasuk dirinya), isi.
    final length = comment.length + 2;
    if (length > 0xFFFF) throw ArgumentError('Data geotag terlalu besar.');
    final segment = <int>[0xFF, 0xFE, length >> 8, length & 0xFF, ...comment];
    return Uint8List.fromList([
      ...clean.sublist(0, 2),
      ...segment,
      ...clean.sublist(2),
    ]);
  }

  static GeoStampVerification verify(Uint8List bytes) {
    if (!_isJpeg(bytes)) {
      return const GeoStampVerification.invalid(GeoStampFailure.notJpeg);
    }
    final stripped = _stripStamp(bytes);
    final comment = stripped.comment;
    if (comment == null) {
      return const GeoStampVerification.invalid(GeoStampFailure.missing);
    }
    final dot = comment.lastIndexOf('.');
    if (dot < 0) {
      return const GeoStampVerification.invalid(GeoStampFailure.tampered);
    }
    final payload = comment.substring(0, dot);
    final signature = comment.substring(dot + 1);
    if (!_constantTimeEquals(signature, _sign(payload, stripped.bytes))) {
      return const GeoStampVerification.invalid(GeoStampFailure.tampered);
    }
    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(payload)),
      );
      final stamp = GeoStamp.fromJson(jsonDecode(decoded));
      if (stamp == null) {
        return const GeoStampVerification.invalid(GeoStampFailure.tampered);
      }
      return GeoStampVerification.valid(stamp);
    } on FormatException {
      return const GeoStampVerification.invalid(GeoStampFailure.tampered);
    }
  }

  static bool _isJpeg(Uint8List b) =>
      b.length > 4 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  static String _sign(String payload, Uint8List cleanJpeg) {
    final digest = sha256.convert(cleanJpeg).toString();
    final hmac = Hmac(sha256, utf8.encode(_key));
    return hmac.convert(utf8.encode('$payload.$digest')).toString();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Membuang segmen COM bertanda aplikasi dan mengembalikan isinya (bila ada).
  static ({Uint8List bytes, String? comment}) _stripStamp(Uint8List jpeg) {
    var i = 2;
    while (i + 4 <= jpeg.length) {
      if (jpeg[i] != 0xFF) break;
      final marker = jpeg[i + 1];
      if (marker == 0xFF) {
        i++; // byte pengisi
        continue;
      }
      // Penanda tanpa panjang.
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      // Mulai data citra: tidak ada segmen komentar lagi sesudahnya.
      if (marker == 0xDA || marker == 0xD9) break;
      final length = (jpeg[i + 2] << 8) | jpeg[i + 3];
      if (length < 2 || i + 2 + length > jpeg.length) break;
      if (marker == 0xFE) {
        final text = String.fromCharCodes(jpeg.sublist(i + 4, i + 2 + length));
        if (text.startsWith(_prefix)) {
          final cleaned = Uint8List.fromList([
            ...jpeg.sublist(0, i),
            ...jpeg.sublist(i + 2 + length),
          ]);
          return (bytes: cleaned, comment: text.substring(_prefix.length));
        }
      }
      i += 2 + length;
    }
    return (bytes: jpeg, comment: null);
  }
}
