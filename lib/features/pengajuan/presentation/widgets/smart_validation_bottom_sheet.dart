import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Item metadata representing a missing requirement for the Smart Validation Bottom Sheet.
class MissingValidationItem {
  final String key;
  final String title;
  final String? subtitle;
  final String statusText;
  final IconData? icon;

  const MissingValidationItem({
    required this.key,
    required this.title,
    this.subtitle,
    this.statusText = 'Belum diunggah',
    this.icon,
  });
}

/// Smart Form Validation Bottom Sheet based on Google Stitch design.
///
/// Provides a clear, non-blocking modal notifying users of any missing
/// mandatory requirements before proceeding to the next step.
class SmartValidationBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final int completedCount;
  final int totalCount;
  final String? statusBadgeText;
  final String? warningText;
  final String sectionTitle;
  final List<MissingValidationItem> missingItems;
  final String actionButtonText;
  final String cancelButtonText;
  final ValueChanged<String?> onActionPressed;
  final VoidCallback onCancelPressed;

  const SmartValidationBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedCount,
    required this.totalCount,
    this.statusBadgeText,
    this.warningText,
    this.sectionTitle = 'DAFTAR DOKUMEN YANG PERLU DIUNGGAH',
    required this.missingItems,
    this.actionButtonText = 'Lengkapi Berkas Sekarang',
    this.cancelButtonText = 'Kembali ke Formulir',
    required this.onActionPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBadge = statusBadgeText ??
        '$completedCount dari $totalCount berkas lengkap';
    final remainingCount = totalCount - completedCount;
    final effectiveWarning = warningText ??
        '$remainingCount berkas wajib belum diunggah';
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. Drag Handle ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),

            // ─── 2. Sheet Header Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primarySurfaceBorder,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      PhosphorIconsRegular.warning,
                      size: 22,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.slate400,
                    splashRadius: 20,
                    tooltip: 'Tutup',
                    onPressed: onCancelPressed,
                  ),
                ],
              ),
            ),

            // ─── 3. Content Body (Flexible to prevent any viewport overflow) ──
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status & Completion Summary Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.slate200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Status Kelengkapan',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: AppRadii.pill,
                                    border: Border.all(
                                      color: AppColors.primarySurfaceBorder,
                                    ),
                                  ),
                                  child: Text(
                                    effectiveBadge,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Progress bar track
                            ClipRRect(
                              borderRadius: AppRadii.pill,
                              child: Container(
                                height: 7,
                                width: double.infinity,
                                color: AppColors.slate200,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryRed,
                                      borderRadius: AppRadii.pill,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Warning count row
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 14,
                                  color: AppColors.primaryRed,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    effectiveWarning,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section Title Label
                      Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.slate400,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Missing Documents List
                      if (missingItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.statusSuccess,
                                size: 32,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Semua persyaratan telah terpenuhi!',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: missingItems.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.slate100,
                          ),
                          itemBuilder: (context, index) {
                            final item = missingItems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      item.icon ??
                                          Icons.description_outlined,
                                      size: 16,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMain,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.subtitle != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle!,
                                            style: const TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 10,
                                              color: AppColors.slate400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurfaceSoft,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color:
                                            AppColors.primarySurfaceBorder,
                                      ),
                                    ),
                                    child: Text(
                                      item.statusText,
                                      style: const TextStyle(
                                        fontFamily:
                                            AppTextStyles.fontFamily,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ─── 4. Sheet Bottom Actions ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final firstKey = missingItems.isNotEmpty
                          ? missingItems.first.key
                          : null;
                      onActionPressed(firstKey);
                    },
                    child: Text(
                      actionButtonText,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onCancelPressed,
                    child: Text(
                      cancelButtonText,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
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

/// Helper function to display the Smart Validation Bottom Sheet cleanly with smooth animations.
Future<void> showSmartValidationBottomSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required int completedCount,
  required int totalCount,
  String? statusBadgeText,
  String? warningText,
  String sectionTitle = 'DAFTAR DOKUMEN YANG PERLU DIUNGGAH',
  required List<MissingValidationItem> missingItems,
  String actionButtonText = 'Lengkapi Berkas Sekarang',
  String cancelButtonText = 'Kembali ke Formulir',
  ValueChanged<String?>? onActionPressed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x990F172A), // Slate 900 60% opacity backdrop
    builder: (ctx) => SmartValidationBottomSheet(
      title: title,
      subtitle: subtitle,
      completedCount: completedCount,
      totalCount: totalCount,
      statusBadgeText: statusBadgeText,
      warningText: warningText,
      sectionTitle: sectionTitle,
      missingItems: missingItems,
      actionButtonText: actionButtonText,
      cancelButtonText: cancelButtonText,
      onActionPressed: (firstKey) {
        Navigator.of(ctx).pop();
        onActionPressed?.call(firstKey);
      },
      onCancelPressed: () => Navigator.of(ctx).pop(),
    ),
  );
}
