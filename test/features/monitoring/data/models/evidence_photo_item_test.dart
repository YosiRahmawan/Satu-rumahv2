import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';

OfficerLocation _pin(double lat, double lng) => OfficerLocation(
  latitude: lat,
  longitude: lng,
  method: LocationMethod.manualPin,
  selectedAt: DateTime(2026, 10, 20, 9),
);

MonitoringModel _model({
  List<String>? photoPaths,
  List<EvidencePhotoItem>? photos,
}) {
  return MonitoringModel(
    id: 'm-1',
    tanggalMonitoring: DateTime(2026, 10, 20),
    namaPerumahan: 'Perumahan Uji',
    photoPaths: photoPaths,
    photos: photos,
  );
}

void main() {
  group('EvidencePhotoItem', () {
    test('foto dari path lama tidak memiliki koordinat apa pun', () {
      final photo = EvidencePhotoItem.fromPath('lama.jpg');

      expect(photo.localRef, 'lama.jpg');
      expect(photo.exif, isNull);
      expect(photo.deviceFix, isNull);
      expect(photo.location, isNull);
      expect(photo.hasLocation, isFalse);
      expect(photo.origin, PhotoOrigin.unknown);
      expect(photo.uploadStatus, UploadStatus.localOnly);
      expect(photo.storageKey, isNull);
    });

    test('ID berformat UUID v4 dan unik', () {
      final ids = {for (var i = 0; i < 1000; i++) EvidencePhotoItem.newId()};

      expect(ids.length, 1000);
      final uuidV4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(ids.every(uuidV4.hasMatch), isTrue);
    });

    test('EXIF, GPS saat input, dan lokasi petugas saling terpisah', () {
      final exifOnly = EvidencePhotoItem.fromPath(
        'a.jpg',
      ).copyWith(exif: const ExifGeo(latitude: -7.3, longitude: 108.2));
      final deviceOnly = EvidencePhotoItem.fromPath('b.jpg').copyWith(
        deviceFix: DeviceFix(
          latitude: -7.31,
          longitude: 108.21,
          accuracyMeters: 12,
          recordedAt: DateTime(2026, 10, 20, 9),
        ),
      );

      // Koordinat tidak otomatis menjadi lokasi pilihan petugas.
      expect(exifOnly.exif, isNotNull);
      expect(exifOnly.deviceFix, isNull);
      expect(exifOnly.location, isNull);
      expect(deviceOnly.deviceFix, isNotNull);
      expect(deviceOnly.exif, isNull);
      expect(deviceOnly.location, isNull);
    });

    test('copyWith mempertahankan identitas dan bisa menghapus lokasi', () {
      final original = EvidencePhotoItem.fromPath(
        'a.jpg',
        origin: PhotoOrigin.camera,
      );
      final located = original.copyWith(location: _pin(-7.3, 108.2));

      expect(located.id, original.id);
      expect(located.localRef, original.localRef);
      expect(located.addedAt, original.addedAt);
      expect(located.origin, PhotoOrigin.camera);
      expect(located.location!.method, LocationMethod.manualPin);

      final cleared = located.copyWith(clearLocation: true);
      expect(cleared.location, isNull);
      expect(cleared.id, original.id);
    });

    test('reconcile mempertahankan metadata, menambah, dan membuang', () {
      final a = EvidencePhotoItem.fromPath(
        'a.jpg',
      ).copyWith(location: _pin(-7.3, 108.2));
      final b = EvidencePhotoItem.fromPath('b.jpg');

      final result = EvidencePhotoItem.reconcile(
        [a, b],
        ['b.jpg', 'a.jpg', 'c.jpg'],
      );

      expect(result.map((p) => p.localRef), ['b.jpg', 'a.jpg', 'c.jpg']);
      expect(result[0], same(b));
      expect(result[1], same(a));
      expect(result[1].location, isNotNull);
      expect(result[2].location, isNull);

      final removed = EvidencePhotoItem.reconcile(result, ['a.jpg']);
      expect(removed.single, same(a));
    });

    test(
      'reconcile memberi ID berbeda pada path ganda dan menjaga path kosong',
      () {
        final result = EvidencePhotoItem.reconcile(const [], [
          'x.jpg',
          '',
          'x.jpg',
        ]);

        expect(result.map((p) => p.localRef), ['x.jpg', '', 'x.jpg']);
        expect(result.map((p) => p.id).toSet().length, 3);
      },
    );
  });

  group('MonitoringModel kompatibilitas photoPaths', () {
    test('data lama dengan photoPaths dibaca tanpa koordinat palsu', () {
      final model = _model(photoPaths: ['a.jpg', 'b.jpg']);

      expect(model.photoPaths, ['a.jpg', 'b.jpg']);
      expect(model.photos.length, 2);
      expect(
        model.photos.every((p) => p.location == null && p.exif == null),
        isTrue,
      );
    });

    test('tanpa foto sama sekali tetap valid', () {
      final model = _model();

      expect(model.photoPaths, isEmpty);
      expect(model.photos, isEmpty);
    });

    test('photos menang bila photoPaths dan photos sama-sama diberikan', () {
      final item = EvidencePhotoItem.fromPath('baru.jpg');
      final model = _model(photoPaths: ['lama.jpg'], photos: [item]);

      expect(model.photoPaths, ['baru.jpg']);
    });

    test('copyWith tanpa argumen foto mempertahankan item yang sama', () {
      final item = EvidencePhotoItem.fromPath(
        'a.jpg',
      ).copyWith(location: _pin(-7.3, 108.2));
      final model = _model(photos: [item]);

      final copy = model.copyWith(namaPerumahan: 'Lain');

      expect(copy.photos.single, same(item));
    });

    test('copyWith(photoPaths) mempertahankan metadata foto yang sama', () {
      final a = EvidencePhotoItem.fromPath(
        'a.jpg',
      ).copyWith(location: _pin(-7.3, 108.2));
      final model = _model(photos: [a]);

      final added = model.copyWith(photoPaths: ['a.jpg', 'b.jpg']);
      expect(added.photos[0], same(a));
      expect(added.photos[1].location, isNull);

      final removed = added.copyWith(photoPaths: ['b.jpg']);
      expect(removed.photoPaths, ['b.jpg']);
    });

    test('copyWith(photos) mengganti daftar foto', () {
      final model = _model(photoPaths: ['a.jpg']);
      final replacement = EvidencePhotoItem.fromPath('z.jpg');

      final copy = model.copyWith(photos: [replacement]);

      expect(copy.photoPaths, ['z.jpg']);
    });
  });
}
