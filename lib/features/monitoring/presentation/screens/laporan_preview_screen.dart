import '../../../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_form_provider.dart';
import '../widgets/berita_acara_action_buttons.dart';
import '../widgets/berita_acara_document_card.dart';
import '../../utils/ba_pdf_generator.dart';

/// Screen for previewing the Berita Acara document.
///
/// Serves two contexts:
/// 1. Draft preview before final submission (from stepper form)
/// 2. Official document inspection from Riwayat Monitoring list
class LaporanPreviewScreen extends ConsumerStatefulWidget {
  final MonitoringModel monitoring;
  final bool isDraft;

  const LaporanPreviewScreen({
    super.key,
    required this.monitoring,
    this.isDraft = false,
  });

  @override
  ConsumerState<LaporanPreviewScreen> createState() =>
      _LaporanPreviewScreenState();
}

class _LaporanPreviewScreenState extends ConsumerState<LaporanPreviewScreen> {
  bool _isPdfBusy = false;
  bool _isShareBusy = false;

  bool get _isBusy => _isPdfBusy || _isShareBusy;

  @override
  Widget build(BuildContext context) {
    final monitoring = widget.monitoring;

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.isDraft ? '/monitoring/tambah' : '/monitoring/lapangan/riwayat');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        title: Text(
          'Berita Acara Monitoring',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.enterpriseTextMain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              BeritaAcaraDocumentCard(
                monitoring: monitoring,
                isSuccessContext: false,
              ),
              const SizedBox(height: 24),
              _buildBottomActions(context, monitoring),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, MonitoringModel monitoring) {
    if (widget.isDraft) {
      final formState = ref.watch(monitoringFormProvider);
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.enterprisePrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              onPressed: formState.isSubmitting
                  ? null
                  : () async {
                      final notifier = ref.read(monitoringFormProvider.notifier);
                      final result = ref.read(apiEnabledProvider)
                          ? await notifier.submitFinalViaApi(monitoring)
                          : notifier.submitFinal(monitoring);
                      if (!context.mounted) return;
                      if (result.isSuccess && result.model != null) {
                        context.go(
                          '/monitoring/success',
                          extra: result.model,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.errorMessage ?? 'Laporan gagal dikirim.',
                            ),
                            backgroundColor: AppColors.enterprisePrimary,
                          ),
                        );
                      }
                    },
              icon: formState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18, color: Colors.white),
              label: Text(
                'SUBMIT LAPORAN SEKARANG',
                style: AppTextStyles.labelLarge.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.enterpriseBorder),
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/monitoring/tambah');
                }
              },
              icon: const Icon(
                Icons.edit,
                color: AppColors.enterpriseTextMain,
                size: 16,
              ),
              label: Text(
                'Kembali & Edit Form',
                style: AppTextStyles.labelMedium.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        BeritaAcaraActionButtons(
          isPdfBusy: _isPdfBusy,
          isShareBusy: _isShareBusy,
          onPdf: () => _printPdf(context, monitoring),
          onShare: () => _shareSummary(context, monitoring),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/monitoring/lapangan/riwayat');
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_outlined,
                  color: AppColors.enterprisePrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Kembali ke Menu Riwayat Monitoring',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: AppColors.enterprisePrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _printPdf(
    BuildContext context,
    MonitoringModel monitoring,
  ) async {
    if (_isBusy) return;
    setState(() => _isPdfBusy = true);
    try {
      await BaPdfGenerator.printAndShare(monitoring);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyiapkan PDF. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfBusy = false);
    }
  }

  Future<void> _shareSummary(
    BuildContext context,
    MonitoringModel monitoring,
  ) async {
    if (_isBusy) return;
    setState(() => _isShareBusy = true);
    final text =
        'RINGKASAN BERITA ACARA MONITORING\n'
        'Perumahan: ${monitoring.namaPerumahan}\n'
        'Nomor BA: ${monitoring.nomorSuratBA}\n'
        'Status: ${monitoring.statusHasilEvaluasi.label}';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka menu berbagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isShareBusy = false);
    }
  }
}
