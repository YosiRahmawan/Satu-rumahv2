import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/utils/koordinat_peta.dart';

void main() {
  test('membaca koordinat dari berbagai bentuk tautan Google Maps', () {
    expect(
      parseKoordinat(
        'https://www.google.com/maps/place/X/@-7.3274,108.2207,17z/data=abc',
      ),
      (lat: -7.3274, lng: 108.2207),
    );
    expect(
      parseKoordinat(
        'https://www.google.com/maps/search/?api=1&query=-7.3274,108.2207',
      ),
      (lat: -7.3274, lng: 108.2207),
    );
    expect(parseKoordinat('https://www.google.com/maps?q=-7.3274%2C108.2207'), (
      lat: -7.3274,
      lng: 108.2207,
    ));
    expect(
      parseKoordinat('https://maps.google.com/x/data=!3d-7.3274!4d108.2207'),
      (lat: -7.3274, lng: 108.2207),
    );
    expect(parseKoordinat('-7.3274, 108.2207'), (lat: -7.3274, lng: 108.2207));
  });

  test('menolak tautan pendek, teks biasa, dan koordinat di luar bumi', () {
    expect(parseKoordinat('https://maps.app.goo.gl/AbCdEf'), isNull);
    expect(parseKoordinat('Jl. Tamansari KM 4'), isNull);
    expect(parseKoordinat('95, 108'), isNull);
    expect(parseKoordinat(''), isNull);
  });
}
