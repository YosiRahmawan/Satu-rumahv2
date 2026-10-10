import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
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

  TextStyle get _titleStyle => AppTextStyles.headlineLarge.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    color: AppColors.enterpriseTextMain,
  );

  TextStyle get _bodyStyle => AppTextStyles.bodyMedium.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    color: AppColors.enterpriseTextMuted,
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.monitoring;
    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/monitoring/lapangan'),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        title: Text(
          'Berita Acara Generated',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              _buildSuccessState(item),
              const SizedBox(height: AppSpacing.lg),
              _buildDocumentCard(item),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(MonitoringModel item) => Column(
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: AppColors.enterpriseSuccessSurface,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            size: 48,
            color: AppColors.enterpriseSuccess,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Berita Acara Lokal Siap',
        style: _titleStyle,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        'Berita Acara monitoring untuk ${item.namaPerumahan} telah dibuat di perangkat ini dan siap dipreview atau dibagikan sebagai ringkasan. Dokumen belum diterbitkan atau dikonfirmasi server.',
        style: _bodyStyle,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildDocumentCard(MonitoringModel item) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.enterpriseSurface,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.enterpriseBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance,
              color: AppColors.enterprisePrimary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PEMERINTAH KOTA TASIKMALAYA', style: _labelStyle(true)),
                  const SizedBox(height: 2),
                  Text(
                    'DINAS PERUMAHAN DAN KAWASAN PERMUKIMAN',
                    style: _smallMutedStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: AppColors.enterpriseTextMain, height: 1),
        ),
        Text(
          'BERITA ACARA MONITORING DAN EVALUASI LAPANGAN',
          style: _labelStyle(true, size: 16),
        ),
        const SizedBox(height: 16),
        _dataRow('Nomor BA', item.nomorSuratBA),
        _dataRow('Perumahan', item.namaPerumahan),
        _dataRow(
          'Lokasi',
          item.lokasiPerumahan.isEmpty ? 'Belum diisi' : item.lokasiPerumahan,
        ),
        _dataRow('Tanggal', _formatDate(item.tanggalMonitoring)),
        _dataRow('Status', item.statusHasilEvaluasi.label),
        if (item.namaDeveloper.isNotEmpty)
          _dataRow('Pengembang', item.namaDeveloper),
      ],
    ),
  );

  Widget _dataRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 82, child: Text(label, style: _smallMutedStyle)),
        Text(': ', style: _smallMutedStyle),
        Expanded(child: Text(value, style: _valueStyle)),
      ],
    ),
  );

  Widget _buildActions(BuildContext context, MonitoringModel item) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isBusy ? null : () => _printPdf(context, item),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.enterprisePrimary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          ),
          icon: _isPdfBusy
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
            _isPdfBusy ? 'Menyiapkan PDF...' : 'Download / Cetak PDF',
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isBusy ? null : () => _shareSummary(context, item),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.enterpriseSuccess,
            side: const BorderSide(color: AppColors.enterpriseSuccess),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          ),
          icon: _isShareBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share),
          label: Text(
            _isShareBusy ? 'Membuka menu berbagi...' : 'Bagikan ringkasan',
          ),
        ),
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: () => context.go('/monitoring/lapangan/riwayat'),
        icon: const Icon(Icons.list_alt, color: AppColors.enterprisePrimary),
        label: Text(
          'Kembali ke Riwayat Monitoring',
          style: AppTextStyles.labelLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterprisePrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

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
      'RINGKASAN BERITA ACARA MONITORING (DIBUAT LOKAL)\nPerumahan: ${item.namaPerumahan}\nNomor BA: ${item.nomorSuratBA}\nStatus: ${item.statusHasilEvaluasi.label}';

  bool get _isBusy => _isPdfBusy || _isShareBusy;

  void _showError(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  TextStyle _labelStyle(bool bold, {double size = 14}) =>
      AppTextStyles.labelLarge.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: AppColors.enterpriseTextMain,
      );

  TextStyle get _smallMutedStyle => AppTextStyles.bodySmall.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    color: AppColors.enterpriseTextMuted,
  );

  TextStyle get _valueStyle => AppTextStyles.bodyMedium.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    color: AppColors.enterpriseTextMain,
    fontWeight: FontWeight.w600,
  );
}
