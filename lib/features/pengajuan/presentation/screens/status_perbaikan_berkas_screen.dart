import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/pengajuan_form_controller.dart';
import 'pengajuan_detail_screen.dart';

/// Halaman Status Perbaikan Berkas (Fase 5 - Status Perbaikan Berkas).
/// Berdasarkan spesifikasi visual Prototype/Pase 5 - Perbaikan.png & design.md.
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
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Text(
              'Bantuan Verifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Setelah perbaikan dikirim, Tim Verifikator Disperwaskim akan memeriksa kembali kesesuaian berkas dalam kurun waktu 1-3 hari kerja. Anda akan menerima notifikasi jika status diperbarui.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Mengerti',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showPratinjauDialog(String fileName, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pratinjau Dokumen',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.borderSubtle, height: 24),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: AppColors.primaryRed.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      fileName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pratinjau Digital Dokumen Sah',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup Pratinjau'),
            ),
          ),
        ],
      ),
    );
  }

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
    final list = ref.watch(pengajuanListProvider);
    final pengajuan = list.where((p) => p.id == widget.pengajuanId).firstOrNull;

    final namaPerumahan = pengajuan?.namaPerumahan ?? 'Perumahan Green Tasik';
    const lokasi = 'Kec. Tawang, Kota Tasikmalaya';
    final noRegistrasi = pengajuan?.id ?? widget.pengajuanId;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              size: 22,
              color: AppColors.slate700,
            ),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. ICON & HEADLINE SUKSES ────────────────────────────────
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF16A34A),
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Perbaikan Berhasil Dikirim',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.slate600,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    children: const [
                      TextSpan(
                        text:
                            'Status pengajuan Anda telah dikembalikan menjadi ',
                      ),
                      TextSpan(
                        text: 'Dalam Proses',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      TextSpan(
                        text:
                            '. Tim Verifikator Disperwaskim akan memeriksa kembali kelengkapan berkas.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // ─── 2. KARTU RINGKASAN PENGAJUAN ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 3 Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Badge Nomor Registrasi
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            noRegistrasi,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate700,
                            ),
                          ),
                        ),
                        // Badge Perbaikan ke-2
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Perbaikan ke-2',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        // Badge Dalam Proses
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 13,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Dalam Proses',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nama Perumahan & Lokasi
                    Text(
                      namaPerumahan,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lokasi,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.slate100, height: 1),
                    const SizedBox(height: 12),

                    // Detail info 1: Tanggal kirim
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate600,
                                fontSize: 12,
                              ),
                              children: const [
                                TextSpan(text: 'Dikirim pada '),
                                TextSpan(
                                  text: '18 Maret 2026, 10:45 WIB',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Detail info 2: Status dokumen
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate600,
                                fontSize: 12,
                              ),
                              children: const [
                                TextSpan(
                                  text: '3 berkas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                TextSpan(text: ' diperbarui • '),
                                TextSpan(
                                  text: '17 terverifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── 3. TOMBOL AKSI ───────────────────────────────────────────
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleLihatDetail,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Lihat Detail Pengajuan',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    foregroundColor: AppColors.slate800,
                    side: const BorderSide(
                      color: AppColors.slate300,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleKembaliKeBeranda,
                  child: Text(
                    'Kembali ke Beranda',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── 4. KARTU RIWAYAT VERSI BERKAS ────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle pill kecil di tengah
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Riwayat Versi Berkas',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'KTP Penanggung Jawab',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Slot No. 04',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── TIMELINE VERSI ─────────────────────────────────────
                    // Entry 1: Versi 2 (Terkirim)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Dot & Line
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Content Card
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Versi 2 (Terkirim)',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showPratinjauDialog(
                                          'KTP_Direktur_Revisi_2026.pdf',
                                          'Versi 2 (Terkirim)',
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.visibility_outlined,
                                              size: 14,
                                              color: AppColors.primaryRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pratinjau',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'KTP_Direktur_Revisi_2026.pdf',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '2.1 MB • 18 Mar 2026, 10:45 oleh PT Tasik Indah Sentosa',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Entry 2: Versi 1 (Ditolak)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dot
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Versi 1 (Ditolak)',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showPratinjauDialog(
                                        'KTP_Direktur_Lama.pdf',
                                        'Versi 1 (Ditolak)',
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.visibility_outlined,
                                            size: 14,
                                            color: AppColors.slate600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pratinjau',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'KTP_Direktur_Lama.pdf',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '1.2 MB • 12 Mar 2026, 14:10',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Kotak Catatan Verifikator
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFEE2E2),
                                    ),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: const Color(0xFFDC2626),
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Catatan Verifikator: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Scan buram, NIK tidak terbaca dengan jelas.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
