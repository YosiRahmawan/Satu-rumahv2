import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final bool showBorder;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'dalam proses':
      case 'proses':
      case 'survey':
      case 'survey lapangan':
        bgColor = AppColors.statusSurveySurface;
        textColor = AppColors.statusSurveyText;
        icon = Icons.schedule;
        break;
      case 'selesai':
      case 'disetujui':
      case 'sesuai':
        bgColor = AppColors.statusSuccessSurface;
        textColor = AppColors.statusSuccessText;
        icon = Icons.check_circle_outline;
        break;
      case 'menunggu verifikasi perbaikan':
      case 'menunggu verifikasi':
        bgColor = AppColors.statusWarningSurface;
        textColor = AppColors.statusWarningText;
        icon = Icons.schedule;
        break;
      case 'perlu perbaikan':
      case 'revisi':
        bgColor = AppColors.statusWarningSurface;
        textColor = AppColors.statusWarningText;
        icon = Icons.warning_amber_rounded;
        break;
      case 'ditolak':
      case 'urgent':
        bgColor = AppColors.statusUrgentSurface;
        textColor = AppColors.statusUrgentText;
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = AppColors.grey200;
        textColor = AppColors.grey700;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: showBorder
            ? Border.all(color: textColor.withValues(alpha: 0.35))
            : null,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (showIcon && icon != null) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(icon, size: 14, color: textColor),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),
            ],
            TextSpan(
              text: status,
              style: AppTextStyles.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
