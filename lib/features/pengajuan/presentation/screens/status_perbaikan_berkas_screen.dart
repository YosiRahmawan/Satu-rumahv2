import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../providers/pengajuan_form_controller.dart';
import 'pengajuan_detail_screen.dart';

/// Layar konfirmasi setelah berkas perbaikan terkirim. Isinya hanya data pengajuan yang nyata;
/// riwayat versi berkas ada di layar rincian pengajuan.
class StatusPerbaikanBerkasScreen extends ConsumerStatefulWidget {
  final String pengajuanId;

  const StatusPerbaikanBerkasScreen({
    super.key,
    this.pengajuanId = 'REG-2026-0142',
  });

  @override
  ConsumerState<StatusPerbaikanBerkasScreen> createState() =>
      _StatusPerbaikanBerkasScreenState();
}

class _StatusPerbaikanBerkasScreenState
    extends ConsumerState<StatusPerbaikanBerkasScreen> {
  // Waktu layar ini dibuka = waktu perbaikan terkirim.
  final DateTime _dikirim = DateTime.now();

  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Tanpa data locale supaya tidak bergantung pada inisialisasi intl.
  static String _format(DateTime d) =>
      '${d.day} ${_bulan[d.month - 1]} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

  void _handleLihatDetail() {
    if (!mounted) return;
    try {
      context.go('/pengajuan/detail/${widget.pengajuanId}');
    } catch (_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PengajuanDetailScreen(id: widget.pengajuanId),
        ),
      );
    }
  }

  void _handleKembaliKeBeranda() {
    if (!mounted) return;
    try {
      context.go('/dashboard');
    } catch (_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengajuan = ref
        .watch(pengajuanListProvider)
        .where((p) => p.id == widget.pengajuanId)
        .firstOrNull;
    final waktu = _format(_dikirim);

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.slate800,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              _handleLihatDetail();
            }
          },
        ),
        title: Text(
          'Status Pengajuan',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: AppIllustration(AppIllustration.semuaBeres, width: 170),
              ),
              const SizedBox(height: 16),
              Text(
                'Perbaikan Berhasil Dikirim',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tim Verifikator Disperwaskim akan memeriksa kembali berkas Anda dalam 1–3 hari kerja. '
                'Anda akan diberi tahu lewat notifikasi.',
                key: Key('perbaikan-penjelasan'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.enterpriseBorder),
                ),
                child: Column(
                  children: [
                    _baris('Nomor pengajuan', widget.pengajuanId),
                    if (pengajuan != null)
                      _baris('Perumahan', pengajuan.namaPerumahan),
                    _baris('Dikirim', '$waktu WIB'),
                    _baris(
                      'Status',
                      'Dalam proses pemeriksaan',
                      terakhir: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleLihatDetail,
                  child: const Text('Lihat Detail Pengajuan'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _handleKembaliKeBeranda,
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(String label, String nilai, {bool terakhir = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: terakhir
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.enterpriseBorder),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
