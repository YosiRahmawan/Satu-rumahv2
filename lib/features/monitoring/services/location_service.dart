import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Posisi perangkat pada satu saat.
class LocationFix {
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
}

/// Mengapa posisi tidak bisa didapat.
enum LocationFailure {
  /// Layanan lokasi (GPS) perangkat mati.
  serviceOff,

  /// Izin lokasi ditolak (masih bisa diminta lagi).
  denied,

  /// Izin lokasi ditolak permanen; harus dibuka lewat pengaturan.
  deniedForever,

  /// Tidak mendapat posisi dalam batas waktu.
  timeout,

  /// Posisi ditandai palsu (mock location).
  mocked,

  unknown,
}

class LocationResult {
  final LocationFix? fix;
  final LocationFailure? failure;

  const LocationResult.success(LocationFix this.fix) : failure = null;
  const LocationResult.failure(LocationFailure this.failure) : fix = null;

  bool get isSuccess => fix != null;
}

/// Sumber posisi. Dipisahkan agar layar kamera dapat diuji tanpa GPS asli.
abstract class LocationService {
  Future<LocationResult> currentFix({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Membuka pengaturan aplikasi (untuk izin yang ditolak permanen).
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> currentFix({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailure.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.deniedForever);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      if (position.isMocked) {
        return const LocationResult.failure(LocationFailure.mocked);
      }
      return LocationResult.success(
        LocationFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
      );
    } on TimeoutException {
      return const LocationResult.failure(LocationFailure.timeout);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unknown);
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
