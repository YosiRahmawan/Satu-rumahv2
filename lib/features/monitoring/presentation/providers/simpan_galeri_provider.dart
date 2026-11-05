import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan petugas: apakah salinan foto bergeotag ikut disimpan ke galeri HP. Bawaan menyala.
/// Foto resmi untuk BA selalu tersimpan di draf, apa pun pilihan ini.
class SimpanGaleriNotifier extends StateNotifier<bool> {
  SimpanGaleriNotifier() : super(true) {
    _muat();
  }

  static const kunci = 'simpan_foto_galeri';

  Future<void> _muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nilai = prefs.getBool(kunci);
      if (nilai != null && mounted) state = nilai;
    } catch (_) {
      // Tanpa penyimpanan: tetap memakai bawaan.
    }
  }

  Future<void> atur(bool aktif) async {
    state = aktif;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kunci, aktif);
    } catch (_) {
      // Pilihan berlaku selama aplikasi terbuka walau gagal disimpan.
    }
  }
}

final simpanGaleriProvider = StateNotifierProvider<SimpanGaleriNotifier, bool>(
  (ref) => SimpanGaleriNotifier(),
);
