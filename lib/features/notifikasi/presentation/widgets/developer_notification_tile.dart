import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/notifikasi_model.dart';

class DeveloperNotificationTile extends StatelessWidget {
  const DeveloperNotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.actionRequired = false,
  });

  final NotifikasiModel item;
  final VoidCallback onTap;

  /// Permintaan revisi yang masih aktif: satu-satunya kartu yang memakai
  /// aksen amber. Kartu lain tetap netral.
  final bool actionRequired;

  String get _kategori => switch (item.jenis) {
    JenisNotifikasi.pengajuanBaru => 'PENGAJUAN',
    JenisNotifikasi.reminderSurvey => 'JADWAL SURVEY',
    JenisNotifikasi.deadlineVerifikasi => 'VERIFIKASI',
    JenisNotifikasi.dokumenDiunggahUlang => 'DOKUMEN',
    JenisNotifikasi.perluRevisi =>
      actionRequired ? 'TINDAKAN DIPERLUKAN' : 'REVISI',
    JenisNotifikasi.tahapLanjut => 'TAHAP LANJUT',
    JenisNotifikasi.disetujui => 'DISETUJUI',
    JenisNotifikasi.ditolak => 'DITOLAK',
    JenisNotifikasi.dibatalkan => 'JADWAL SURVEY',
    JenisNotifikasi.baTerbit => 'BERITA ACARA',
    JenisNotifikasi.batasPerbaikan => 'BATAS PERBAIKAN',
  };

  @override
  Widget build(BuildContext context) {
    // Keep the Pengembang palette local: other roles use the existing model.
    final (color, surface) = switch (item.jenis) {
      JenisNotifikasi.pengajuanBaru || JenisNotifikasi.reminderSurvey => (
        AppColors.statusSurveyText,
        AppColors.statusSurveySurface,
      ),
      JenisNotifikasi.dokumenDiunggahUlang => (
        AppColors.statusWarningText,
        AppColors.statusWarningSurface,
      ),
      JenisNotifikasi.deadlineVerifikasi ||
      JenisNotifikasi.ditolak => (
        AppColors.statusUrgentText,
        AppColors.statusUrgentSurface,
      ),
      JenisNotifikasi.disetujui || JenisNotifikasi.baTerbit => (
        AppColors.statusSuccessText,
        AppColors.statusSuccessSurface,
      ),
      JenisNotifikasi.tahapLanjut => (
        AppColors.statusSurveyText,
        AppColors.statusSurveySurface,
      ),
      JenisNotifikasi.dibatalkan ||
      JenisNotifikasi.batasPerbaikan => (
        AppColors.statusWarningText,
        AppColors.statusWarningSurface,
      ),
      JenisNotifikasi.perluRevisi =>
        actionRequired
            ? (AppColors.statusWarningText, AppColors.statusWarningSurface)
            : (AppColors.slate500, AppColors.slate100),
    };
    final emphasised = !item.isRead || actionRequired;
    final iconColor = emphasised ? color : const Color(0xFF64748B);
    final iconSurface = emphasised ? surface : const Color(0xFFF1F5F9);

    return Semantics(
      label: item.isRead ? 'Sudah dibaca' : 'Belum dibaca',
      button: true,
      child: Material(
        color: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: actionRequired
                ? AppColors.statusWarningText.withValues(alpha: 0.35)
                : (item.isRead
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.jenis.icon, color: iconColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          container: true,
                          label: item.isRead ? 'Sudah dibaca' : 'Belum dibaca',
                          child: const SizedBox.shrink(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _pill(
                                    _kategori,
                                    emphasised
                                        ? color
                                        : const Color(0xFF64748B),
                                    emphasised
                                        ? surface
                                        : const Color(0xFFF1F5F9),
                                  ),
                                  if (item.isSimulasi)
                                    _pill(
                                      'SIMULASI',
                                      const Color(0xFF64748B),
                                      const Color(0xFFF1F5F9),
                                    ),
                                ],
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  key: const ValueKey('unread-indicator'),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.judul,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.deskripsi,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(item.waktu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, Color surface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}
