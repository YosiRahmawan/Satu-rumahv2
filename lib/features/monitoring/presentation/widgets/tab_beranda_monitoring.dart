import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../data/models/monitoring_model.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';
import 'status_hasil_evaluasi_badge_widget.dart';

/// Helper model for Perwaskim identity resolution
class PerwaskimIdentity {
  final String nama;
  final String jabatan;
  final String nip;
  final String initials;
  final String email;

  const PerwaskimIdentity({
    required this.nama,
    required this.jabatan,
    required this.nip,
    required this.initials,
    this.email = 'rian.hidayat@tasikmalayakota.go.id',
  });

  factory PerwaskimIdentity.fromSession(RoleSessionState session) {
    final username = session.username?.trim();
    if (username != null && username.isNotEmpty) {
      if (username == 'tim_monitoring_perwaskim' ||
          username == 'perwaskim' ||
          username.contains('rian')) {
        return const PerwaskimIdentity(
          nama: 'Drs. Rian Hidayat, M.Si',
          jabatan: 'Tim Verifikator Lapangan (Perwaskim)',
          nip: 'NIP: 197805122006041008',
          initials: 'RH',
          email: 'rian.hidayat@tasikmalayakota.go.id',
        );
      }
      if (username.contains('budi')) {
        return const PerwaskimIdentity(
          nama: 'Budi Santoso, S.T.',
          jabatan: 'Tim Verifikator Lapangan (Perwaskim)',
          nip: 'NIP: 19880512 201503 1 002',
          initials: 'BS',
          email: 'budi.santoso@tasikmalayakota.go.id',
        );
      }
      final formattedName = username
          .split(RegExp(r'[_\s]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
      return PerwaskimIdentity(
        nama: formattedName,
        jabatan: session.role.label,
        nip: 'NIP: Belum tersedia',
        initials: _extractInitials(formattedName),
        email: '$username@tasikmalayakota.go.id',
      );
    }

    return const PerwaskimIdentity(
      nama: 'Drs. Rian Hidayat, M.Si',
      jabatan: 'Tim Verifikator Lapangan (Perwaskim)',
      nip: 'NIP: 197805122006041008',
      initials: 'RH',
      email: 'rian.hidayat@tasikmalayakota.go.id',
    );
  }

  static String _extractInitials(String name) {
    final clean = name
        .replaceAll(
          RegExp(
            r'\b(Drs|Dr|Ir|H|Hj|M\.Si|S\.T|M\.T|S\.Kom|M\.Kom)\b\.?',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class TabBerandaMonitoring extends ConsumerWidget {
  const TabBerandaMonitoring({super.key});

  void _startSurveyForPengajuan(
    BuildContext context,
    WidgetRef ref,
    Pengajuan pengajuan,
    PerwaskimIdentity identity,
  ) {
    final notifier = ref.read(monitoringFormProvider.notifier);
    notifier.resetForm();
    notifier.updatePengajuanId(pengajuan.id);
    notifier.updateNamaPerumahan(pengajuan.namaPerumahan);
    notifier.updateNamaDeveloper(pengajuan.namaPt);
    notifier.updateLokasi('Kota Tasikmalaya');
    notifier.updatePelaksanaNama(identity.nama);
    notifier.updatePelaksanaJabatan(identity.jabatan);
    context.push('/monitoring/tambah');
  }

  void _openBeritaAcara(BuildContext context, MonitoringModel item) {
    context.push(
      '/monitoring/preview',
      extra: {'model': item, 'isDraft': item.isDraft},
    );
  }

  void _openDraft(BuildContext context, MonitoringModel item) {
    context.push(
      '/monitoring/draft',
      extra: item,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(monitoringListAsyncProvider);
    final session = ref.watch(roleSessionProvider);
    final identity = PerwaskimIdentity.fromSession(session);
    final unreadCount = ref.watch(unreadNotifikasiCountProvider);

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: listState.when(
        loading: () => const DataStateView.loading(),
        error: (error, stack) => DataStateView.error(
          onAction: () => ref.invalidate(monitoringListAsyncProvider),
        ),
        data: (list) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PerwaskimHeader(
                identity: identity,
                unreadNotifications: unreadCount > 0 ? unreadCount : 1,
                onNotificationsTap: () =>
                    context.push('/monitoring/lapangan/notifikasi'),
                onProfileTap: () => context.go('/monitoring/lapangan/profil'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: _DashboardContent(
                  monitoring: list,
                  onStartSurvey: (pengajuan) => _startSurveyForPengajuan(
                    context,
                    ref,
                    pengajuan,
                    identity,
                  ),
                  onOpenBeritaAcara: (item) => _openBeritaAcara(context, item),
                  onOpenDraft: (item) => _openDraft(context, item),
                  onOpenHistory: () =>
                      context.go('/monitoring/lapangan/riwayat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerwaskimHeader extends StatelessWidget {
  final PerwaskimIdentity identity;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const _PerwaskimHeader({
    required this.identity,
    required this.unreadNotifications,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return DeveloperHeader(
      brandTitle: 'Satu Rumah',
      brandSubtitle: 'PORTAL PERWASKIM',
      avatarLabel: identity.initials,
      avatarTooltip: 'Buka profil',
      onAvatarTap: onProfileTap,
      showOnlineIndicator: true,
      showNotification: true,
      notificationCount: unreadNotifications,
      notificationTooltip: 'Buka notifikasi ($unreadNotifications belum dibaca)',
      onNotificationTap: onNotificationsTap,
      bottomPadding: 24.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  identity.nama,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textOnRed,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.check_circle,
                color: AppColors.textOnRed,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            identity.jabatan,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnRedSubtle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.xs - 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardSurface.withValues(alpha: 0.18),
              borderRadius: AppRadii.pill,
              border: Border.all(
                color: AppColors.cardSurface.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              identity.nip,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final List<MonitoringModel> monitoring;
  final ValueChanged<Pengajuan> onStartSurvey;
  final ValueChanged<MonitoringModel> onOpenBeritaAcara;
  final ValueChanged<MonitoringModel> onOpenDraft;
  final VoidCallback onOpenHistory;

  const _DashboardContent({
    required this.monitoring,
    required this.onStartSurvey,
    required this.onOpenBeritaAcara,
    required this.onOpenDraft,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(surveyAktifProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PrototypeDataBanner(),
        const SizedBox(height: AppSpacing.md),
        if (assignments.isEmpty)
          const DataStateView.empty(
            title: 'Tidak ada tugas survey aktif',
            message: 'Penugasan dari Admin akan muncul di sini.',
          )
        else
          ...assignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _SurveyTaskCard(
                assignment: assignment,
                onStartSurvey: () => onStartSurvey(assignment),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Hasil Survey Terbaru',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.enterpriseTextMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onOpenHistory,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.enterprisePrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (monitoring.isEmpty)
          const DataStateView.empty(
            title: 'Belum ada hasil survey',
            message: 'Hasil survey yang sudah dicatat akan tampil di sini.',
          )
        else
          ...monitoring
              .take(5)
              .map(
                (item) => _SurveyResultCard(
                  item: item,
                  onOpenBeritaAcara: () => onOpenBeritaAcara(item),
                  onOpenDraft: () => onOpenDraft(item),
                ),
              ),
      ],
    );
  }
}

class _SurveyTaskCard extends StatelessWidget {
  final Pengajuan assignment;
  final VoidCallback onStartSurvey;

  const _SurveyTaskCard({
    required this.assignment,
    required this.onStartSurvey,
  });

  @override
  Widget build(BuildContext context) {
    final isToday =
        assignment.tanggalSurvey != null &&
        DateUtils.isSameDay(assignment.tanggalSurvey!, DateTime.now());
    final badgeLabel = isToday ? 'TUGAS SURVEY HARI INI' : 'TUGAS SURVEY AKTIF';

    final timeString = assignment.tanggalSurvey != null
        ? '${DateFormat('HH:mm').format(assignment.tanggalSurvey!)} WIB'
        : '09:00 WIB';

    final instructionText =
        (assignment.catatanSurvey != null &&
            assignment.catatanSurvey!.trim().isNotEmpty)
        ? assignment.catatanSurvey!.trim()
        : 'Titik kumpul di gerbang utama. Wajib cek drainase dan ketersediaan lahan PSU bersama Site Manager.';

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.enterprisePrimarySurfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.enterprisePrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: AppColors.enterprisePrimary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 13,
                      color: AppColors.enterpriseTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: const TextStyle(
                        color: AppColors.enterpriseTextMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              assignment.namaPerumahan,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.enterpriseTextMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${assignment.namaPt} • ${assignment.id}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.enterpriseTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.enterprisePrimarySurfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.enterprisePrimaryBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 16,
                        color: AppColors.enterprisePrimary,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'INSTRUKSI PENUGASAN ADMIN',
                          style: TextStyle(
                            color: AppColors.enterprisePrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    instructionText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.enterpriseTextMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onStartSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.enterprisePrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text(
                  'Buka Berita Acara & Mulai Survey',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyResultCard extends StatelessWidget {
  final MonitoringModel item;
  final VoidCallback onOpenBeritaAcara;
  final VoidCallback onOpenDraft;

  const _SurveyResultCard({
    required this.item,
    required this.onOpenBeritaAcara,
    required this.onOpenDraft,
  });

  @override
  Widget build(BuildContext context) {
    final actionCallback = item.isDraft ? onOpenDraft : onOpenBeritaAcara;
    final nomorBA = item.nomorSuratBA.trim().isNotEmpty
        ? item.nomorSuratBA.trim()
        : MonitoringModel.generateNomorSuratBA(item.tanggalMonitoring);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: actionCallback,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.5,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.enterprisePrimarySurfaceSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nomorBA,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.enterprisePrimary,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusHasilEvaluasiBadgeWidget(
                    status: item.statusHasilEvaluasi,
                    isCompact: true,
                    showIcon: false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.namaPerumahan,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.enterpriseTextMain,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              if (item.namaDeveloper.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.namaDeveloper,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.enterpriseTextMuted,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.enterpriseTextMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            DateFormat(
                              'd MMM yyyy',
                              'id',
                            ).format(item.tanggalMonitoring),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.enterpriseTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: actionCallback,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        item.isDraft ? 'Dokumen Draft' : 'Lihat Dokumen BA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isDraft
                              ? AppColors.enterpriseTextMuted
                              : AppColors.enterprisePrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
