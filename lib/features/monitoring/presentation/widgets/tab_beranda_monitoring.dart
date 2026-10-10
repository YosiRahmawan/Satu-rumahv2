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

  const PerwaskimIdentity({
    required this.nama,
    required this.jabatan,
    required this.nip,
    required this.initials,
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
        );
      }
      if (username.contains('budi')) {
        return const PerwaskimIdentity(
          nama: 'Budi Santoso, S.T.',
          jabatan: 'Tim Verifikator Lapangan (Perwaskim)',
          nip: 'NIP: 19880512 201503 1 002',
          initials: 'BS',
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
      );
    }

    return const PerwaskimIdentity(
      nama: 'Drs. Rian Hidayat, M.Si',
      jabatan: 'Tim Verifikator Lapangan (Perwaskim)',
      nip: 'NIP: 197805122006041008',
      initials: 'RH',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(monitoringListAsyncProvider);
    final session = ref.watch(roleSessionProvider);
    final identity = PerwaskimIdentity.fromSession(session);
    final unreadCount = ref.watch(unreadNotifikasiCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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

  const _PerwaskimHeader({
    required this.identity,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF991B1B),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFF881337)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification button
              Row(
                children: [
                  Semantics(
                    button: true,
                    label:
                        'Buka notifikasi ($unreadNotifications belum dibaca)',
                    child: InkWell(
                      onTap: onNotificationsTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
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
                            if (unreadNotifications > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 15,
                                    minHeight: 15,
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFB91C1C),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$unreadNotifications',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
              const SizedBox(height: 16),
              // Officer identity row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        identity.initials,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                identity.nama,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          identity.jabatan,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            identity.nip,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
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
  final VoidCallback onOpenHistory;

  const _DashboardContent({
    required this.monitoring,
    required this.onStartSurvey,
    required this.onOpenBeritaAcara,
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
                  color: Color(0xFF0F172A),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFFB91C1C),
                  ),
                ],
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB91C1C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
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
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
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
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${assignment.namaPt} • ${assignment.id}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 16,
                        color: Color(0xFFB91C1C),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'INSTRUKSI PENUGASAN ADMIN',
                          style: TextStyle(
                            color: Color(0xFFB91C1C),
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
                      color: Color(0xFF475569),
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
                  backgroundColor: const Color(0xFF991B1B),
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

  const _SurveyResultCard({
    required this.item,
    required this.onOpenBeritaAcara,
  });

  @override
  Widget build(BuildContext context) {
    final nomorBA = item.nomorSuratBA.trim().isNotEmpty
        ? item.nomorSuratBA.trim()
        : MonitoringModel.generateNomorSuratBA(item.tanggalMonitoring);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        nomorBA,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB91C1C),
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
            const SizedBox(height: 10),
            Text(
              item.namaPerumahan,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            if (item.namaDeveloper.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                item.namaDeveloper,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
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
                        color: Color(0xFF94A3B8),
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
                            color: Color(0xFF64748B),
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
                  onTap: item.isDraft ? null : onOpenBeritaAcara,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.isDraft ? 'Dokumen Draft' : 'Lihat Dokumen BA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: item.isDraft
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: item.isDraft
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFFB91C1C),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
