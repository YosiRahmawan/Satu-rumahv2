import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dialog panduan pengajuan berkas site plan: isi tiap dari 5 langkah form.
/// Digunakan bersama oleh [PengajuanStepHeader] dan Pusat Bantuan.
class PanduanPengajuanDialog extends StatelessWidget {
  const PanduanPengajuanDialog({super.key});

  static const _langkah = [
    (
      'Data PT',
      'Isi jenis pengajuan, nama dan alamat proyek, NPWP (tekan Verifikasi), '
          'luas lahan, jumlah unit, dan tipe perumahan. Daya listrik PLN boleh '
          'dikosongkan.',
    ),
    (
      'Berkas PT',
      'Unggah 5 berkas PDF (maks. 10 MB): KTP, NIB, NPWP, keanggotaan '
          'asosiasi, dan legalitas akta.',
    ),
    (
      'Berkas perumahan',
      'Unggah 11 berkas PDF (maks. 10 MB). Satu berkas opsional: Data '
          'Penanggung Jawab Dokumen Teknis.',
    ),
    (
      'Teknis',
      'Unggah minimal satu site plan berformat DWG atau PDF (maks. 50 MB), '
          'lalu pilih cakupan gambarnya.',
    ),
    ('Review', 'Periksa semua data, centang pernyataan, lalu kirim.'),
  ];

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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengajuan diisi dalam 5 langkah. Berikut isi tiap langkah.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _langkah.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == _langkah.length - 1 ? 0 : AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _langkah[i].$1,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _langkah[i].$2,
                              style: AppTextStyles.bodySmall.copyWith(
                                height: 1.5,
                                color: AppColors.textSecondary,
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
