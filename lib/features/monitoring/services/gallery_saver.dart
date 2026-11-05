import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

/// Menyalin foto bergeotag ke galeri HP (album "Satu Rumah") sebagai arsip pribadi petugas.
/// Gagal diam-diam: bukti resmi tetap tersimpan di draf BA.
abstract class GallerySaver {
  Future<bool> save(Uint8List bytes, String name);
}

class DeviceGallerySaver implements GallerySaver {
  const DeviceGallerySaver();

  @override
  Future<bool> save(Uint8List bytes, String name) async {
    if (kIsWeb) return false;
    try {
      if (!await Gal.hasAccess(toAlbum: true) &&
          !await Gal.requestAccess(toAlbum: true)) {
        return false;
      }
      await Gal.putImageBytes(bytes, album: 'Satu Rumah', name: name);
      return true;
    } catch (_) {
      return false;
    }
  }
}
