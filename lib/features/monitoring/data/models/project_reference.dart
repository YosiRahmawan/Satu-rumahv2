/// Titik referensi proyek yang ditetapkan Pengembang. Hanya-baca bagi
/// Perwaskim: tidak ada kode di sisi monitoring yang mengubahnya.
class ProjectReference {
  final double latitude;
  final double longitude;

  /// Mis. "pin_peta", "gps_perangkat", "alamat".
  final String? source;

  const ProjectReference({
    required this.latitude,
    required this.longitude,
    this.source,
  });

  @override
  bool operator ==(Object other) =>
      other is ProjectReference &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.source == source;

  @override
  int get hashCode => Object.hash(latitude, longitude, source);
}
