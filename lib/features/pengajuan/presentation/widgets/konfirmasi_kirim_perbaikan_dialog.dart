import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dialog konfirmasi pengiriman berkas perbaikan (Fase 4 - Konfirmasi Kirim Perbaikan).
/// Sesuai spesifikasi visual Prototype/Pase 4 - Perbaikan.png & design.md.
class KonfirmasiKirimPerbaikanDialog extends StatefulWidget {
  final int jumlahBerkas;
  final Future<void> Function()? onConfirm;

  const KonfirmasiKirimPerbaikanDialog({
    super.key,
    required this.jumlahBerkas,
    this.onConfirm,
  });

  @override
  State<KonfirmasiKirimPerbaikanDialog> createState() =>
      _KonfirmasiKirimPerbaikanDialogState();
}

class _KonfirmasiKirimPerbaikanDialogState
    extends State<KonfirmasiKirimPerbaikanDialog> {
  bool _isSubmitting = false;

  Future<void> _handleKirim() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.onConfirm != null) {
        await widget.onConfirm!();
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isHighTextScale = textScaler.scale(14) > 20;

    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      elevation: 4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Bulat Merah Muda
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryRed,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Judul Dialog
            Text(
              'Kirim Perbaikan Berkas?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 10),

            // Deskripsi Dinamis
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate600,
                  fontSize: 13,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '${widget.jumlahBerkas} berkas',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' yang telah diperbarui akan dikirimkan ke Admin Verifikator. Anda tidak dapat mengubah berkas selama proses verifikasi berlangsung.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tombol Aksi: Batal & Ya, Kirim
            if (isHighTextScale)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildYaKirimButton(),
                  const SizedBox(height: 10),
                  _buildBatalButton(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildBatalButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildYaKirimButton()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatalButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          side: const BorderSide(color: AppColors.slate300, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        child: Text(
          'Batal',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _isSubmitting ? AppColors.slate400 : AppColors.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildYaKirimButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isSubmitting ? null : _handleKirim,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Ya, Kirim',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Menampilkan Dialog Konfirmasi Pengiriman Perbaikan Berkas (Fase 4).
Future<bool?> showKonfirmasiKirimPerbaikanDialog({
  required BuildContext context,
  required int jumlahBerkas,
  Future<void> Function()? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => KonfirmasiKirimPerbaikanDialog(
      jumlahBerkas: jumlahBerkas,
      onConfirm: onConfirm,
    ),
  );
}
