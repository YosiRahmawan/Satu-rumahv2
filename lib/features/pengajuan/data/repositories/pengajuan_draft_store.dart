import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan draf form pengajuan di perangkat, satu draf per akun.
///
/// Hanya berisi JSON mentah; pengubahan dari dan ke state form dilakukan di
/// [PengajuanFormState]. Berkas yang dipilih tersimpan sebagai referensi
/// (nama atau path), bukan isi filenya.
class PengajuanDraftStore {
  const PengajuanDraftStore();

  static String _key(String owner) => 'pengajuan_draft_v1_$owner';

  Future<void> save(String owner, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(owner), jsonEncode(json));
  }

  /// Mengembalikan draf tersimpan, atau null bila belum ada atau rusak.
  Future<Map<String, dynamic>?> load(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(owner));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<bool> exists(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(owner));
  }

  Future<void> clear(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(owner));
  }
}
