import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';

class PengajuanListCard extends StatelessWidget {
  const PengajuanListCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.onDownloadSk,
  });

  final Pengajuan item;
  final VoidCallback onOpen;
  final VoidCallback? onDownloadSk;
  static final _number = NumberFormat.decimalPattern('id_ID');

  static (int step, int total, String tahapLabel, double progress) _getStepInfo(
    StatusTahapPengajuan stage,
  ) {
    switch (stage) {
      case StatusTahapPengajuan.pengajuanBaru:
        return (1, 4, 'Pengajuan Baru', 0.25);
      case StatusTahapPengajuan.verifikasiAdministrasi:
        return (2, 4, 'Verifikasi Administrasi', 0.50);
      case StatusTahapPengajuan.verifikasiTeknis:
        return (2, 4, 'Verifikasi Teknis', 0.50);
      case StatusTahapPengajuan.surveyLapangan:
        return (3, 4, 'Verifikasi Lapangan', 0.75);
      case StatusTahapPengajuan.persetujuan:
        return (4, 4, 'Persetujuan Final', 0.90);
      case StatusTahapPengajuan.selesai:
        return (4, 4, 'Selesai Validasi', 1.0);
      case StatusTahapPengajuan.perluPerbaikan:
        return (2, 4, 'Perlu Perbaikan', 0.40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWaitingVerification =
        item.status.toLowerCase() == 'menunggu verifikasi perbaikan';
    final revision = item.statusTahap == StatusTahapPengajuan.perluPerbaikan &&
        !isWaitingVerification;
    final complete = item.statusTahap == StatusTahapPengajuan.selesai;
    final canRevise = revision && !item.revisionSubmitted;
    final status = isWaitingVerification
        ? 'Menunggu Verifikasi Perbaikan'
        : revision
        ? 'Perlu Perbaikan'
        : complete
        ? 'Disetujui'
        : 'Dalam Proses';

    final tipeText = item.tipePengajuan ??
        (item.tipePerumahan.contains('Site Plan')
            ? item.tipePerumahan
            : 'Pengajuan Site Plan (${item.tipePerumahan})');

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadii.card,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top row: ID chip & Status badge
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppRadii.tight,
                      ),
                      child: Text(
                        item.id,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StatusBadge(
                      status: status,
                      showIcon: true,
                      showBorder: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Title: Nama Perumahan
                Text(
                  item.namaPerumahan,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // 3. Subtitle row: [Tipe] Pill + Type text
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'Tipe',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        tipeText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. Metrics container: Luas Lahan & Rencana Unit
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundCanvas,
                    borderRadius: AppRadii.small,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _metric(
                          Icons.straighten,
                          'Luas Lahan',
                          '${_number.format(item.luasLahan)} m²',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _metric(
                          Icons.home_work_outlined,
                          'Rencana Unit',
                          '${_number.format(item.jumlahUnit)} Unit',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5. Middle State-Specific Area
                if (isWaitingVerification) ...[
                  // Langsung ke bottom action bar
                ] else if (revision) ...[
                  // Date sent & Updated row
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _inlineNotice(
                        icon: Icons.event_outlined,
                        text: 'Dikirim ${item.tanggal}',
                        color: AppColors.textSecondary,
                      ),
                      _inlineNotice(
                        icon: Icons.schedule_outlined,
                        text: item.diperbarui ?? 'Diperbarui 2 hari lalu',
                        color: AppColors.statusWarningText,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  if (item.catatanPerbaikan?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.catatanPerbaikan!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else if (complete) ...[
                  // SK Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessSurface,
                      borderRadius: AppRadii.small,
                      border: Border.all(
                        color: AppColors.statusSuccessText.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor SK Pengesahan:',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.statusSuccessText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.nomorSk ?? '648/SK-SP/DPKP/2026',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.statusSuccessText.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            item.tanggalSk ?? item.tanggal,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.statusSuccessText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Dalam Proses: Step & Progress bar
                  Builder(
                    builder: (context) {
                      final stepInfo = _getStepInfo(item.statusTahap);
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.statusSurveySurface,
                          borderRadius: AppRadii.small,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _inlineNotice(
                                  icon: Icons.info_outline,
                                  text: 'Tahap: ${stepInfo.$3}',
                                  color: AppColors.statusSurveyText,
                                  fontWeight: FontWeight.w700,
                                ),
                                Text(
                                  'Langkah ${stepInfo.$1}/${stepInfo.$2}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.statusSurveyText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LinearProgressIndicator(
                              value: stepInfo.$4,
                              semanticsLabel: 'Tahap ${item.statusTahap.label}',
                              minHeight: 6,
                              borderRadius: AppRadii.pill,
                              color: AppColors.statusSurveyText,
                              backgroundColor: AppColors.borderSubtle,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // 6. Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: canRevise
                  ? AppColors.statusWarningSurface.withValues(alpha: .4)
                  : AppColors.cardSurface,
              border: const Border(
                top: BorderSide(color: AppColors.dividerLine),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (isWaitingVerification) ...[
                  _inlineNotice(
                    icon: Icons.event_outlined,
                    text: 'Dikirim ${item.tanggal}',
                    color: AppColors.textSecondary,
                  ),
                  _inlineNotice(
                    icon: Icons.schedule_outlined,
                    text: item.diperbarui ?? 'Diperbarui 2 hari lalu',
                    color: AppColors.statusWarningText,
                    fontWeight: FontWeight.w600,
                  ),
                ] else if (revision) ...[
                  _inlineNotice(
                    icon: item.revisionSubmitted
                        ? Icons.info_outline
                        : Icons.warning_amber_rounded,
                    text: item.revisionSubmitted
                        ? 'Revisi terkirim · Menunggu pemeriksaan'
                        : item.dokumenPerluRevisi.isEmpty
                        ? '2 berkas perlu diperbaiki'
                        : '${item.dokumenPerluRevisi.length} berkas perlu diperbaiki',
                    color: AppColors.statusWarningText,
                    fontWeight: FontWeight.w700,
                    iconSize: 16,
                  ),
                  TextButton.icon(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: canRevise
                          ? AppColors.textOnRed
                          : AppColors.primaryRed,
                      backgroundColor: canRevise
                          ? AppColors.primaryRed
                          : AppColors.primarySurfaceSoft,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.small,
                      ),
                      textStyle: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: Icon(
                      canRevise
                          ? Icons.edit_document
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(canRevise ? 'Perbaiki →' : 'Cek Detail →'),
                  ),
                ] else if (complete) ...[
                  _inlineNotice(
                    icon: Icons.check_circle_outline,
                    text: 'Selesai Validasi',
                    color: AppColors.statusSuccessText,
                    fontWeight: FontWeight.w600,
                    iconSize: 16,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (onDownloadSk != null) {
                        onDownloadSk!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Mengunduh SK Pengesahan: ${item.nomorSk ?? "648/SK-SP/DPKP/2026"} (Dummy/Local Preview)',
                            ),
                            backgroundColor: AppColors.statusSuccessText,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 40),
                      foregroundColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(
                      Icons.file_download_outlined,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    label: const Text('Unduh SK (PDF)'),
                  ),
                ] else ...[
                  _inlineNotice(
                    icon: Icons.event_outlined,
                    text: 'Dikirim ${item.tanggal}',
                    color: AppColors.textSecondary,
                  ),
                  InkWell(
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detail',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primaryRed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _metric(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.textSecondary, size: 16),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _inlineNotice({
    required IconData icon,
    required String text,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
    double iconSize = 14,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

