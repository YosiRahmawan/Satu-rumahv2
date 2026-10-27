import 'package:flutter/material.dart';

/// Ilustrasi maskot untuk kondisi kosong dan galat. Gambar berlatar
/// transparan, jadi aman di atas kanvas maupun kartu putih.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.asset, {super.key, this.width = 220});

  final String asset;
  final double width;

  static const jadwalSurvey = 'assets/images/jadwal_survey_empty.png';
  static const unduhSkBa = 'assets/images/unduh_sk_empty.png';
  static const hasilSurvey = 'assets/images/hasil_survey_empty.png';
  static const galat = 'assets/images/error_umum.png';
  static const semuaBeres = 'assets/images/semua_beres.png';
  static const tugasLapangan = 'assets/images/tugas_lapangan_empty.png';
  static const fotoKosong = 'assets/images/foto_kosong.png';
  static const notifikasi = 'assets/images/notifikasi_kosong.png';

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: width,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true, // dekoratif; teks di bawahnya yang dibacakan
  );
}
