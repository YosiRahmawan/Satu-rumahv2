import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';

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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.enterprisePrimary,
            AppColors.enterprisePrimaryDark,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selamat bertugas,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      identity.nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: unreadNotifications > 0
                        ? 'Buka notifikasi ($unreadNotifications belum dibaca)'
                        : 'Buka notifikasi',
                    child: IconButton(
                      onPressed: onNotificationsTap,
                      tooltip: unreadNotifications > 0
                          ? 'Buka notifikasi ($unreadNotifications belum dibaca)'
                          : 'Buka notifikasi',
                      icon: Badge(
                        isLabelVisible: unreadNotifications > 0,
                        backgroundColor: const Color(0xFFF59E0B),
                        textColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        label: Text(
                          unreadNotifications > 9
                              ? '9+'
                              : '$unreadNotifications',
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Semantics(
                    button: true,
                    label: 'Buka profil',
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          identity.initials,
                          style: const TextStyle(
                            color: AppColors.enterprisePrimaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
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
    final rawAssignments = ref.watch(surveyAktifProvider);

    // Keep assignments in the priority order established by the provider/model
    final assignments = List<Pengajuan>.from(rawAssignments);

    // Sort monitoring results descending by monitoring date, then created date
    final sortedMonitoring = List<MonitoringModel>.from(monitoring)
      ..sort((a, b) {
        final cmp = b.tanggalMonitoring.compareTo(a.tanggalMonitoring);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    final recentResults = sortedMonitoring.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION: Tugas Survey Aktif ---
        _buildSectionHeader(
          title: 'Tugas Survey Aktif',
          trailing: Text(
            '${rawAssignments.length} tugas',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          const DataStateView.empty(
            title: 'Tidak ada tugas survey aktif',
            message: 'Penugasan dari Admin akan muncul di sini.',
          )
        else ...[
          _PrimaryTaskCard(
            assignment: assignments.first,
            onStartSurvey: () => onStartSurvey(assignments.first),
          ),
          if (assignments.length > 1) ...[
            const SizedBox(height: 12),
            _SecondaryTasksList(
              tasks: assignments.skip(1).take(2).toList(),
              onStartSurvey: onStartSurvey,
            ),
          ],
        ],

        const SizedBox(height: 24),

        // --- SECTION: Hasil Survey Terbaru ---
        _buildSectionHeader(
          title: 'Hasil Survey Terbaru',
          trailing: InkWell(
            onTap: onOpenHistory,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Lihat Semua →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (monitoring.isEmpty)
          const DataStateView.empty(
            title: 'Belum ada hasil survey',
            message: 'Hasil survey yang sudah dicatat akan tampil di sini.',
          )
        else
          _SurveyResultCardsList(
            items: recentResults,
            onOpenBeritaAcara: onOpenBeritaAcara,
            onOpenDraft: onOpenDraft,
          ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'Mode prototipe lokal · data contoh',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.enterpriseTextMuted.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Widget trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.enterpriseTextMain,
            ),
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute WIB';
}

String _formatShortTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? _scheduleLabel(Pengajuan assignment) {
  final date = assignment.tanggalSurvey;
  if (date == null) return null;
  return '${_formatDate(date)}, ${_formatTime(date)}';
}

class _PrimaryTaskCard extends StatelessWidget {
  final Pengajuan assignment;
  final VoidCallback onStartSurvey;

  const _PrimaryTaskCard({
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
        : 'Tinjau kesesuaian site plan, drainase, akses jalan, dan fasilitas umum di lokasi perumahan.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schedule != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    schedule,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.enterpriseTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(
            assignment.namaPerumahan,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.enterpriseTextMain,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${assignment.namaPt} · ${assignment.id}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.enterpriseTextMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INSTRUKSI ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.enterpriseTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructionText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStartSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Buka Berita Acara & Mulai Survei',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryTasksList extends StatelessWidget {
  final List<Pengajuan> tasks;
  final ValueChanged<Pengajuan> onStartSurvey;

  const _SecondaryTasksList({required this.tasks, required this.onStartSurvey});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onStartSurvey(tasks[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tasks[i].namaPerumahan,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.enterpriseTextMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tasks[i].namaPt,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.enterpriseTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (tasks[i].tanggalSurvey != null)
                        Text(
                          _formatShortTime(tasks[i].tanggalSurvey!),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.enterpriseTextMuted,
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < tasks.length - 1)
              const Divider(height: 1, color: AppColors.enterpriseBorder),
          ],
        ],
      ),
    );
  }
}

class _SurveyResultCardsList extends StatelessWidget {
  final List<MonitoringModel> items;
  final ValueChanged<MonitoringModel> onOpenBeritaAcara;
  final ValueChanged<MonitoringModel> onOpenDraft;

  const _SurveyResultCardsList({
    required this.items,
    required this.onOpenBeritaAcara,
    required this.onOpenDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _SurveyResultCard(
            item: items[i],
            onTap: () => items[i].isDraft
                ? onOpenDraft(items[i])
                : onOpenBeritaAcara(items[i]),
          ),
          if (i < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SurveyResultCard extends StatelessWidget {
  final MonitoringModel item;
  final VoidCallback onTap;

  const _SurveyResultCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(item.tanggalMonitoring);
    final developerStr = item.namaDeveloper.isNotEmpty
        ? item.namaDeveloper
        : 'Kota Tasikmalaya';
    final actionLabel = item.isDraft
        ? 'Lanjutkan Draf Survei'
        : 'Lihat Detail Hasil';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.enterpriseTextMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: _buildResultBadge(item)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.namaPerumahan,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.enterpriseTextMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  developerStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.enterpriseTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primaryRed,
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

  Widget _buildResultBadge(MonitoringModel item) {
    if (item.isDraft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Draf',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    String label = item.statusHasilEvaluasi.label;

    switch (item.statusHasilEvaluasi) {
      case StatusHasilEvaluasi.sesuaiSiteplan:
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        textColor = const Color(0xFF047857);
        break;
      case StatusHasilEvaluasi.perluEvaluasiLanjutan:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        break;
      case StatusHasilEvaluasi.tidakSesuaiSiteplan:
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFECDD3);
        textColor = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
