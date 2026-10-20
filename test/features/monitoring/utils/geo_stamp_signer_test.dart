import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

Uint8List _jpeg({int seed = 40}) {
  final image = img.Image(width: 32, height: 24);
  img.fill(image, color: img.ColorRgb8(seed, 120, 200));
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

final _stamp = GeoStamp(
  latitude: -7.3274,
  longitude: 108.2207,
  accuracyMeters: 12.4,
  capturedAt: DateTime.utc(2026, 10, 20, 9, 30, 15),
  address: 'Jl. Sukawarni, Kota Tasikmalaya',
  note: 'Drainase sisi timur',
);

void main() {
  test('foto bertanda dapat diperiksa dan datanya kembali utuh', () {
    final signed = GeoStampSigner.embed(_jpeg(), _stamp);
    final result = GeoStampSigner.verify(signed);

    expect(result.isValid, isTrue);
    expect(result.stamp, _stamp);
  });

  test('hasil tanda tetap JPEG yang dapat didekode', () {
    final signed = GeoStampSigner.embed(_jpeg(), _stamp);
    final decoded = img.decodeJpg(signed);
    expect(decoded, isNotNull);
    expect(decoded!.width, 32);
  });

  test('foto tanpa tanda ditolak sebagai tidak ada tanda', () {
    final result = GeoStampSigner.verify(_jpeg());
    expect(result.isValid, isFalse);
    expect(result.failure, GeoStampFailure.missing);
  });

  test('berkas bukan JPEG ditolak', () {
    final result = GeoStampSigner.verify(
      Uint8List.fromList([1, 2, 3, 4, 5, 6]),
    );
    expect(result.failure, GeoStampFailure.notJpeg);
  });

  test('menyimpan ulang foto (piksel berubah) membuat tanda tidak sah', () {
    final signed = GeoStampSigner.embed(_jpeg(), _stamp);
    final reencoded = Uint8List.fromList(
      img.encodeJpg(img.decodeJpg(signed)!, quality: 70),
    );
    // Tanda hilang karena penyimpanan ulang membuang segmen komentar.
    expect(GeoStampSigner.verify(reencoded).failure, GeoStampFailure.missing);
  });

  test('menyalin tanda ke foto lain membuat tanda tidak sah', () {
    final signedA = GeoStampSigner.embed(_jpeg(seed: 40), _stamp);
    final otherPhoto = _jpeg(seed: 200);
    // Pindahkan segmen COM milik A ke foto lain.
    final commentLength = (signedA[4] << 8) | signedA[5];
    final segment = signedA.sublist(2, 4 + commentLength);
    final forged = Uint8List.fromList([
      ...otherPhoto.sublist(0, 2),
      ...segment,
      ...otherPhoto.sublist(2),
    ]);

    expect(GeoStampSigner.verify(forged).failure, GeoStampFailure.tampered);
  });

  test('mengubah byte citra membuat tanda tidak sah', () {
    final signed = GeoStampSigner.embed(_jpeg(), _stamp);
    final altered = Uint8List.fromList(signed);
    altered[altered.length - 20] ^= 0xFF;
    expect(GeoStampSigner.verify(altered).failure, GeoStampFailure.tampered);
  });

  test('mengubah isi data geotag (mis. koordinat) tidak sah', () {
    final signed = GeoStampSigner.embed(_jpeg(), _stamp);
    final text = String.fromCharCodes(signed);
    // Ganti satu karakter di dalam payload tanda.
    final index =
        text.indexOf('SATURUMAH-GEO1:') + 'SATURUMAH-GEO1:'.length + 5;
    final altered = Uint8List.fromList(signed);
    altered[index] = altered[index] == 0x41 ? 0x42 : 0x41;
    expect(GeoStampSigner.verify(altered).isValid, isFalse);
  });

  test('menanam ulang mengganti tanda lama, bukan menumpuk', () {
    final first = GeoStampSigner.embed(_jpeg(), _stamp);
    final second = GeoStampSigner.embed(
      first,
      GeoStamp(
        latitude: -7.0,
        longitude: 108.0,
        capturedAt: DateTime.utc(2026, 10, 21),
      ),
    );
    final result = GeoStampSigner.verify(second);
    expect(result.isValid, isTrue);
    expect(result.stamp!.latitude, -7.0);
    expect(String.fromCharCodes(second).split('SATURUMAH-GEO1:').length, 2);
  });
}
