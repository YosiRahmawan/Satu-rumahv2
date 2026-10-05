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

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengajuan = ref.watch(pengajuanListProvider);
    final total = pengajuan.length;
    final selesai = pengajuan
        .where((item) => item.statusTahap == StatusTahapPengajuan.selesai)
        .length;
    final dalamProses = total - selesai;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Merah
            const DeveloperHeader(
              pageTitle: 'Profil Pengembang',
              pageSubtitle: 'Kelola informasi perusahaan dan pengaturan akun',
              isVerified: true,
              showAvatar: false,
              bottomPadding: 40,
            ),

            // Konten kartu yang bertumpuk halus dengan header merah
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Card Identitas Pengembang
                    _buildIdentityCard(),

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

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar "TI"
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'TI',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkAlt,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nama & ID
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PT. Tasik Indah Sentosa',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  'ID: Dev-2026-082',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Badge "Aktif"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.statusSuccessText,
              ),
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
        color: Colors.white,
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('$total', 'Total Pengajuan'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatItem('$dalamProses', 'Dalam Proses'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatItem('$selesai', 'Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCanvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
        color: AppColors.slate700,
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        color: Colors.white,
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
            icon: PhosphorIconsRegular.clockCounterClockwise,
            title: 'Ubah Kata Sandi',
            onTap: () => showUnavailableAction(
              context,
              'Ubah Kata Sandi',
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
            title: 'Pusat Bantuan Disperwaskim',
            onTap: () => showUnavailableAction(
              context,
              'Pusat Bantuan Disperwaskim',
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

