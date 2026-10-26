import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../bantuan/presentation/screens/pusat_bantuan_screen.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';

enum VerificationStatus { verified, pending }

/// Badge status verifikasi perusahaan sesuai visual Google Stitch.
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
            size: 13,
            color: Color(0xFF6EE7B7), // emerald-300
          ),
          SizedBox(width: 4),
          Text(
            'Terverifikasi',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Color(0xFF6EE7B7), // emerald-300
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
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

    // Sumber data identitas pengembang existing
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
            // 1. Header Merah Kanonis & Overlapping Stats Card
            _buildHeaderAndStats(
              companyName: companyName,
              developerId: developerId,
              status: verificationStatus,
              total: total,
              dalamProses: dalamProses,
              selesai: selesai,
            ),

            // 2. Konten Tubuh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Section Data Akun & Perusahaan
                  _buildSectionHeader('Data Akun & Perusahaan'),
                  const SizedBox(height: 8),
                  _buildAccountCard(),

                  const SizedBox(height: 20),

                  // Section Pengaturan & Bantuan
                  _buildSectionHeader('Pengaturan & Bantuan'),
                  const SizedBox(height: 8),
                  _buildMenuCard(context),

                  const SizedBox(height: 24),

                  // Tombol Keluar Akun
                  _buildLogoutButton(context, ref),

                  const SizedBox(height: 28),

                  // Footer Aplikasi & Instansi
                  _buildFooter(),

                  // Safe spacing agar footer tidak tertutup FAB / bottom navigation
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Merah dengan sudut bawah 44dp dan Card Statistik yang overlap 32dp.
  Widget _buildHeaderAndStats({
    required String companyName,
    required String developerId,
    required VerificationStatus status,
    required int total,
    required int dalamProses,
    required int selesai,
  }) {
    return Stack(
      children: [
        // Background Header Gradient dengan rounded bottom 44dp
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 32,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF881337), // rose-900 / primaryDark
                  Color(0xFF991B1B), // red-800 / primaryDarkAlt
                  Color(0xFFB91C1C), // red-700 / primaryRed
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(44),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),

        // Konten Header dan Overlapping Stats Card
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    // Judul kecil "Profil Pengembang" di tengah
                    Text(
                      'Profil Pengembang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar Perusahaan (80dp)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(companyName),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Color(0xFF881337),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama Perusahaan
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        companyName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Developer ID
                    Text(
                      'ID: $developerId',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Color(0xFFFEE2E2), // red-100
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Badge Verifikasi
                    if (status == VerificationStatus.verified)
                      const VerifiedBadge(
                        status: VerificationStatus.verified,
                        inHeader: true,
                      ),
                  ],
                ),
              ),
            ),

            // Card Statistik Putih yang overlap 32dp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsCard(
                total: total,
                dalamProses: dalamProses,
                selesai: selesai,
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)), // slate-100
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05), // shadow-soft
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: total,
            label: 'Total Pengajuan',
            valueColor: const Color(0xFF1E293B), // slate-800
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFF1F5F9), // divide-slate-100
          ),
          _buildStatItem(
            value: dalamProses,
            label: 'Dalam Proses',
            valueColor: const Color(0xFFF59E0B), // amber-500
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFF1F5F9), // divide-slate-100
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
                color: Color(0xFF64748B), // slate-500
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
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B), // slate-500
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
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
              borderRadius: BorderRadius.circular(12), // rounded-xl
              border: Border.all(color: const Color(0xFFF1F5F9)), // slate-100
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8), // slate-400
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B), // slate-800
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: const Color(0xFF64748B), // slate-500
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B), // slate-800
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
      color: const Color(0xFFFEF2F2), // red-50
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
              color: const Color(0xFFFECACA), // red-200
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.signOut,
                color: Color(0xFFDC2626), // red-600
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Keluar Akun',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626), // red-600
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
            fontSize: 10,
            color: Color(0xFF94A3B8), // slate-400
            height: 1.4,
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
