import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/repositories/officer_api_repository.dart';

/// Reusable action buttons for Berita Acara actions (PDF printing and sharing).
///
/// Uses responsive 2-column layout on standard mobile/web screens,
/// gracefully collapsing to a single column on compact viewports or high text scaling.
class BeritaAcaraActionButtons extends ConsumerWidget {
  final bool isPdfBusy;
  final bool isShareBusy;
  final VoidCallback? onPdf;
  final VoidCallback? onShare;

  /// Nomor BA. Dengan server: bila BA sudah diterbitkan Admin, tombol PDF mengunduh dokumen resmi;
  /// bila belum, PDF dari HP hanya pratinjau dan diberi label "belum resmi".
  final String? nomorBa;

  const BeritaAcaraActionButtons({
    super.key,
    required this.isPdfBusy,
    required this.isShareBusy,
    required this.onPdf,
    required this.onShare,
    this.nomorBa,
  });

  Future<void> _unduhResmi(
    BuildContext context,
    WidgetRef ref,
    String nomor,
  ) async {
    try {
      final bytes = await ref.read(officerRemoteProvider).downloadPdf(nomor);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'BA-${nomor.replaceAll('/', '-')}.pdf',
      );
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, e.message, error: true);
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          context,
          'PDF resmi belum bisa dibuka. Coba lagi.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = isPdfBusy || isShareBusy;
    final nomor = nomorBa?.trim() ?? '';
    final denganServer = ref.watch(apiEnabledProvider) && nomor.isNotEmpty;
    final resmi =
        denganServer &&
        (ref.watch(serverReportProvider(nomor))?.signatures.published ?? false);
    final label = !denganServer
        ? 'Download / Cetak PDF'
        : resmi
        ? 'Unduh PDF Resmi'
        : 'Pratinjau PDF (belum resmi)';
    final aksiPdf = resmi ? () => _unduhResmi(context, ref, nomor) : onPdf;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useTwoColumns = constraints.maxWidth >= 340 && textScale <= 1.3;

        final pdfButton = _buildPdfButton(isBusy, label, aksiPdf);
        final shareButton = _buildShareButton(isBusy);

        if (useTwoColumns) {
          return Row(
            children: [
              Expanded(child: pdfButton),
              const SizedBox(width: 12),
              Expanded(child: shareButton),
            ],
          );
        }

        return Column(
          children: [pdfButton, const SizedBox(height: 10), shareButton],
        );
      },
    );
  }

  Widget _buildPdfButton(bool isBusy, String label, VoidCallback? aksi) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isBusy ? null : aksi,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.enterprisePrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isPdfBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontFamily: AppTextStyles.enterpriseFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildShareButton(bool isBusy) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isBusy ? null : onShare,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.enterpriseSuccess,
            side: const BorderSide(
              color: AppColors.enterpriseSuccess,
              width: 1.4,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isShareBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.enterpriseSuccess,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.share,
                      size: 18,
                      color: AppColors.enterpriseSuccess,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Bagikan ringkasan',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontFamily: AppTextStyles.enterpriseFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.enterpriseSuccess,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
