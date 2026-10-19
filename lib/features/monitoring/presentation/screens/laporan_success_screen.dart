import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../widgets/berita_acara_action_buttons.dart';
import '../widgets/berita_acara_document_card.dart';
import '../../utils/ba_pdf_generator.dart';

class LaporanSuccessScreen extends StatefulWidget {
  final MonitoringModel monitoring;

  const LaporanSuccessScreen({super.key, required this.monitoring});

  @override
  State<LaporanSuccessScreen> createState() => _LaporanSuccessScreenState();
}

class _LaporanSuccessScreenState extends State<LaporanSuccessScreen> {
  bool _isPdfBusy = false;
  bool _isShareBusy = false;

  bool get _isBusy => _isPdfBusy || _isShareBusy;

  @override
  Widget build(BuildContext context) {
    final item = widget.monitoring;

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/monitoring/lapangan'),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        title: Text(
          'Berita Acara Generated',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _buildSuccessState(),
              const SizedBox(height: 24),
              BeritaAcaraDocumentCard(
                monitoring: item,
                isSuccessContext: true,
              ),
              const SizedBox(height: 24),
              BeritaAcaraActionButtons(
                isPdfBusy: _isPdfBusy,
                isShareBusy: _isShareBusy,
                onPdf: () => _printPdf(context, item),
                onShare: () => _shareSummary(context, item),
              ),
              const SizedBox(height: 20),
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() => Column(
    children: [
      Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          color: AppColors.enterpriseSuccessSurface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.enterpriseSuccess,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Laporan Berhasil Dibuat!',
        style: AppTextStyles.headlineSmall.copyWith(
          fontFamily: AppTextStyles.enterpriseFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.enterpriseTextMain,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Berita Acara Monitoring & Evaluasi Lapangan resmi telah diterbitkan oleh sistem.',
          style: AppTextStyles.bodyMedium.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontSize: 13,
            color: AppColors.enterpriseTextMuted,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  Widget _buildBottomNavigation(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/monitoring/lapangan/riwayat'),
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
    );
  }

  Future<void> _printPdf(BuildContext context, MonitoringModel item) async {
    if (_isBusy) return;
    setState(() => _isPdfBusy = true);
    try {
      await BaPdfGenerator.printAndShare(item);
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'PDF belum dapat disiapkan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isPdfBusy = false);
    }
  }

  Future<void> _shareSummary(BuildContext context, MonitoringModel item) async {
    if (_isBusy) return;
    setState(() => _isShareBusy = true);
    try {
      await SharePlus.instance.share(ShareParams(text: _shareText(item)));
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Menu berbagi tidak dapat dibuka. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isShareBusy = false);
    }
  }

  String _shareText(MonitoringModel item) =>
      'RINGKASAN BERITA ACARA MONITORING\n'
      'Perumahan: ${item.namaPerumahan}\n'
      'Nomor BA: ${item.nomorSuratBA}\n'
      'Status: ${item.statusHasilEvaluasi.label}';

  void _showError(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
