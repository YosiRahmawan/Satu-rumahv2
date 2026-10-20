import 'dart:math';

/// Asal foto: diambil lewat kamera, dipilih dari galeri, atau tidak diketahui
/// (data lama yang hanya menyimpan path).
enum PhotoOrigin { camera, gallery, unknown }

/// Cara lokasi foto ditetapkan oleh petugas. Ketiganya sengaja dibedakan:
/// GPS saat input tidak boleh diklaim sebagai GPS saat pemotretan.
enum LocationMethod { exifConfirmed, manualPin, deviceAtEntry }

enum UploadStatus { localOnly, queued, uploading, uploaded, failed }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

double? _doubleOrNull(Object? value) => value is num ? value.toDouble() : null;

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

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (altitude != null) 'altitude': altitude,
    if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
  };

  static ExifGeo? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = _doubleOrNull(json['latitude']);
    final lng = _doubleOrNull(json['longitude']);
    if (lat == null || lng == null) return null;
    return ExifGeo(
      latitude: lat,
      longitude: lng,
      altitude: _doubleOrNull(json['altitude']),
      capturedAt: _dateOrNull(json['capturedAt']),
    );
  }

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

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'recordedAt': recordedAt.toIso8601String(),
    if (isMocked != null) 'isMocked': isMocked,
  };

  static DeviceFix? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = _doubleOrNull(json['latitude']);
    final lng = _doubleOrNull(json['longitude']);
    final acc = _doubleOrNull(json['accuracyMeters']);
    final at = _dateOrNull(json['recordedAt']);
    if (lat == null || lng == null || acc == null || at == null) return null;
    return DeviceFix(
      latitude: lat,
      longitude: lng,
      accuracyMeters: acc,
      recordedAt: at,
      isMocked: json['isMocked'] is bool ? json['isMocked'] as bool : null,
    );
  }

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

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'method': method.name,
    'selectedAt': selectedAt.toIso8601String(),
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    if (clarificationNote != null) 'clarificationNote': clarificationNote,
  };

  static OfficerLocation? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = _doubleOrNull(json['latitude']);
    final lng = _doubleOrNull(json['longitude']);
    final at = _dateOrNull(json['selectedAt']);
    if (lat == null || lng == null || at == null) return null;
    return OfficerLocation(
      latitude: lat,
      longitude: lng,
      method: _enumByName(
        LocationMethod.values,
        json['method'],
        LocationMethod.manualPin,
      ),
      selectedAt: at,
      accuracyMeters: _doubleOrNull(json['accuracyMeters']),
      clarificationNote: json['clarificationNote'] as String?,
    );
  }

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

  /// Benar bila berkas foto tidak bisa dipulihkan dari draf tersimpan, jadi
  /// petugas harus memilih ulang fotonya sebelum laporan dikirim.
  final bool needsReselect;

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
    this.needsReselect = false,
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
    bool? needsReselect,
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
      needsReselect: needsReselect ?? this.needsReselect,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'localRef': localRef,
    if (storageKey != null) 'storageKey': storageKey,
    'uploadStatus': uploadStatus.name,
    'origin': origin.name,
    'addedAt': addedAt.toIso8601String(),
    if (caption != null) 'caption': caption,
    if (exif != null) 'exif': exif!.toJson(),
    if (deviceFix != null) 'deviceFix': deviceFix!.toJson(),
    if (location != null) 'location': location!.toJson(),
    if (needsReselect) 'needsReselect': true,
  };

  /// Membaca satu foto dari JSON; null bila datanya rusak.
  static EvidencePhotoItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final ref = json['localRef'];
    if (id is! String || ref is! String || id.isEmpty) return null;
    return EvidencePhotoItem(
      id: id,
      localRef: ref,
      storageKey: json['storageKey'] as String?,
      uploadStatus: _enumByName(
        UploadStatus.values,
        json['uploadStatus'],
        UploadStatus.localOnly,
      ),
      origin: _enumByName(
        PhotoOrigin.values,
        json['origin'],
        PhotoOrigin.unknown,
      ),
      addedAt: _dateOrNull(json['addedAt']),
      caption: json['caption'] as String?,
      exif: ExifGeo.fromJson(json['exif']),
      deviceFix: DeviceFix.fromJson(json['deviceFix']),
      location: OfficerLocation.fromJson(json['location']),
      needsReselect: json['needsReselect'] == true,
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
    needsReselect ? 'reselect' : '',
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
      other.location == location &&
      other.needsReselect == needsReselect;

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
    needsReselect,
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
