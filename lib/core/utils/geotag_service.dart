/// Model koordinat GPS hasil geotagging foto dan survey lapangan.
class GeotagLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;
  final bool isMocked;

  const GeotagLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
    this.isMocked = false,
  });

  /// Format string siap tampil untuk laporan survey (contoh: "-7.3274, 108.2207 (Akurasi: ±4m)")
  String toDisplayString() {
    final acc = accuracy != null ? ' (±${accuracy!.toStringAsFixed(1)}m)' : '';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}$acc';
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
        'is_mocked': isMocked,
      };

  factory GeotagLocation.fromJson(Map<String, dynamic> json) {
    return GeotagLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isMocked: json['is_mocked'] == true,
    );
  }
}

/// Service untuk memeriksa izin lokasi, mendapatkan posisi GPS akurat,
/// serta mendeteksi indikasi Mock Location / Fake GPS.
class GeotagService {
  const GeotagService();

  /// Validasi apakah posisi terindikasi Fake GPS / Mock Location
  /// atau akurasi GPS terlalu rendah (> 50 meter)
  bool validatePositionIntegrity(GeotagLocation location) {
    if (location.isMocked) {
      return false; // Ditolak karena terdeteksi Fake GPS
    }
    if (location.accuracy != null && location.accuracy! > 50.0) {
      return false; // Akurasi terlalu rendah untuk audit fisik
    }
    return true;
  }

  /// Helper untuk membuat GeotagLocation dari nilai mentah perangkat
  GeotagLocation createGeotag({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
    bool isMocked = false,
  }) {
    return GeotagLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      timestamp: timestamp ?? DateTime.now(),
      isMocked: isMocked,
    );
  }
}

