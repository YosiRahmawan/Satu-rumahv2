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
    context.push('/monitoring/draft', extra: item);
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
                unreadNotifications: unreadCount,
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
      showBrandBar: false,
      pageTitle: identity.nama,
      pageSubtitle: identity.jabatan,
      avatarLabel: identity.initials,
      avatarTooltip: 'Buka profil',
      onAvatarTap: onProfileTap,
      showOnlineIndicator: true,
      showNotification: true,
      notificationCount: unreadNotifications,
      showNotificationCount: true,
      notificationTooltip: unreadNotifications > 0
          ? 'Buka notifikasi ($unreadNotifications belum dibaca)'
          : 'Buka notifikasi',
      onNotificationTap: onNotificationsTap,
      bottomPadding: 24.0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.xs,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadii.pill,
          ),
          child: Text(
            identity.nip,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
        if (assignments.isEmpty)
          const DataStateView.empty(
            title: 'Tidak ada tugas survey aktif',
            message: 'Penugasan dari Admin akan muncul di sini.',
          )
        else ...[
          _SectionHeader(
            title: 'Tugas Survey Aktif',
            trailing: Text(
              '${assignments.length} tugas',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SurveyTaskCard(
            assignment: assignments.first,
            onStartSurvey: () => onStartSurvey(assignments.first),
          ),
          if (assignments.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            _SurveyTaskList(
              assignments: assignments.skip(1).toList(),
              onStartSurvey: onStartSurvey,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(
          title: 'Hasil Survey Terbaru',
          trailing: TextButton(
            onPressed: onOpenHistory,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lihat Semua',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (monitoring.isEmpty)
          const DataStateView.empty(
            title: 'Belum ada hasil survey',
            message: 'Hasil survey yang sudah dicatat akan tampil di sini.',
          )
        else
          _SurveyResultList(
            items: monitoring.take(5).toList(),
            onOpenBeritaAcara: onOpenBeritaAcara,
            onOpenDraft: onOpenDraft,
          ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Mode prototipe lokal · data contoh',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.enterpriseTextMain,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}

String? _scheduleLabel(Pengajuan assignment) {
  final date = assignment.tanggalSurvey;
  if (date == null) return null;
  final time = '${DateFormat('HH:mm').format(date)} WIB';
  return DateUtils.isSameDay(date, DateTime.now())
      ? 'Hari ini, $time'
      : '${DateFormat('d MMM yyyy', 'id').format(date)}, $time';
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
    final schedule = _scheduleLabel(assignment);
    final instructionText =
        (assignment.catatanSurvey != null &&
            assignment.catatanSurvey!.trim().isNotEmpty)
        ? assignment.catatanSurvey!.trim()
        : 'Titik kumpul di gerbang utama. Wajib cek drainase dan ketersediaan lahan PSU bersama Site Manager.';

    return Container(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    schedule,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              assignment.namaPerumahan,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.enterpriseTextMain,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${assignment.namaPt} · ${assignment.id}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'INSTRUKSI ADMIN',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              instructionText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.enterpriseTextMain,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onStartSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: AppColors.textOnRed,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Buka Berita Acara & Mulai Survey',
                    maxLines: 1,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textOnRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool showDivider;

  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.enterpriseTextMain,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.enterpriseBorder),
      ],
    );
  }
}

class _SurveyTaskList extends StatelessWidget {
  final List<Pengajuan> assignments;
  final ValueChanged<Pengajuan> onStartSurvey;

  const _SurveyTaskList({
    required this.assignments,
    required this.onStartSurvey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < assignments.length; i++)
            _ListRow(
              title: assignments[i].namaPerumahan,
              subtitle: assignments[i].namaPt,
              showDivider: i < assignments.length - 1,
              onTap: () => onStartSurvey(assignments[i]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (assignments[i].tanggalSurvey != null)
                    Text(
                      DateFormat('HH:mm').format(assignments[i].tanggalSurvey!),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SurveyResultList extends StatelessWidget {
  final List<MonitoringModel> items;
  final ValueChanged<MonitoringModel> onOpenBeritaAcara;
  final ValueChanged<MonitoringModel> onOpenDraft;

  const _SurveyResultList({
    required this.items,
    required this.onOpenBeritaAcara,
    required this.onOpenDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _resultRow(items[i], showDivider: i < items.length - 1),
        ],
      ),
    );
  }

  Widget _resultRow(MonitoringModel item, {required bool showDivider}) {
    final date = DateFormat('d MMM yyyy', 'id').format(item.tanggalMonitoring);
    return _ListRow(
      title: item.namaPerumahan,
      subtitle: item.isDraft ? 'Draf · $date' : date,
      showDivider: showDivider,
      onTap: () => item.isDraft ? onOpenDraft(item) : onOpenBeritaAcara(item),
      trailing: StatusHasilEvaluasiBadgeWidget(
        status: item.statusHasilEvaluasi,
        isCompact: true,
        showIcon: false,
      ),
    );
  }
}

const _cardDecoration = BoxDecoration(
  color: AppColors.cardSurface,
  borderRadius: AppRadii.card,
  border: Border.fromBorderSide(BorderSide(color: AppColors.enterpriseBorder)),
  boxShadow: [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ],
);
