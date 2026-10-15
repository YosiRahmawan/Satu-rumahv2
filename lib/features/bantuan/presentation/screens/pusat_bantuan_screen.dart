import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/kontak_layanan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/panduan_pengajuan_dialog.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/screens/template_berkas_screen.dart';

/// Layar Pusat Bantuan resmi untuk Pengembang — SATU RUMAH V2
class PusatBantuanScreen extends StatelessWidget {
  const PusatBantuanScreen({super.key});

  Future<void> _launchExternalUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAlurStatusBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: AppRadii.pill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alur & Status Pengajuan',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tahapan verifikasi dan status resmi pengajuan perumahan.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: StatusTahapPengajuan.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final tahap = StatusTahapPengajuan.values[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCanvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tahap.backgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tahap.icon,
                                  color: tahap.color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tahap ${index + 1}',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tahap.label,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. HEADER MERAH SATU RUMAH V2 ──────────────────────────────
            _buildHeader(context),

            // ─── 2. KONTEN KARTU OVERLAP ─────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAGIAN 1: KARTU KONTAK LAYANAN
                    _buildKontakCard(),

                    const SizedBox(height: 20),

                    // BAGIAN 2: PANDUAN
                    _buildSectionTitle('Panduan'),
                    const SizedBox(height: 10),
                    _buildPanduanCard(context),

                    const SizedBox(height: 20),

                    // BAGIAN 3: PERTANYAAN UMUM
                    _buildSectionTitle('Pertanyaan umum'),
                    const SizedBox(height: 10),
                    _buildFaqCard(context),

                    const SizedBox(height: 12),

                    // CATATAN KECIL DI BAWAH
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Kontak layanan dan jawaban pertanyaan umum akan diisi setelah '
                        'divalidasi Disperwaskim. Selama belum ada, '
                        'ditampilkan "Belum tersedia".',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Back button and SATU RUMAH title
          Row(
            children: [
              Semantics(
                label: 'Kembali',
                button: true,
                child: InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      try {
                        context.go('/dashboard');
                      } catch (_) {}
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'SATU RUMAH',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Pusat Bantuan',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Panduan dan kontak layanan $namaInstansi',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildKontakCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildKontakRow(
              icon: Icons.phone_outlined,
              title: 'Telepon',
              subtitle: 'Hubungi petugas layanan',
              value: KontakLayanan.nomorTelepon,
              onTap: KontakLayanan.nomorTelepon == null
                  ? null
                  : () => _launchExternalUrl('tel:${KontakLayanan.nomorTelepon}'),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildKontakRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'WhatsApp',
              subtitle: 'Tanya jawab singkat',
              value: KontakLayanan.nomorWhatsApp,
              onTap: KontakLayanan.nomorWhatsApp == null
                  ? null
                  : () => _launchExternalUrl(
                        'https://wa.me/${KontakLayanan.nomorWhatsApp}',
                      ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildKontakRow(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              subtitle: 'Kirim pertanyaan tertulis',
              value: KontakLayanan.email,
              onTap: KontakLayanan.email == null
                  ? null
                  : () => _launchExternalUrl('mailto:${KontakLayanan.email}'),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildKontakRow(
              icon: Icons.access_time_rounded,
              title: 'Jam layanan',
              subtitle: 'Hari dan jam kerja',
              value: KontakLayanan.jamLayanan,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKontakRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? value,
    required VoidCallback? onTap,
  }) {
    final isClickable = onTap != null && value != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isClickable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (value == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: AppRadii.pill,
                  ),
                  child: const Text(
                    'Belum tersedia',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanduanCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildNavigationRow(
              icon: Icons.description_outlined,
              title: 'Panduan pengajuan',
              subtitle: 'Langkah mengisi dan mengirim berkas',
              onTap: () => PanduanPengajuanDialog.show(context),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildNavigationRow(
              icon: Icons.format_list_bulleted_rounded,
              title: 'Template berkas',
              subtitle: 'Daftar dan contoh dokumen persyaratan',
              onTap: () {
                try {
                  context.push('/template-berkas');
                } catch (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateBerkasScreen(),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildNavigationRow(
              icon: Icons.schedule_rounded,
              title: 'Alur dan status pengajuan',
              subtitle: 'Arti tiap tahap dan langkah berikutnya',
              onTap: () => _showAlurStatusBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildFaqItem(
              context: context,
              question: 'Dokumen apa saja yang wajib diunggah?',
              answer:
                  KontakLayanan.jawabanDokumenWajib ?? 'Jawaban belum tersedia',
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildFaqItem(
              context: context,
              question: 'Apa yang harus dilakukan jika berkas diminta diperbaiki?',
              answer:
                  KontakLayanan.jawabanPerbaikanBerkas ?? 'Jawaban belum tersedia',
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.dividerLine),
            _buildFaqItem(
              context: context,
              question: 'Bagaimana jadwal survei lapangan ditentukan?',
              answer:
                  KontakLayanan.jawabanJadwalSurvei ?? 'Jawaban belum tersedia',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        iconColor: AppColors.textTertiary,
        collapsedIconColor: AppColors.textTertiary,
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
