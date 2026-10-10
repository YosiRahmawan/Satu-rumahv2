import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class BeritaAcaraActionButtons extends StatelessWidget {
  final bool isPdfBusy;
  final bool isShareBusy;
  final VoidCallback? onPdf;
  final VoidCallback? onShare;

  const BeritaAcaraActionButtons({
    super.key,
    required this.isPdfBusy,
    required this.isShareBusy,
    required this.onPdf,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isPdfBusy || isShareBusy;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.enterprisePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
            ),
            icon: isPdfBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              isPdfBusy ? 'Menyiapkan PDF...' : 'Download / Cetak PDF',
              style: AppTextStyles.labelLarge.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.enterpriseSuccess,
              side: const BorderSide(color: AppColors.enterpriseSuccess),
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
            ),
            icon: isShareBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(
              isShareBusy ? 'Membuka menu berbagi...' : 'Bagikan ringkasan',
              style: AppTextStyles.labelLarge.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                color: AppColors.enterpriseSuccess,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
