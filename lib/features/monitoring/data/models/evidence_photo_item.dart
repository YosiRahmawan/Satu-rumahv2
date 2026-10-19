import 'dart:math';

/// Asal foto: diambil lewat kamera, dipilih dari galeri, atau tidak diketahui
/// (data lama yang hanya menyimpan path).
enum PhotoOrigin { camera, gallery, unknown }

/// Cara lokasi foto ditetapkan oleh petugas. Ketiganya sengaja dibedakan:
/// GPS saat input tidak boleh diklaim sebagai GPS saat pemotretan.
enum LocationMethod { exifConfirmed, manualPin, deviceAtEntry }

enum UploadStatus { localOnly, queued, uploading, uploaded, failed }

/// Koordinat asli yang tertanam di berkas foto (EXIF). Tidak pernah ditimpa.
class ExifGeo {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime? capturedAt;

  const ExifGeo({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.capturedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is ExifGeo &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitude == altitude &&
      other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(latitude, longitude, altitude, capturedAt);
}

/// Posisi perangkat saat foto dimasukkan ke aplikasi. Bukan lokasi pemotretan.
class DeviceFix {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime recordedAt;
  final bool? isMocked;

  const DeviceFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    this.isMocked,
  });

  @override
  bool operator ==(Object other) =>
      other is DeviceFix &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyMeters == accuracyMeters &&
      other.recordedAt == recordedAt &&
      other.isMocked == isMocked;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, accuracyMeters, recordedAt, isMocked);
}

/// Lokasi yang dipilih petugas untuk foto ini.
class OfficerLocation {
  final double latitude;
  final double longitude;
  final LocationMethod method;
  final DateTime selectedAt;
  final double? accuracyMeters;
  final String? clarificationNote;

  const OfficerLocation({
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.selectedAt,
    this.accuracyMeters,
    this.clarificationNote,
  });

  @override
  bool operator ==(Object other) =>
      other is OfficerLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.method == method &&
      other.selectedAt == selectedAt &&
      other.accuracyMeters == accuracyMeters &&
      other.clarificationNote == clarificationNote;

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    method,
    selectedAt,
    accuracyMeters,
    clarificationNote,
  );
}

/// Satu foto dokumentasi beserta metadata-nya.
///
/// [exif], [deviceFix], dan [location] disimpan terpisah dan tidak saling
/// mengisi: foto lama atau foto tanpa EXIF tetap tanpa koordinat sampai
/// petugas menentukannya.
class EvidencePhotoItem {
  /// UUID v4 yang stabil sejak foto ditambahkan.
  final String id;

  /// Referensi berkas lokal; sama dengan elemen `photoPaths` lama.
  final String localRef;

  /// Path di storage privat setelah diunggah; null sebelum itu.
  final String? storageKey;
  final UploadStatus uploadStatus;
  final PhotoOrigin origin;
  final DateTime addedAt;
  final String? caption;
  final ExifGeo? exif;
  final DeviceFix? deviceFix;
  final OfficerLocation? location;

  EvidencePhotoItem({
    required this.id,
    required this.localRef,
    this.storageKey,
    this.uploadStatus = UploadStatus.localOnly,
    this.origin = PhotoOrigin.unknown,
    DateTime? addedAt,
    this.caption,
    this.exif,
    this.deviceFix,
    this.location,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Membungkus path tanpa metadata (data lama atau foto baru dari picker).
  factory EvidencePhotoItem.fromPath(
    String path, {
    PhotoOrigin origin = PhotoOrigin.unknown,
    DateTime? addedAt,
  }) {
    return EvidencePhotoItem(
      id: newId(),
      localRef: path,
      origin: origin,
      addedAt: addedAt,
    );
  }

  static List<EvidencePhotoItem> fromPaths(List<String> paths) => [
    for (final path in paths) EvidencePhotoItem.fromPath(path),
  ];

  /// Menyelaraskan daftar item dengan daftar path hasil `updatePhotos`.
  ///
  /// Item yang `localRef`-nya masih ada dipertahankan lengkap dengan
  /// metadatanya; path baru dibungkus tanpa koordinat; item yang hilang dari
  /// daftar dibuang. Urutan mengikuti [paths].
  static List<EvidencePhotoItem> reconcile(
    List<EvidencePhotoItem> existing,
    List<String> paths,
  ) {
    final remaining = List<EvidencePhotoItem>.of(existing);
    final result = <EvidencePhotoItem>[];
    for (final path in paths) {
      final index = remaining.indexWhere((item) => item.localRef == path);
      if (index == -1) {
        result.add(EvidencePhotoItem.fromPath(path));
      } else {
        result.add(remaining.removeAt(index));
      }
    }
    return result;
  }

  bool get hasLocation => location != null;

  EvidencePhotoItem copyWith({
    String? storageKey,
    UploadStatus? uploadStatus,
    PhotoOrigin? origin,
    String? caption,
    ExifGeo? exif,
    DeviceFix? deviceFix,
    OfficerLocation? location,
    bool clearLocation = false,
  }) {
    return EvidencePhotoItem(
      id: id,
      localRef: localRef,
      storageKey: storageKey ?? this.storageKey,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      origin: origin ?? this.origin,
      addedAt: addedAt,
      caption: caption ?? this.caption,
      exif: exif ?? this.exif,
      deviceFix: deviceFix ?? this.deviceFix,
      location: clearLocation ? null : (location ?? this.location),
    );
  }

  /// Sidik ringkas untuk mendeteksi perubahan isian yang belum disimpan.
  String get signature => [
    id,
    localRef,
    storageKey ?? '',
    uploadStatus.name,
    caption ?? '',
    exif == null ? '' : '${exif!.latitude},${exif!.longitude}',
    deviceFix == null ? '' : '${deviceFix!.latitude},${deviceFix!.longitude}',
    location == null
        ? ''
        : '${location!.latitude},${location!.longitude},'
              '${location!.method.name},${location!.clarificationNote ?? ''}',
  ].join('|');

  @override
  bool operator ==(Object other) =>
      other is EvidencePhotoItem &&
      other.id == id &&
      other.localRef == localRef &&
      other.storageKey == storageKey &&
      other.uploadStatus == uploadStatus &&
      other.origin == origin &&
      other.addedAt == addedAt &&
      other.caption == caption &&
      other.exif == exif &&
      other.deviceFix == deviceFix &&
      other.location == location;

  @override
  int get hashCode => Object.hash(
    id,
    localRef,
    storageKey,
    uploadStatus,
    origin,
    addedAt,
    caption,
    exif,
    deviceFix,
    location,
  );

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
