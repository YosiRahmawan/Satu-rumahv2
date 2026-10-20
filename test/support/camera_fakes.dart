import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/services/camera_gateway.dart';
import 'package:satu_rumah/features/monitoring/services/geocoding_service.dart';
import 'package:satu_rumah/features/monitoring/services/location_service.dart';
import 'package:satu_rumah/features/monitoring/services/photo_import.dart';
import 'package:satu_rumah/features/monitoring/services/stamp_renderer.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

/// JPEG kecil polos untuk bahan tes.
Uint8List plainJpeg({int width = 64, int height = 48}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(90, 140, 200));
  return Uint8List.fromList(img.encodeJpg(image));
}

class FakeCameraSession implements CameraSession {
  int captures = 0;
  bool disposed = false;

  @override
  double get aspectRatio => 3 / 4;

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.blueGrey);

  @override
  Future<Uint8List> capture() async {
    captures++;
    return plainJpeg();
  }

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeCameraGateway implements CameraGateway {
  final CameraFailure? failure;
  final FakeCameraSession session = FakeCameraSession();
  FakeCameraGateway({this.failure});

  @override
  Future<CameraSession> open() async {
    if (failure != null) throw CameraUnavailable(failure!);
    return session;
  }
}

class FakeLocationService implements LocationService {
  LocationResult result;
  int calls = 0;
  int settingsOpened = 0;

  FakeLocationService([LocationResult? result])
    : result =
          result ??
          const LocationResult.success(
            LocationFix(
              latitude: -7.3274,
              longitude: 108.2207,
              accuracyMeters: 8,
            ),
          );

  @override
  Future<LocationResult> currentFix({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    calls++;
    return result;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeGeocoding implements GeocodingService {
  final String? address;
  FakeGeocoding([this.address = 'Jl. Contoh No. 1, Tasikmalaya']);

  @override
  Future<String?> reverse(double latitude, double longitude) async => address;
}

class FakeMapThumbnail implements MapThumbnailProvider {
  @override
  Future<Uint8List?> thumbnail(double latitude, double longitude) async => null;
}

/// Pengganti renderer: tidak memakai dart:ui, cukup menanam tanda tangan.
Future<Uint8List> fakeRender({
  required Uint8List photoBytes,
  required GeoStamp stamp,
  Uint8List? map,
}) async => GeoStampSigner.embed(photoBytes, stamp);

class FakePhotoPicker implements PhotoPickerGateway {
  List<PickedPhotoFile> files;
  FakePhotoPicker([this.files = const []]);

  @override
  Future<List<PickedPhotoFile>> pickImages() async => files;
}

class GeoStampStub {
  static GeoStamp at(double lat, double lng, int minute) => GeoStamp(
    latitude: lat,
    longitude: lng,
    capturedAt: DateTime.utc(2026, 10, 20, 2, minute),
  );
}
