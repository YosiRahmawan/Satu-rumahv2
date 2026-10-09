import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Canonical hero header component for the multi-step Pengembang submission flow.
///
/// Features:
/// - Brand red gradient ([AppColors.heroGradient])
/// - Bottom corner radius ([AppRadii.hero])
/// - Semi-transparent circular back and help action buttons
/// - Centered title, step indicator subtitle, and official agency pill badge
/// - Accessible and responsive scaling up to 200% text scale without overflow
class PengajuanStepHeader extends StatelessWidget {
  const PengajuanStepHeader({
    super.key,
    this.title = 'Pengajuan Baru',
    this.subtitle = 'Langkah 1 dari 5',
    this.badgeText = 'DISPERWASKIM KOTA TASIKMALAYA',
    this.onBackPressed,
    this.onHelpPressed,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback? onBackPressed;
  final VoidCallback? onHelpPressed;

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryRed),
            SizedBox(width: AppSpacing.sm),
            Text('Panduan Pengajuan', style: AppTextStyles.titleMedium),
          ],
        ),
        content: const Text(
          'Lengkapi data PT dan permohonan site plan pada langkah ini. '
          'Seluruh berkas administrasi dan gambar teknis akan diunggah pada langkah berikutnya.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti', style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.pill,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsRegular.sealCheck,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              badgeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isTextScaled = MediaQuery.textScalerOf(context).scale(14) > 20;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row with back button, center title/subtitle/pill, and help button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCircularButton(
                icon: Icons.arrow_back,
                tooltip: 'Kembali',
                onTap: onBackPressed ?? () => _defaultBack(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnRedSubtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAgencyPill(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildCircularButton(
                icon: Icons.help_outline,
                tooltip: 'Bantuan',
                onTap: onHelpPressed ?? () => _showHelpDialog(context),
              ),
            ],
          ),
          if (isTextScaled) const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
