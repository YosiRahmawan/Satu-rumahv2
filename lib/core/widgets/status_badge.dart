import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'dalam proses':
      case 'proses':
      case 'survey':
      case 'survey lapangan':
        bgColor = AppColors.statusSurveySurface;
        textColor = AppColors.statusSurveyText;
        break;
      case 'selesai':
      case 'disetujui':
      case 'sesuai':
        bgColor = AppColors.statusSuccessSurface;
        textColor = AppColors.statusSuccessText;
        break;
      case 'perlu perbaikan':
      case 'revisi':
        bgColor = AppColors.statusWarningSurface;
        textColor = AppColors.statusWarningText;
        break;
      case 'ditolak':
      case 'urgent':
        bgColor = AppColors.statusUrgentSurface;
        textColor = AppColors.statusUrgentText;
        break;
      default:
        bgColor = AppColors.grey200;
        textColor = AppColors.grey700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
