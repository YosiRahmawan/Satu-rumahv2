import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dialog informasi panduan pengajuan berkas site plan.
/// Digunakan bersama oleh [PengajuanStepHeader] dan Pusat Bantuan.
class PanduanPengajuanDialog extends StatelessWidget {
  const PanduanPengajuanDialog({super.key});

  /// Helper untuk membuka dialog panduan pengajuan secara konsisten.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const PanduanPengajuanDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
