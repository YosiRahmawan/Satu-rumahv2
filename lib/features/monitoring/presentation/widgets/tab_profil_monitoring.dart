import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_list_provider.dart';
import 'tab_beranda_monitoring.dart';

class TabProfilMonitoring extends ConsumerWidget {
  const TabProfilMonitoring({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoring = ref.watch(monitoringListProvider);
    final session = ref.watch(roleSessionProvider);
    final assignments = ref.watch(surveyAktifProvider);

    final completedSurveyCount = monitoring
        .where((item) => !item.isDraft)
        .length;
    final needsEvaluationCount = monitoring
        .where(
          (item) =>
              !item.isDraft &&
              item.statusHasilEvaluasi != StatusHasilEvaluasi.sesuaiSiteplan,
        )
        .length;

    final identity = PerwaskimIdentity.fromSession(session);
    final assignment = assignments.isNotEmpty ? assignments.first : null;

    final isVerified =
        session.isAuthenticated &&
        identity.nip.isNotEmpty &&
        !identity.nip.toLowerCase().contains('belum tersedia');

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderAndStats(
              context: context,
              identity: identity,
              isVerified: isVerified,
              activeTasks: assignments.length,
              completedSurveys: completedSurveyCount,
              needEvaluation: needsEvaluationCount,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildAssignmentCard(context, assignment),
                  const SizedBox(height: 20),
                  _buildAccountInfoSection(identity, session),
                  const SizedBox(height: 20),
                  _buildSettingsSection(context),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context, ref),
                  const SizedBox(height: 16),
                  _buildFooter(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndStats({
    required BuildContext context,
    required PerwaskimIdentity identity,
    required bool isVerified,
    required int activeTasks,
    required int completedSurveys,
    required int needEvaluation,
  }) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 36,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.enterprisePrimary,
                  AppColors.enterprisePrimaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
        ),
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  children: [
                    // Avatar: 68x68 white circle with bold red initials (no checkmark, no decorative rings)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        identity.initials,
                        style: const TextStyle(
                          color: AppColors.enterprisePrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      identity.nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // NIP
                    Text(
                      identity.nip,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Verification Badge
                    _buildVerificationBadge(isVerified),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsCard(
                activeTasks: activeTasks,
                completedSurveys: completedSurveys,
                needEvaluation: needEvaluation,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationBadge(bool isVerified) {
    if (!isVerified) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 13, color: Color(0xFFD97706)),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                'Belum Terverifikasi',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 13, color: Color(0xFF059669)),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              'Terverifikasi',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required int activeTasks,
    required int completedSurveys,
    required int needEvaluation,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatColumn(
              '$activeTasks',
              'Tugas Aktif',
              const Color(0xFF0F172A),
            ),
          ),
          Container(width: 1, height: 38, color: AppColors.enterpriseBorder),
          Expanded(
            child: _buildStatColumn(
              '$completedSurveys',
              'Survei Selesai',
              const Color(0xFFD97706),
            ),
          ),
          Container(width: 1, height: 38, color: AppColors.enterpriseBorder),
          Expanded(
            child: _buildStatColumn(
              '$needEvaluation',
              'Perlu Evaluasi',
              const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, Color countColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count,
            style: TextStyle(
              color: countColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.enterpriseTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Pengajuan? assignment) {
    final hasAssignment = assignment != null;
    final isToday =
        hasAssignment &&
        assignment.tanggalSurvey != null &&
        DateUtils.isSameDay(assignment.tanggalSurvey!, DateTime.now());
    final title = isToday
        ? 'PENUGASAN LAPANGAN HARI INI'
        : 'PENUGASAN LAPANGAN';
    final locationText = hasAssignment
        ? assignment.namaPerumahan
        : 'Belum ada penugasan lapangan aktif.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasAssignment
              ? () => context.go('/monitoring/lapangan')
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.enterpriseTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationText,
                        style: TextStyle(
                          color: hasAssignment
                              ? AppColors.enterpriseTextMain
                              : AppColors.enterpriseTextMuted,
                          fontSize: 14,
                          fontWeight: hasAssignment
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasAssignment) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.enterpriseTextMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(
    PerwaskimIdentity identity,
    RoleSessionState session,
  ) {
    final emailText = identity.email;
    final username = session.username?.trim();
    final loginAccount = username != null && username.isNotEmpty
        ? username
        : 'tim_monitoring_perwaskim';
    final roleText = session.role.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMASI AKUN DINAS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.enterpriseTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.enterpriseBorder),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.mail_outline,
                label: 'Email Resmi Dinas',
                value: emailText,
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 58,
              ),
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Nomor Kontak',
                value: 'Belum ditautkan',
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 58,
              ),
              _buildInfoRow(
                icon: Icons.apartment_outlined,
                label: 'Instansi Kerja',
                value: 'Dinas Perumahan & Kawasan Permukiman',
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 58,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Akun login',
                value: loginAccount,
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 58,
              ),
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: 'Peran akses',
                value: roleText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.enterpriseTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.enterpriseTextMain,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PENGATURAN & PANDUAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.enterpriseTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.enterpriseBorder),
          ),
          child: Column(
            children: [
              _buildMenuRow(
                icon: Icons.headset_mic_outlined,
                title: 'Hubungi Admin / CS',
                subtitle: 'Bantuan akun, NIP, dan reset password',
                onTap: () =>
                    showUnavailableAction(context, 'Hubungi Admin / CS'),
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 58,
              ),
              _buildMenuRow(
                icon: Icons.menu_book_outlined,
                title: 'Panduan SOP Verifikasi Lapangan',
                subtitle: 'Panduan pelaksanaan verifikasi lapangan',
                onTap: () => showUnavailableAction(
                  context,
                  'Panduan SOP Verifikasi Lapangan',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required String subtitle,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.enterpriseTextMain,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.enterpriseTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.enterpriseTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await performLogout(ref);
          if (context.mounted) {
            try {
              context.go('/login');
            } catch (_) {
              // Context might not be wrapped with GoRouter in isolated widget tests
            }
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: AppColors.enterprisePrimarySurfaceSoft,
          foregroundColor: AppColors.enterprisePrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.enterprisePrimaryBorder),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18, color: AppColors.enterprisePrimary),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.enterprisePrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: AppConfig.appName,
                style: TextStyle(
                  color: AppColors.enterpriseTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: ' • v${AppConfig.appVersion}',
                style: TextStyle(
                  color: AppColors.enterpriseTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2),
        Text(
          'Sistem Integrasi Perumahan & Kawasan Permukiman',
          style: TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
