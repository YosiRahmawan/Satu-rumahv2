/// Data geotag sebuah foto dokumentasi, dicatat pada saat pemotretan.
///
/// Dicetak ke foto sebagai watermark dan ditanam (bertanda tangan) di dalam
/// berkas JPEG-nya sehingga foto bisa diperiksa ulang saat diimpor dari galeri.
class GeoStamp {
  final double latitude;
  final double longitude;

  /// Akurasi horizontal GPS dalam meter, bila perangkat melaporkannya.
  final double? accuracyMeters;

  /// Waktu pemotretan (waktu perangkat).
  final DateTime capturedAt;

  /// Alamat hasil geocoding; null bila offline atau layanan gagal.
  final String? address;

  /// Catatan petugas yang ikut dicetak pada foto.
  final String? note;

  const GeoStamp({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracyMeters,
    this.address,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    if (accuracyMeters != null) 'acc': accuracyMeters,
    't': capturedAt.toUtc().toIso8601String(),
    if (address != null) 'addr': address,
    if (note != null) 'note': note,
  };

  static GeoStamp? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    final t = DateTime.tryParse('${json['t']}');
    if (lat is! num || lng is! num || t == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return GeoStamp(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      accuracyMeters: json['acc'] is num
          ? (json['acc'] as num).toDouble()
          : null,
      capturedAt: t.toLocal(),
      address: json['addr'] as String?,
      note: json['note'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeoStamp &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyMeters == accuracyMeters &&
      other.capturedAt.toUtc() == capturedAt.toUtc() &&
      other.address == address &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    accuracyMeters,
    capturedAt.toUtc(),
    address,
    note,
  );
}
