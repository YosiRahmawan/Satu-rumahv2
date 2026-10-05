import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_list_view_provider.dart';

class PengajuanListSummary extends StatelessWidget {
  const PengajuanListSummary({super.key, required this.items});
  final List<Pengajuan> items;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Proses',
        '${items.where(PengajuanFilter.proses.matches).length}',
        'Verifikasi',
        Icons.schedule,
        AppColors.statusSurveyText,
        AppColors.statusSurveySurface,
      ),
      (
        'Perbaikan',
        '${items.where(PengajuanFilter.perbaikan.matches).length}',
        'Revisi Data',
        Icons.warning_amber_rounded,
        AppColors.statusWarningText,
        AppColors.statusWarningSurface,
      ),
      (
        'Disetujui',
        '${items.where(PengajuanFilter.selesai.matches).length}',
        'Terbit SK',
        Icons.check_circle_outline,
        AppColors.statusSuccessText,
        AppColors.statusSuccessSurface,
      ),
      (
        'Ditolak',
        '${items.where((i) => i.status.toLowerCase().contains('tolak')).length}',
        'TMS Berkas',
        Icons.cancel_outlined,
        AppColors.statusUrgentText,
        AppColors.statusUrgentSurface,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          Icons.assessment_outlined,
                          size: 18,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: 'Ringkasan Berkas',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Total: ${items.length} Pengajuan',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = MediaQuery.textScalerOf(context).scale(12) > 16
                  ? 2
                  : 4;
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.sm) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final metric in metrics)
                    Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: metric.$6,
                        borderRadius: AppRadii.small,
                        border: Border.all(
                          color: metric.$5.withValues(alpha: .15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            metric.$1,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: metric.$5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.xs,
                            children: [
                              Icon(metric.$4, color: metric.$5, size: 16),
                              Text(
                                metric.$2,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: metric.$5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            metric.$3,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: metric.$5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
