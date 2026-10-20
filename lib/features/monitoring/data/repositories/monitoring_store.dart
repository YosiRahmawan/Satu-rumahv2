import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan laporan monitoring (draf dan final) beserta isi fotonya di
/// perangkat. Hanya mengurus data mentah; pengubahan dari dan ke model
/// dilakukan oleh `MonitoringRepository`.
abstract class MonitoringStore {
  const MonitoringStore();

  Future<List<Map<String, dynamic>>> loadReports();

  Future<void> saveReports(List<Map<String, dynamic>> reports);

  Future<Uint8List?> loadPhoto(String photoId);

  /// Menyimpan isi foto. Mengembalikan false bila ditolak karena melebihi
  /// batas penyimpanan; foto itu harus dipilih ulang setelah aplikasi dibuka
  /// kembali.
  Future<bool> savePhoto(String photoId, Uint8List bytes);

  Future<void> deletePhoto(String photoId);

  /// Id foto yang isinya saat ini tersimpan.
  Future<Set<String>> storedPhotoIds();
}

/// Batas total isi foto yang disimpan lewat SharedPreferences. Di web, data
/// ini masuk localStorage (sekitar 5 MB per situs), jadi batasnya sengaja kecil.
const int kStoredPhotoBudgetBytes = 3 * 1024 * 1024;

class SharedPrefsMonitoringStore extends MonitoringStore {
  final int photoBudgetBytes;

  const SharedPrefsMonitoringStore({
    this.photoBudgetBytes = kStoredPhotoBudgetBytes,
  });

  static const _reportsKey = 'monitoring_reports_v1';
  static const _photoIndexKey = 'monitoring_photo_index_v1';
  static String _photoKey(String id) => 'monitoring_photo_v1_$id';

  @override
  Future<List<Map<String, dynamic>>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) item,
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveReports(List<Map<String, dynamic>> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportsKey, jsonEncode(reports));
  }

  Future<Map<String, int>> _index(SharedPreferences prefs) async {
    final raw = prefs.getString(_photoIndexKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key as String: entry.value as int,
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> _writeIndex(SharedPreferences prefs, Map<String, int> index) =>
      prefs.setString(_photoIndexKey, jsonEncode(index));

  @override
  Future<Uint8List?> loadPhoto(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_photoKey(photoId));
    if (raw == null) return null;
    try {
      return base64Decode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<bool> savePhoto(String photoId, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final index = await _index(prefs);
    final others = index.entries
        .where((e) => e.key != photoId)
        .fold<int>(0, (sum, e) => sum + e.value);
    if (others + bytes.length > photoBudgetBytes) return false;
    try {
      final stored = await prefs.setString(
        _photoKey(photoId),
        base64Encode(bytes),
      );
      if (!stored) return false;
    } catch (_) {
      return false;
    }
    index[photoId] = bytes.length;
    await _writeIndex(prefs, index);
    return true;
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoKey(photoId));
    final index = await _index(prefs);
    if (index.remove(photoId) != null) await _writeIndex(prefs, index);
  }

  @override
  Future<Set<String>> storedPhotoIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (await _index(prefs)).keys.toSet();
  }
}

/// Penyimpanan di memori untuk tes.
class MemoryMonitoringStore extends MonitoringStore {
  final int photoBudgetBytes;
  List<Map<String, dynamic>> reports = [];
  final Map<String, Uint8List> photos = {};

  MemoryMonitoringStore({this.photoBudgetBytes = kStoredPhotoBudgetBytes});

  @override
  Future<List<Map<String, dynamic>>> loadReports() async => [
    for (final r in reports) jsonDecode(jsonEncode(r)) as Map<String, dynamic>,
  ];

  @override
  Future<void> saveReports(List<Map<String, dynamic>> value) async {
    reports = [
      for (final r in value) jsonDecode(jsonEncode(r)) as Map<String, dynamic>,
    ];
  }

  @override
  Future<Uint8List?> loadPhoto(String photoId) async => photos[photoId];

  @override
  Future<bool> savePhoto(String photoId, Uint8List bytes) async {
    final others = photos.entries
        .where((e) => e.key != photoId)
        .fold<int>(0, (sum, e) => sum + e.value.length);
    if (others + bytes.length > photoBudgetBytes) return false;
    photos[photoId] = bytes;
    return true;
  }

  @override
  Future<void> deletePhoto(String photoId) async => photos.remove(photoId);

  @override
  Future<Set<String>> storedPhotoIds() async => photos.keys.toSet();
}
