import 'dart:typed_data';

/// Isi foto dokumentasi yang sedang dipakai, dikunci dengan id
/// foto (`ReportPhoto.id`). Berada di memori; salinan yang bertahan
/// setelah aplikasi ditutup dikelola oleh `MonitoringStore`.
class PhotoBytesCache {
  PhotoBytesCache._();

  static final Map<String, Uint8List> _bytes = {};

  static Uint8List? get(String ref) => _bytes[ref];

  static bool contains(String ref) => _bytes.containsKey(ref);

  static void put(String ref, Uint8List bytes) {
    _bytes[ref] = bytes;
  }

  static void remove(String ref) {
    _bytes.remove(ref);
  }

  /// Hanya untuk tes.
  static void clear() => _bytes.clear();
}
