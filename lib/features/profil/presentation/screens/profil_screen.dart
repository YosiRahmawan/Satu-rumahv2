import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../../bantuan/presentation/screens/pusat_bantuan_screen.dart';

const double profileCardOverlap = 0.0;

enum VerificationStatus { verified, pending }

/// Badge status verifikasi perusahaan.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.status = VerificationStatus.verified,
    this.inHeader = false,
  });

  final VerificationStatus status;
  final bool inHeader;

  @override
  Widget build(BuildContext context) {
    final verified = status == VerificationStatus.verified;
    if (!verified) return const SizedBox.shrink();

    if (inHeader) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x3310B981), // emerald-500/20
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0x4D34D399), // emerald-400/30
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 11,
              color: Color(0xFFA7F3D0), // emerald-200
            ),
            SizedBox(width: 4),
            Text(
              'Terverifikasi',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Color(0xFFA7F3D0), // emerald-200
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    const emeraldColor = Color(0xFF059669);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emeraldColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: emeraldColor.withValues(alpha: 0.28)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13, color: emeraldColor),
          SizedBox(width: 4),
          Text(
            'Terverifikasi',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: emeraldColor,
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
            // 1. Header Merah Kanonis dengan Corporate Identity Terintegrasi
            DeveloperHeader(
              pageTitle: 'Profil Pengembang',
              pageSubtitle: 'Kelola informasi perusahaan dan akun',
              showBrandBar: false,
              showAvatar: false,
              bottomPadding: 24,
              child: _buildHeaderIdentity(
                companyName: companyName,
                developerId: developerId,
                status: verificationStatus,
              ),
            ),

            // Konten tubuh (tanpa floating card / offset translate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 2. Ringkasan Statistik Horizontal (3 Kolom dengan Divider Halus)
                  _buildStatsCard(
                    total: total,
                    dalamProses: dalamProses,
                    selesai: selesai,
                  ),

                  const SizedBox(height: 20),

                  // 3. Section Data Akun & Perusahaan
                  _buildSectionHeader('Data Akun & Perusahaan'),
                  const SizedBox(height: 8),
                  _buildAccountCard(),

                  const SizedBox(height: 20),

                  // 4. Section Pengaturan & Bantuan
                  _buildSectionHeader('Pengaturan & Bantuan'),
                  const SizedBox(height: 8),
                  _buildMenuCard(context),

                  const SizedBox(height: 24),

                  // 5. Tombol Keluar Akun (Soft Red Outlined)
                  _buildLogoutButton(context, ref),

                  const SizedBox(height: 28),

                  // 6. Footer Institusi
                  _buildFooter(),

                  // Spacing ekstra di bawah agar konten tidak terpotong navbar
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIdentity({
    required String companyName,
    required String developerId,
    required VerificationStatus status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Initials Avatar: Lingkaran putih bersih dengan inisial merah maroon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(companyName),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Color(0xFF881337), // rose-900 / primaryDarkAlt
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Company Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                companyName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.textOnRed,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'ID: $developerId',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.textOnRed.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (status == VerificationStatus.verified)
                    const VerifiedBadge(
                      status: VerificationStatus.verified,
                      inHeader: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required int total,
    required int dalamProses,
    required int selesai,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: total,
            label: 'Total Pengajuan',
            valueColor: const Color(0xFF0F172A), // slate-900
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFF1F5F9), // slate-100 vertical divider
          ),
          _buildStatItem(
            value: dalamProses,
            label: 'Dalam Proses',
            valueColor: const Color(0xFFD97706), // amber-600
          ),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFF1F5F9), // slate-100 vertical divider
          ),
          _buildStatItem(
            value: selesai,
            label: 'Selesai',
            valueColor: const Color(0xFF059669), // emerald-600
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int value,
    required String label,
    required Color valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.slate500,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            color: Color(0xFFF1F5F9), // slate-100
            indent: 14,
            endIndent: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // slate-50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)), // slate-100
            ),
            child: Icon(icon, color: AppColors.slate500, size: 16),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8), // slate-400
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            color: Color(0xFFF1F5F9), // slate-100
            indent: 14,
            endIndent: 14,
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.lifebuoy,
            title: 'Pusat Bantuan',
            onTap: () {
              try {
                context.push('/bantuan');
              } catch (_) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PusatBantuanScreen()),
                );
              }
            },
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9), // slate-100
            indent: 14,
            endIndent: 14,
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.info,
            title: 'Tentang Aplikasi Satu Rumah',
            onTap: () => context.push('/tentang'),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF475569), // slate-600
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: Color(0xFF94A3B8), // slate-400
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
      color: const Color(0xFFFFF1F2), // rose-50
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _logout(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFECDD3), // rose-200
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.signOut,
                color: Color(0xFFBE123C), // rose-700
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Keluar Akun',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBE123C), // rose-700
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
          '${AppConfig.appName} • v${AppConfig.appVersion} (${AppConfig.appBuild})',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8), // slate-400
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            color: Color(0xFF94A3B8), // slate-400
            height: 1.3,
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
