import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
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
    final unreadCount = ref.watch(unreadNotifikasiCountProvider);

    final completedSurveyCount =
        monitoring.where((item) => !item.isDraft).length;
    final needsEvaluationCount = monitoring
        .where(
          (item) =>
              !item.isDraft &&
              item.statusHasilEvaluasi != StatusHasilEvaluasi.sesuaiSiteplan,
        )
        .length;

    final identity = PerwaskimIdentity.fromSession(session);
    final assignment = assignments.isNotEmpty ? assignments.first : null;

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context: context,
              identity: identity,
              unreadCount: unreadCount,
              onNotificationsTap: () =>
                  context.push('/monitoring/lapangan/notifikasi'),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatsCard(
                      activeTasks: assignments.length,
                      completedSurveys: completedSurveyCount,
                      needEvaluation: needsEvaluationCount,
                    ),
                    const SizedBox(height: 16),
                    _buildAssignmentCard(context, assignment),
                    const SizedBox(height: 20),
                    _buildAccountInfoSection(identity, session),
                    const SizedBox(height: 20),
                    _buildSettingsSection(context),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, ref),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required PerwaskimIdentity identity,
    required int unreadCount,
    required VoidCallback onNotificationsTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.enterprisePrimary,
            AppColors.enterprisePrimaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          child: Column(
            children: [
              // Top Bar: Institution Badge & Notification Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'DINAS PERKIM KOTA TASIKMALAYA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Buka notifikasi ($unreadCount belum dibaca)',
                    child: InkWell(
                      onTap: onNotificationsTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8.5,
                                  height: 8.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.enterprisePrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Center Avatar with verified check badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        identity.initials,
                        style: const TextStyle(
                          color: AppColors.enterprisePrimaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.enterpriseSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                identity.nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // NIP
              Text(
                identity.nip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Role Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Tim Verifikator Perwaskim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              AppColors.enterprisePrimary,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppColors.enterpriseBorder,
          ),
          Expanded(
            child: _buildStatColumn(
              '$completedSurveys',
              'Survey Selesai',
              AppColors.enterpriseTextMain,
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppColors.enterpriseBorder,
          ),
          Expanded(
            child: _buildStatColumn(
              '$needEvaluation',
              'Perlu Evaluasi',
              AppColors.enterpriseWarning,
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
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Pengajuan? assignment) {
    final hasAssignment = assignment != null;
    final isToday = hasAssignment &&
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
          onTap: hasAssignment ? () => context.go('/monitoring/lapangan') : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 38,
                  decoration: BoxDecoration(
                    color: hasAssignment
                        ? AppColors.enterprisePrimary
                        : AppColors.enterpriseTextMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: hasAssignment
                                    ? AppColors.enterprisePrimary
                                    : AppColors.enterpriseTextMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasAssignment) ...[
                            const SizedBox(width: 5),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.enterprisePrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationText,
                        style: TextStyle(
                          color: hasAssignment
                              ? AppColors.enterpriseTextMain
                              : AppColors.enterpriseTextMuted,
                          fontSize: 14.5,
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
                const SizedBox(width: 8),
                Icon(
                  Icons.near_me_outlined,
                  color: hasAssignment
                      ? AppColors.enterprisePrimary
                      : AppColors.enterpriseTextMuted.withValues(alpha: 0.4),
                  size: 22,
                ),
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
        const SizedBox(height: 10),
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
                indent: 64,
              ),
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Nomor Kontak',
                value: 'Belum ditautkan',
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 64,
              ),
              _buildInfoRow(
                icon: Icons.apartment_outlined,
                label: 'Instansi Kerja',
                value: 'Dinas Perumahan & Kawasan Permukiman',
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 64,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Akun login',
                value: loginAccount,
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 64,
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
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.enterprisePrimarySurfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.enterprisePrimary,
            ),
          ),
          const SizedBox(width: 14),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.enterpriseTextMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.enterpriseBorder),
          ),
          child: Column(
            children: [
              _buildMenuRow(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                onTap: () => showUnavailableAction(context, 'Ubah Password'),
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 64,
              ),
              _buildMenuRow(
                icon: Icons.support_agent_outlined,
                title: 'Kontak Admin Kantor / Verifikator',
                onTap: () => showUnavailableAction(
                  context,
                  'Kontak Admin Kantor / Verifikator',
                ),
              ),
              const Divider(
                height: 1,
                color: AppColors.enterpriseBorder,
                indent: 64,
              ),
              _buildMenuRow(
                icon: Icons.menu_book_outlined,
                title: 'Panduan SOP Verifikasi Lapangan',
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.enterprisePrimarySurfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.enterprisePrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.enterpriseTextMain,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
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
        onPressed: () {
          ref.read(roleSessionProvider.notifier).signOut();
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
            Icon(
              Icons.logout,
              size: 19,
              color: AppColors.enterprisePrimary,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
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
                  color: AppColors.enterprisePrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              TextSpan(
                text: ' • v${AppConfig.appVersion} Production Build 2026',
                style: TextStyle(
                  color: AppColors.enterpriseTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3),
        Text(
          'Sistem Integrasi Perumahan & Kawasan Permukiman',
          style: TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
