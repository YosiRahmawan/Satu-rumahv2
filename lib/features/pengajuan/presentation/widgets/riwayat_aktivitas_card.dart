import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/riwayat_item.dart';
import '../../data/repositories/pengajuan_api_repository.dart';

/// Warna dan ikon bulatan menurut jenis kejadian (sama dengan Riwayat di Web Admin).
({Color fg, Color bg, IconData icon, String label}) _gaya(RiwayatItem e) {
  if (e.ditolak) {
    return (
      fg: AppColors.statusUrgentText,
      bg: AppColors.statusUrgentSurface,
      icon: Icons.cancel_outlined,
      label: 'Ditolak',
    );
  }
  return switch (e.type) {
    'revision_requested' => (
      fg: AppColors.statusWarningText,
      bg: AppColors.statusWarningSurface,
      icon: Icons.warning_amber_rounded,
      label: 'Perlu Perbaikan',
    ),
    'file_reviewed' when e.title.toLowerCase().contains('perlu perbaikan') => (
      fg: AppColors.statusWarningText,
      bg: AppColors.statusWarningSurface,
      icon: Icons.warning_amber_rounded,
      label: 'Perlu Perbaikan',
    ),
    'file_reviewed' => (
      fg: AppColors.statusSuccessText,
      bg: AppColors.statusSuccessSurface,
      icon: Icons.check_circle_outline,
      label: 'Dokumen Sesuai',
    ),
    'decided' => (
      fg: AppColors.statusSuccessText,
      bg: AppColors.statusSuccessSurface,
      icon: Icons.verified_outlined,
      label: 'Disetujui',
    ),
    'stage_advanced' => (
      fg: AppColors.statusSuccessText,
      bg: AppColors.statusSuccessSurface,
      icon: Icons.arrow_forward_rounded,
      label: 'Tahap Lanjut',
    ),
    'survey_scheduled' || 'survey_rescheduled' => (
      fg: AppColors.statusSurveyText,
      bg: AppColors.statusSurveySurface,
      icon: Icons.event_outlined,
      label: 'Survei',
    ),
    'report_submitted' => (
      fg: AppColors.statusSurveyText,
      bg: AppColors.statusSurveySurface,
      icon: Icons.description_outlined,
      label: 'Laporan Survei',
    ),
    'survey_cancelled' => (
      fg: AppColors.statusWarningText,
      bg: AppColors.statusWarningSurface,
      icon: Icons.event_busy_outlined,
      label: 'Survei Dibatalkan',
    ),
    'report_signed_ketua' || 'report_signed_admin' => (
      fg: AppColors.statusSuccessText,
      bg: AppColors.statusSuccessSurface,
      icon: Icons.draw_outlined,
      label: 'BA Ditandatangani',
    ),
    'report_published' => (
      fg: AppColors.statusSuccessText,
      bg: AppColors.statusSuccessSurface,
      icon: Icons.verified_outlined,
      label: 'BA Diterbitkan',
    ),
    'resubmitted' => (
      fg: AppColors.statusSurveyText,
      bg: AppColors.statusSurveySurface,
      icon: Icons.sync_rounded,
      label: 'Perbaikan Dikirim',
    ),
    _ => (
      fg: AppColors.grey700,
      bg: AppColors.grey200,
      icon: Icons.flag_outlined,
      label: 'Pengajuan',
    ),
  };
}

/// Riwayat aktivitas pengajuan dari server: siapa melakukan apa dan kapan.
class RiwayatAktivitasCard extends ConsumerWidget {
  const RiwayatAktivitasCard({super.key, required this.number});

  final String number;

  static final _waktu = DateFormat('d MMM y · HH.mm', 'id_ID');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(riwayatPengajuanProvider(number));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Aktivitas', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 2),
            const Text(
              'Setiap tindakan pada pengajuan ini tercatat.',
              style: TextStyle(fontSize: 12, color: AppColors.slate400),
            ),
            const SizedBox(height: AppSpacing.md),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
              error: (_, _) => Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Riwayat belum bisa dimuat.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(riwayatPengajuanProvider(number)),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? const Text(
                      'Belum ada aktivitas tercatat.',
                      style: TextStyle(fontSize: 13, color: AppColors.slate400),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _Baris(
                            item: items[i],
                            terakhir: i == items.length - 1,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.item, required this.terakhir});

  final RiwayatItem item;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    final g = _gaya(item);
    final waktu = item.createdAt == null
        ? ''
        : RiwayatAktivitasCard._waktu.format(item.createdAt!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: g.bg, shape: BoxShape.circle),
                child: Icon(g.icon, size: 16, color: g.fg),
              ),
              if (!terakhir)
                Expanded(
                  child: Container(width: 2, color: AppColors.borderSubtle),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: g.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      g.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: g.fg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((item.description ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    [waktu, if (item.actor != null) item.actor!].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate400,
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

/// Alasan penolakan, diambil dari riwayat (peristiwa keputusan "ditolak").
class AlasanPenolakanCard extends ConsumerWidget {
  const AlasanPenolakanCard({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(riwayatPengajuanProvider(number)).asData?.value;
    final alasan = items
        ?.where((e) => e.ditolak)
        .map((e) => e.description?.trim() ?? '')
        .firstWhere((d) => d.isNotEmpty, orElse: () => '');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusUrgentText.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: AppColors.statusUrgentText,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pengajuan ditolak',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusUrgentText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (alasan ?? '').isEmpty
                ? 'Pengajuan ini tidak dapat dilanjutkan. Hubungi Disperwaskim untuk penjelasan.'
                : alasan!,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
