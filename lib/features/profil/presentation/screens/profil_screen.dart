import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../../bantuan/presentation/screens/pusat_bantuan_screen.dart';

const double profileCardOverlap = 34.0;

enum VerificationStatus { verified, pending }

/// Badge status verifikasi perusahaan (gaya glass terang).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.status = VerificationStatus.verified});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final verified = status == VerificationStatus.verified;
    const emeraldColor = Color(0xFF059669);
    const amberColor = Color(0xFFF59E0B);
    const amberTextColor = Color(0xFFB45309);
    final color = verified ? emeraldColor : amberColor;
    final textColor = verified ? emeraldColor : amberTextColor;
    final label = verified ? 'Terverifikasi' : 'Menunggu Verifikasi';
    final icon = verified ? Icons.verified_rounded : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  static String _initials(String name) {
    final words = name
        .replaceFirst(RegExp(r'^(PT|CV)\.?\s+', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final second = words.length > 1 ? words[1][0] : '';
    return (words.first[0] + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengajuan = ref.watch(pengajuanListProvider);
    final total = pengajuan.length;
    final selesai = pengajuan
        .where((item) => item.statusTahap == StatusTahapPengajuan.selesai)
        .length;
    final dalamProses = total - selesai;

    // Sumber data identitas pengembang
    final companyName = pengajuan.isNotEmpty
        ? pengajuan.first.namaPt
        : 'PT. Tasik Indah Sentosa';
    const developerId = 'Dev-2026-082';
    const verificationStatus = VerificationStatus.verified;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Merah Kanonis
            const DeveloperHeader(
              pageTitle: 'Profil Pengembang',
              pageSubtitle: 'Kelola informasi perusahaan dan pengaturan akun',
              showAvatar: false,
              bottomPadding: 52,
            ),

            // Konten kartu yang overlap 34dp dengan header merah
            Transform.translate(
              offset: const Offset(0, -34), // profileCardOverlap = 34.0
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Card Identitas Pengembang (Badge verifikasi di atas nama PT, tanpa chip Aktif)
                    _buildIdentityCard(
                      companyName: companyName,
                      developerId: developerId,
                      status: verificationStatus,
                    ),

                    const SizedBox(height: 12),

                    // 3. Statistik (3 kolom: Total, Dalam Proses, Selesai)
                    _buildStatsCard(
                      total: total,
                      dalamProses: dalamProses,
                      selesai: selesai,
                    ),

                    const SizedBox(height: 20),

                    // 4. Section "Data Akun & Perusahaan"
                    _buildSectionHeader('Data Akun & Perusahaan'),
                    const SizedBox(height: 10),
                    _buildAccountCard(),

                    const SizedBox(height: 20),

                    // 5. Section "Pengaturan & Bantuan"
                    _buildSectionHeader('Pengaturan & Bantuan'),
                    const SizedBox(height: 10),
                    _buildMenuCard(context),

                    const SizedBox(height: 20),

                    // 6. Tombol "Keluar Akun"
                    _buildLogoutButton(context, ref),

                    const SizedBox(height: 20),

                    // 7. Footer
                    _buildFooter(),

                    // Spacing ekstra di bawah agar footer tidak tertutup bottom bar & docked FAB
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard({
    required String companyName,
    required String developerId,
    VerificationStatus status = VerificationStatus.verified,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              _initials(companyName),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.primaryDarkAlt,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VerifiedBadge(status: status),
                const SizedBox(height: 6),
                Text(
                  companyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $developerId',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required int total,
    required int dalamProses,
    required int selesai,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatBox(value: total, label: 'Total Pengajuan'),
          const SizedBox(width: 8),
          _buildStatBox(value: dalamProses, label: 'Dalam Proses'),
          const SizedBox(width: 8),
          _buildStatBox(value: selesai, label: 'Selesai'),
        ],
      ),
    );
  }

  Widget _buildStatBox({required int value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundCanvas,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: AppColors.slate800,
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAccountRow(
            icon: PhosphorIconsRegular.envelope,
            label: 'Email Terdaftar',
            value: 'tasikindah@developer.com',
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _buildAccountRow(
            icon: PhosphorIconsRegular.phone,
            label: 'No. Kontak Pengembang',
            value: '0812-9876-5432',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuRow(
            icon: PhosphorIconsRegular.briefcase,
            title: 'Profil Perusahaan & Dokumen NIB',
            onTap: () => showUnavailableAction(
              context,
              'Profil Perusahaan & Dokumen NIB',
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.lifebuoy,
            title: 'Pusat Bantuan',
            onTap: () {
              try {
                context.push('/bantuan');
              } catch (_) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PusatBantuanScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
            indent: 16,
            endIndent: 16,
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.info,
            title: 'Tentang Aplikasi Satu Rumah',
            onTap: () => showUnavailableAction(
              context,
              'Tentang Aplikasi Satu Rumah',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.primarySurfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _logout(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primarySurfaceBorder,
              width: 1.2,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.signOut,
                color: AppColors.primaryRed,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Keluar Akun',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'SATU RUMAH • v1.0.0 (Build 2026)',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Pengembang ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(roleSessionProvider.notifier).signOut();
              context.go('/login');
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

