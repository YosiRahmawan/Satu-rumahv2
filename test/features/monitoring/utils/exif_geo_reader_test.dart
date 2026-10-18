import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/utils/exif_geo_reader.dart';

import 'exif_test_jpeg.dart';

IfdTag _ratios(List<Ratio> ratios) =>
    IfdTag(tag: 0, tagType: 'Ratio', printable: '', values: IfdRatios(ratios));

IfdTag _ref(String value) => IfdTag(
  tag: 0,
  tagType: 'ASCII',
  printable: value,
  values: IfdBytes.empty(),
);

Map<String, IfdTag> _gps({
  List<Ratio>? lat,
  List<Ratio>? lng,
  String latRef = 'S',
  String lngRef = 'E',
}) => {
  if (lat != null) 'GPS GPSLatitude': _ratios(lat),
  'GPS GPSLatitudeRef': _ref(latRef),
  if (lng != null) 'GPS GPSLongitude': _ratios(lng),
  'GPS GPSLongitudeRef': _ref(lngRef),
};

void main() {
  group('parseExifGeo', () {
    test('mengubah derajat-menit-detik menjadi desimal dengan arah S/E', () {
      final geo = parseExifGeo(
        _gps(
          lat: [Ratio(7, 1), Ratio(19, 1), Ratio(3864, 100)],
          lng: [Ratio(108, 1), Ratio(13, 1), Ratio(1452, 100)],
        ),
      );
      expect(geo, isNotNull);
      expect(geo!.latitude, closeTo(-7.3274, 1e-5));
      expect(geo.longitude, closeTo(108.2207, 1e-5));
    });

    test('arah N dan W memberi tanda yang sesuai', () {
      final geo = parseExifGeo(
        _gps(
          lat: [Ratio(10, 1), Ratio(0, 1), Ratio(0, 1)],
          lng: [Ratio(20, 1), Ratio(30, 1), Ratio(0, 1)],
          latRef: 'N',
          lngRef: 'W',
        ),
      );
      expect(geo!.latitude, 10);
      expect(geo.longitude, -20.5);
    });

    test('tanpa tag GPS menghasilkan null', () {
      expect(parseExifGeo({}), isNull);
      expect(parseExifGeo(_gps(lat: null, lng: null)), isNull);
    });

    test('hanya salah satu sumbu menghasilkan null', () {
      expect(
        parseExifGeo(_gps(lat: [Ratio(7, 1), Ratio(0, 1), Ratio(0, 1)])),
        isNull,
      );
    });

    test('penyebut nol, nilai negatif, atau rentang tak valid ditolak', () {
      expect(
        parseExifGeo(
          _gps(
            lat: [Ratio(7, 0), Ratio(0, 1), Ratio(0, 1)],
            lng: [Ratio(108, 1), Ratio(0, 1), Ratio(0, 1)],
          ),
        ),
        isNull,
      );
      expect(
        parseExifGeo(
          _gps(
            lat: [Ratio(95, 1), Ratio(0, 1), Ratio(0, 1)],
            lng: [Ratio(108, 1), Ratio(0, 1), Ratio(0, 1)],
          ),
        ),
        isNull,
      );
    });

    test('titik 0,0 dianggap GPS tidak terkunci', () {
      expect(
        parseExifGeo(
          _gps(
            lat: [Ratio(0, 1), Ratio(0, 1), Ratio(0, 1)],
            lng: [Ratio(0, 1), Ratio(0, 1), Ratio(0, 1)],
          ),
        ),
        isNull,
      );
    });
  });

  group('readExifGeo', () {
    test('membaca GPS dari JPEG sungguhan', () async {
      final geo = await readExifGeo(jpegWithGps());
      expect(geo, isNotNull);
      expect(geo!.latitude, closeTo(-7.3274, 1e-5));
      expect(geo.longitude, closeTo(108.2207, 1e-5));
    });

    test('byte kosong, sampah, atau tanpa EXIF menghasilkan null', () async {
      expect(await readExifGeo(Uint8List(0)), isNull);
      expect(await readExifGeo(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
      expect(
        await readExifGeo(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9])),
        isNull,
      );
    });
  });
}
