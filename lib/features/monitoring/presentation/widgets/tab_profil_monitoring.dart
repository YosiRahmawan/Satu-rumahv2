import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../profil/presentation/widgets/role_profile_view.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_list_provider.dart';

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
    final username = session.username?.trim();
    final displayName = username == null || username.isEmpty
        ? 'Akun Perwaskim'
        : username;
    final assignment = assignments.isEmpty ? null : assignments.first;

    return RoleProfileView(
      profileTitle: 'Profil Perwaskim',
      heroOrganizationLabel: 'Dinas Perkim Kota Tasikmalaya',
      displayName: displayName,
      roleLabel: session.role.label,
      initials: _initials(displayName),
      heroVariant: ProfileHeroVariant.enterpriseAuthority,
      stats: [
        ProfileStatData(
          '${assignments.length}',
          'Tugas Aktif',
          color: AppColors.enterprisePrimary,
        ),
        ProfileStatData(
          '$completedSurveyCount',
          'Survey Selesai',
          color: AppColors.enterpriseTextMain,
        ),
        ProfileStatData(
          '$needsEvaluationCount',
          'Perlu Evaluasi',
          color: AppColors.enterpriseWarning,
        ),
      ],
      assignmentSectionTitle: 'Penugasan Lapangan',
      assignment: assignment == null
          ? null
          : ProfileAssignmentData(
              projectName: assignment.namaPerumahan,
              developerName: assignment.namaPt,
              scheduleText: assignment.tanggalSurvey == null
                  ? 'Jadwal survey belum tersedia'
                  : 'Jadwal survey: ${DateFormat('d MMM yyyy').format(assignment.tanggalSurvey!)}',
              instructionText:
                  assignment.catatanSurvey?.trim().isNotEmpty == true
                  ? assignment.catatanSurvey!.trim()
                  : 'Belum ada instruksi tambahan dari admin.',
            ),
      accountSectionTitle: 'Informasi akun dinas',
      accountItems: [
        ProfileAccountItem(
          icon: PhosphorIconsRegular.userCircle,
          label: 'Akun login',
          value: username == null || username.isEmpty
              ? 'Belum tersedia'
              : username,
        ),
        ProfileAccountItem(
          icon: PhosphorIconsRegular.identificationBadge,
          label: 'Peran akses',
          value: session.role.label,
        ),
      ],
      menuItems: [
        ProfileMenuItem(
          icon: PhosphorIconsRegular.key,
          title: 'Ubah Password',
          onTap: () => showUnavailableAction(context, 'Ubah Password'),
        ),
        ProfileMenuItem(
          icon: PhosphorIconsRegular.question,
          title: 'Kontak Admin Kantor / Verifikator',
          onTap: () => showUnavailableAction(
            context,
            'Kontak Admin Kantor / Verifikator',
          ),
        ),
        ProfileMenuItem(
          icon: PhosphorIconsRegular.bookOpen,
          title: 'Panduan SOP Verifikasi Lapangan',
          onTap: () =>
              showUnavailableAction(context, 'Panduan SOP Verifikasi Lapangan'),
        ),
      ],
      onNotifications: () => context.go('/monitoring/lapangan/notifikasi'),
      onLogout: () {
        ref.read(roleSessionProvider.notifier).signOut();
        context.go('/login');
      },
      footerText: 'SATU RUMAH',
      banner: const SizedBox.shrink(),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'PW';
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length.clamp(1, 2)).toUpperCase();
  }
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
}
