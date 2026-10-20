import 'dart:math';

import 'geo_stamp.dart';

/// Dari mana foto masuk ke laporan.
enum PhotoSource {
  /// Diambil langsung oleh kamera aplikasi.
  camera,

  /// Diimpor dari galeri; hanya diterima bila memuat tanda geotag yang sah.
  gallery,
}

/// Satu foto dokumentasi pada laporan. Isi fotonya (JPEG yang sudah
/// berwatermark) disimpan terpisah di `PhotoBytesCache`, dikunci dengan [id].
class ReportPhoto {
  final String id;
  final PhotoSource source;
  final GeoStamp stamp;
  final DateTime addedAt;

  /// Benar bila berkas foto tidak bisa dipulihkan dari draf tersimpan, jadi
  /// petugas harus memotret atau memilih ulang fotonya.
  final bool needsReselect;

  ReportPhoto({
    required this.id,
    required this.source,
    required this.stamp,
    DateTime? addedAt,
    this.needsReselect = false,
  }) : addedAt = addedAt ?? DateTime.now();

  factory ReportPhoto.create({
    required PhotoSource source,
    required GeoStamp stamp,
  }) => ReportPhoto(id: newId(), source: source, stamp: stamp);

  ReportPhoto copyWith({bool? needsReselect}) => ReportPhoto(
    id: id,
    source: source,
    stamp: stamp,
    addedAt: addedAt,
    needsReselect: needsReselect ?? this.needsReselect,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.name,
    'stamp': stamp.toJson(),
    'addedAt': addedAt.toIso8601String(),
    if (needsReselect) 'needsReselect': true,
  };

  /// Membaca satu foto dari JSON; null bila datanya rusak.
  static ReportPhoto? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final stamp = GeoStamp.fromJson(json['stamp']);
    if (id is! String || id.isEmpty || stamp == null) return null;
    final source = PhotoSource.values.where((s) => s.name == json['source']);
    return ReportPhoto(
      id: id,
      source: source.isEmpty ? PhotoSource.camera : source.first,
      stamp: stamp,
      addedAt: DateTime.tryParse('${json['addedAt']}'),
      needsReselect: json['needsReselect'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReportPhoto &&
      other.id == id &&
      other.source == source &&
      other.stamp == stamp &&
      other.addedAt == addedAt &&
      other.needsReselect == needsReselect;

  @override
  int get hashCode => Object.hash(id, source, stamp, addedAt, needsReselect);

  static final Random _random = Random.secure();

  /// UUID v4 tanpa paket tambahan.
  static String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
