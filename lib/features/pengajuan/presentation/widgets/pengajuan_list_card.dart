import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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
    this.onOpenSk,
  });

  final Pengajuan item;
  final VoidCallback onOpen;

  /// Membuka SK pengesahan pengajuan ini (layar Unduh SK & BA).
  final VoidCallback? onOpenSk;
  static final _number = NumberFormat.decimalPattern('id_ID');

  static (int step, int total, String tahapLabel, double progress) stepInfoOf(
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

  /// Label status yang sama dipakai kartu daftar dan kartu Beranda.
  static String statusLabelOf(Pengajuan item) {
    if (item.status.toLowerCase() == 'menunggu verifikasi perbaikan') {
      return 'Menunggu Verifikasi Perbaikan';
    }
    if (item.statusTahap == StatusTahapPengajuan.perluPerbaikan) {
      return 'Perlu Perbaikan';
    }
    if (item.statusTahap == StatusTahapPengajuan.selesai) return 'Disetujui';
    return 'Dalam Proses';
  }

  /// "Lihat SK" membuka layar Unduh SK & BA untuk pengajuan ini. Tanpa berkas
  /// SK tercatat, teks tenang "SK belum tersedia" menggantikannya.
  Widget _buildSkLink() {
    final hasSk = (item.skPersetujuanPath ?? '').trim().isNotEmpty;
    if (!hasSk || onOpenSk == null) {
      return const Flexible(
        child: Text(
          'SK belum tersedia',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slate400,
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Lihat SK Pengesahan',
      child: InkWell(
        onTap: onOpenSk,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: Color(0xFF15803D),
                ),
                SizedBox(width: 4),
                Text(
                  'Lihat SK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Aksi "Detail" di footer kartu non-selesai. Warna merah kanonis agar
  /// kontras di atas kartu putih; area ketuk minimal 44dp.
  Widget _buildDetailLink() {
    return Semantics(
      button: true,
      label: 'Lihat detail pengajuan',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWaitingVerification =
        item.status.toLowerCase() == 'menunggu verifikasi perbaikan';
    final revision =
        item.statusTahap == StatusTahapPengajuan.perluPerbaikan &&
        !isWaitingVerification;
    final complete = item.statusTahap == StatusTahapPengajuan.selesai;
    final canRevise = revision && !item.revisionSubmitted;
    final status = statusLabelOf(item);

    final tipeText =
        item.tipePengajuan ??
        (item.tipePerumahan.contains('Site Plan')
            ? item.tipePerumahan
            : 'Pengajuan Site Plan (${item.tipePerumahan})');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group 1: Identity & Status
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.namaPerumahan,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.48,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: StatusBadge(
                            status: status,
                            showIcon: true,
                            showBorder: true,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Tipe: $tipeText',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Group 2: Essential Metrics (Unboxed inline layout)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9)),
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            size: 16,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Luas Lahan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate400,
                                  ),
                                ),
                                Text(
                                  '${_number.format(item.luasLahan)} m²',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            size: 16,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rencana Unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate400,
                                  ),
                                ),
                                Text(
                                  '${_number.format(item.jumlahUnit)} Unit',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Group 3: Contextual Action per status
              if (isWaitingVerification) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF3B82F6), width: 4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Revisi terkirim · Menunggu pemeriksaan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (revision) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    border: Border(
                      left: BorderSide(color: Color(0xFFF59E0B), width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item.catatanPerbaikan != null &&
                                item.catatanPerbaikan!.trim().isNotEmpty)
                            ? item.catatanPerbaikan!
                            : (item.dokumenPerluRevisi.isEmpty
                                  ? 'Pengajuan perlu diperbaiki. Buka detail untuk melihat berkas yang diminta.'
                                  : '${item.dokumenPerluRevisi.length} berkas perlu diperbaiki.'),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textScaler = MediaQuery.textScalerOf(context);
                          final isTextScaled = textScaler.scale(1.0) > 1.15;

                          final Widget timestampWidget = item.diperbarui == null
                              ? const SizedBox.shrink()
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      size: 14,
                                      color: Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        item.diperbarui!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                );

                          final actionWidget = canRevise
                              ? ElevatedButton.icon(
                                  onPressed: onOpen,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.edit_document,
                                    size: 16,
                                  ),
                                  label: const Text('Perbaiki Berkas'),
                                )
                              : Text(
                                  'Revisi terkirim · Menunggu pemeriksaan',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.statusWarningText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );

                          final minWidthNeeded = canRevise ? 270.0 : 360.0;
                          final bool useMultiRow =
                              isTextScaled ||
                              constraints.maxWidth < minWidthNeeded;

                          if (useMultiRow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                timestampWidget,
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: actionWidget,
                                ),
                              ],
                            );
                          }

                          return SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: timestampWidget,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                actionWidget,
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (complete) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nomor SK Pengesahan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.nomorSk ?? 'Belum tersedia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF064E3B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.tanggalSk != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            item.tanggalSk!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Builder(
                  builder: (context) {
                    final stepInfo = stepInfoOf(item.statusTahap);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Tahap: ${stepInfo.$3}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0369A1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Langkah ${stepInfo.$1}/${stepInfo.$2}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stepInfo.$4,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Group 4: Footer
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle_outline
                                : Icons.calendar_today_outlined,
                            size: 13,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              complete
                                  ? 'Selesai diproses'
                                  : 'Dikirim ${item.tanggal}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (complete) _buildSkLink() else _buildDetailLink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
