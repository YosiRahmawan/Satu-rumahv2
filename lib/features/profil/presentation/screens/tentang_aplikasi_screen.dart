import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Layar "Tentang Aplikasi": identitas, versi, deskripsi singkat, peran
/// pengguna, dan pengembang. Isinya hanya yang sudah terkonfirmasi di
/// README dan design.md.
class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 32 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIdentity(),
                const SizedBox(height: 28),
                const Text(
                  'Aplikasi untuk mengajukan penyerahan prasarana, sarana, dan '
                  'utilitas umum (PSU) perumahan kepada Pemerintah Kota '
                  'Tasikmalaya, dari unggah berkas sampai Berita Acara.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 32),
                _sectionTitle('Cara kerjanya singkat'),
                const Text(
                  'Satu pengajuan melewati tiga peran secara berurutan.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 14),
                const _AlurSingkat(),
                const SizedBox(height: 32),
                _sectionTitle('Siapa yang memakai'),
                const _PeranCard(
                  icon: PhosphorIconsRegular.buildings,
                  title: 'Pengembang',
                  subtitle: 'Perusahaan yang menyerahkan PSU perumahan',
                  label: 'Di aplikasi ini, Anda bisa',
                  points: [
                    'Mengisi pengajuan dalam 5 langkah dan mengunggah berkas',
                    'Memantau status pengajuan dan membaca catatan perbaikan',
                    'Mengirim ulang berkas yang diminta diperbaiki',
                  ],
                ),
                const SizedBox(height: 12),
                const _PeranCard(
                  icon: PhosphorIconsRegular.sealCheck,
                  title: 'Admin Disperwaskim',
                  subtitle: 'Petugas dinas yang memproses pengajuan',
                  label: 'Tugasnya',
                  points: [
                    'Memeriksa berkas, lalu menyetujui, meminta perbaikan, atau menolak',
                    'Menjadwalkan survey dan menugaskan petugas lapangan',
                    'Mengelola alur persetujuan sampai selesai',
                  ],
                ),
                const SizedBox(height: 12),
                const _PeranCard(
                  icon: PhosphorIconsRegular.mapPin,
                  title: 'Tim Perwaskim Lapangan',
                  subtitle: 'Petugas yang turun langsung ke lokasi',
                  label: 'Tugasnya',
                  points: [
                    'Survey fisik PSU dan mencatat temuan di lapangan',
                    'Mengambil foto bukti',
                    'Menyusun Berita Acara hasil survey',
                  ],
                ),
                const SizedBox(height: 32),
                _sectionTitle('Dikembangkan oleh'),
                _card(const [
                  _InfoRow(
                    title: 'Diskominfo Kota Tasikmalaya',
                    subtitle: 'Bidang Aplikasi dan Informatika',
                  ),
                  _InfoRow(
                    title: 'Disperwaskim',
                    subtitle: 'Dinas Perumahan dan Permukiman',
                  ),
                ]),
                const SizedBox(height: 36),
                const Text(
                  '© 2025–2026 Pemerintah Kota Tasikmalaya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        24,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Kembali',
            button: true,
            child: InkWell(
              onTap: () => _back(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tentang aplikasi',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            PhosphorIconsRegular.house,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          AppConfig.appName,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sistem Aplikasi Terpadu Urusan Rumah',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.pill,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Text(
            AppConfig.versionLabel,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _card(List<_InfoRow> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dividerLine,
            indent: 16,
            endIndent: 16,
          ),
        );
      }
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empat langkah alur pengajuan, urutannya mengikuti README.
class _AlurSingkat extends StatelessWidget {
  const _AlurSingkat();

  static const _steps = [
    ('Pengembang', ' mengajukan berkas'),
    ('Admin Disperwaskim', ' memeriksa berkas dan menjadwalkan survey'),
    ('Tim Perwaskim Lapangan', ' survey lokasi dan menyusun Berita Acara'),
    ('Admin', ' mengelola persetujuan sampai selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < _steps.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.fromLTRB(10, 3, 0, 3),
            color: AppColors.borderSubtle,
          ),
        );
      }
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _steps[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: _steps[i].$2),
                  ],
                ),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

/// Kartu satu peran: siapa dia, lalu daftar tugasnya di aplikasi.
class _PeranCard extends StatelessWidget {
  const _PeranCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurfaceSoft,
                  borderRadius: AppRadii.control,
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < points.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      points[i],
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
