import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/role_session.dart';

/// Data perusahaan pengembang yang dibuat Dinas bersama akunnya.
class DeveloperProfileData {
  final String nib;
  final String namaPerumahan;
  final String namaPt;
  final String namaDirektur;
  final String alamatPerumahan;
  final String alamatPt;
  final String noHpDirektur;
  final String emailPt;
  final String tipePengajuan;

  const DeveloperProfileData({
    this.nib = '',
    this.namaPerumahan = '',
    this.namaPt = '',
    this.namaDirektur = '',
    this.alamatPerumahan = '',
    this.alamatPt = '',
    this.noHpDirektur = '',
    this.emailPt = '',
    this.tipePengajuan = '',
  });

  factory DeveloperProfileData.fromJson(Map<String, dynamic> j) {
    String s(String k) => '${j[k] ?? ''}';
    return DeveloperProfileData(
      nib: s('nib'),
      namaPerumahan: s('nama_perumahan'),
      namaPt: s('nama_pt'),
      namaDirektur: s('nama_direktur'),
      alamatPerumahan: s('alamat_perumahan'),
      alamatPt: s('alamat_pt'),
      noHpDirektur: s('no_hp_direktur'),
      emailPt: s('email_pt'),
      tipePengajuan: s('tipe_pengajuan'),
    );
  }

  /// Label tipe pengajuan di form; kosong bila nilainya tidak dikenal.
  String get tipePengajuanLabel => switch (tipePengajuan) {
    'site_plan_baru' => 'Pengajuan Site Plan Baru',
    'perubahan_siteplan' => 'Perubahan Siteplan',
    'pengembangan_siteplan' => 'Pengembangan Siteplan',
    _ => '',
  };
}

/// Profil pengembang yang masuk, dari server. Null di mode contoh, untuk role
/// lain, atau bila profil belum dibuat Dinas. Berganti akun memuat ulang.
final developerProfileProvider = FutureProvider<DeveloperProfileData?>((
  ref,
) async {
  if (!ref.watch(apiEnabledProvider)) return null;
  final role = ref.watch(roleSessionProvider.select((s) => s.role));
  if (role != AppRole.developer) return null;
  try {
    final response = await ref
        .watch(apiDioProvider)
        .get<Map<String, dynamic>>('developer/profile');
    final data = response.data?['data'];
    return data is Map<String, dynamic>
        ? DeveloperProfileData.fromJson(data)
        : null;
  } on DioException {
    return null; // layar menampilkan "Belum tersedia"; dicoba lagi saat dibuka ulang
  }
});
