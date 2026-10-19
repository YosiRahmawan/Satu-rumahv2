import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_distance.dart';

OfficerLocation _loc(double lat, double lng, {double? accuracy}) =>
    OfficerLocation(
      latitude: lat,
      longitude: lng,
      method: LocationMethod.manualPin,
      selectedAt: DateTime(2026, 10, 20),
      accuracyMeters: accuracy,
    );

const _project = ProjectReference(latitude: -7.3274, longitude: 108.2207);

void main() {
  group('haversineMeters', () {
    test('titik yang sama berjarak nol', () {
      expect(haversineMeters(-7.3274, 108.2207, -7.3274, 108.2207), 0);
    });

    test('satu derajat lintang sekitar 111,19 km', () {
      final d = haversineMeters(0, 0, 1, 0);
      expect(d, closeTo(111195, 50));
    });

    test('satu derajat bujur di khatulistiwa sekitar 111,19 km', () {
      expect(haversineMeters(0, 0, 0, 1), closeTo(111195, 50));
    });

    test('simetris dan konsisten dengan jarak kecil (± 10 m)', () {
      final a = haversineMeters(-7.3274, 108.2207, -7.3279, 108.2207);
      final b = haversineMeters(-7.3279, 108.2207, -7.3274, 108.2207);
      expect(a, closeTo(b, 1e-9));
      expect(a, closeTo(55.6, 1));
    });

    test('jarak Tasikmalaya ke Bandung sekitar 90 km', () {
      final d = haversineMeters(-7.3274, 108.2207, -6.9175, 107.6191);
      expect(d / 1000, inInclusiveRange(75, 95));
    });
  });

  group('isValidLatLng', () {
    test('menerima rentang valid dan menolak di luar rentang', () {
      expect(isValidLatLng(-7.3, 108.2), isTrue);
      expect(isValidLatLng(90, 180), isTrue);
      expect(isValidLatLng(91, 0), isFalse);
      expect(isValidLatLng(0, -181), isFalse);
      expect(isValidLatLng(double.nan, 0), isFalse);
      expect(isValidLatLng(0, double.infinity), isFalse);
    });
  });

  group('evaluatePhotoProximity', () {
    test('tanpa lokasi petugas: noLocation', () {
      final result = evaluatePhotoProximity(
        location: null,
        reference: _project,
      );
      expect(result.status, ProximityStatus.noLocation);
      expect(result.distanceMeters, isNull);
    });

    test('tanpa titik proyek: noReference tanpa jarak', () {
      final result = evaluatePhotoProximity(
        location: _loc(-7.3274, 108.2207),
        reference: null,
      );
      expect(result.status, ProximityStatus.noReference);
      expect(result.distanceMeters, isNull);
    });

    test('dalam toleransi', () {
      final result = evaluatePhotoProximity(
        location: _loc(-7.32745, 108.2207),
        reference: _project,
      );
      expect(result.status, ProximityStatus.withinTolerance);
      expect(result.distanceMeters, lessThan(50));
    });

    test('di luar toleransi', () {
      final result = evaluatePhotoProximity(
        location: _loc(-7.3290, 108.2207),
        reference: _project,
      );
      expect(result.status, ProximityStatus.outsideTolerance);
      expect(result.distanceMeters, greaterThan(50));
    });

    test('batas tepat sama dengan toleransi masih dianggap dalam', () {
      final edge = haversineMeters(-7.3274, 108.2207, -7.3278, 108.2207);
      final result = evaluatePhotoProximity(
        location: _loc(-7.3278, 108.2207),
        reference: _project,
        toleranceMeters: edge,
      );
      expect(result.status, ProximityStatus.withinTolerance);
    });

    test('toleransi bisa diubah (parameter uji, bukan aturan tetap)', () {
      final loc = _loc(-7.3290, 108.2207);
      expect(
        evaluatePhotoProximity(location: loc, reference: _project).status,
        ProximityStatus.outsideTolerance,
      );
      expect(
        evaluatePhotoProximity(
          location: loc,
          reference: _project,
          toleranceMeters: 500,
        ).status,
        ProximityStatus.withinTolerance,
      );
    });

    test('akurasi dicatat terpisah dari jarak dan menandai akurasi rendah', () {
      final result = evaluatePhotoProximity(
        location: _loc(-7.32745, 108.2207, accuracy: 250),
        reference: _project,
      );
      expect(result.accuracyMeters, 250);
      expect(result.lowAccuracy, isTrue);
      expect(result.status, ProximityStatus.withinTolerance);

      final good = evaluatePhotoProximity(
        location: _loc(-7.32745, 108.2207, accuracy: 8),
        reference: _project,
      );
      expect(good.lowAccuracy, isFalse);
    });
  });
}
