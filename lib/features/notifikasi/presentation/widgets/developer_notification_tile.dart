import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/notifikasi_model.dart';

class DeveloperNotificationTile extends StatelessWidget {
  const DeveloperNotificationTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final NotifikasiModel item;
  final VoidCallback onTap;

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
      JenisNotifikasi.deadlineVerifikasi => (
        AppColors.statusUrgentText,
        AppColors.statusUrgentSurface,
      ),
    };
    final readLabel = item.isRead ? 'Sudah dibaca' : 'Belum dibaca';

    return Material(
      color: item.isRead ? AppColors.cardSurface : AppColors.primarySurfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(
          color: item.isRead
              ? AppColors.borderSubtle
              : AppColors.primarySurfaceBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppRadii.control,
                ),
                child: Icon(item.jenis.icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: item.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.deskripsi,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      DateFormat('dd/MM/yyyy • HH:mm').format(item.waktu),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          item.isRead ? Icons.done_all_rounded : Icons.circle,
                          size: item.isRead ? 14 : 8,
                          color: item.isRead
                              ? AppColors.textSecondary
                              : AppColors.notificationUnread,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            readLabel,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: item.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
