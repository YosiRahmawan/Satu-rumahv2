import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';

typedef DetailFilePickerSeam =
    Future<PlatformFile?> Function({List<String>? allowedExtensions});

/// Halaman Detail Penggantian Satu Dokumen (Fase 3 - Perbaikan Berkas)
/// Sesuai spesifikasi visual Prototype/Pase 3 - Perbaikan.png & design.md.
class DetailPerbaruiDokumenScreen extends ConsumerStatefulWidget {
  final String pengajuanId;
  final String docKey;
  final Map<String, dynamic>? docData;
  final DetailFilePickerSeam? pickerSeam;

  const DetailPerbaruiDokumenScreen({
    super.key,
    required this.pengajuanId,
    required this.docKey,
    this.docData,
    this.pickerSeam,
  });

  @override
  ConsumerState<DetailPerbaruiDokumenScreen> createState() =>
      _DetailPerbaruiDokumenScreenState();
}

class _DetailPerbaruiDokumenScreenState
    extends ConsumerState<DetailPerbaruiDokumenScreen> {
  late TextEditingController _catatanController;
  String? _selectedFileName;
  String? _selectedFileSize;

  @override
  void initState() {
    super.initState();
    final defaultCatatan =
        widget.docData?['catatanPengembang'] as String? ??
        'Sudah dipindai ulang dengan resolusi 300 DPI warna jelas.';
    _catatanController = TextEditingController(text: defaultCatatan);

    // Default file terpilih sesuai acceptance prototype Fase 3
    _selectedFileName =
        widget.docData?['revisiFileName'] as String? ??
        'KTP_Direktur_Revisi_2026.pdf';
    _selectedFileSize =
        widget.docData?['revisiFileSize'] as String? ?? '2.1 MB';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  String get _documentTitle {
    if (widget.docData != null && widget.docData!['title'] != null) {
      final title = widget.docData!['title'] as String;
      if (title.contains('KTP')) return 'KTP Penanggung Jawab';
      return title;
    }
    switch (widget.docKey) {
      case 'ktp':
        return 'KTP Penanggung Jawab';
      case 'bukti_kepemilikan_lahan':
        return 'Sertifikat Hak Atas Tanah';
      case 'site_plan_dwg':
        return 'Site Plan Perumahan';
      default:
        return 'Dokumen Pengajuan';
    }
  }

  String get _adminReason {
    if (widget.docData != null && widget.docData!['catatan'] != null) {
      final c = widget.docData!['catatan'] as String;
      return c.replaceFirst(RegExp(r'^Catatan:\s*'), '');
    }
    return 'Scan buram, nomor NIK dan tanda tangan pada halaman depan tidak terbaca jelas saat verifikasi keabsahan.';
  }

  String get _oldFileName {
    if (widget.docData != null && widget.docData!['fileName'] != null) {
      return widget.docData!['fileName'] as String;
    }
    return 'KTP_Direktur_Lama.pdf';
  }

  String get _oldFileSize {
    if (widget.docData != null && widget.docData!['fileSize'] != null) {
      return widget.docData!['fileSize'] as String;
    }
    return '1.2 MB';
  }

  Future<void> _handlePickFile() async {
    try {
      final isSitePlan = widget.docKey == 'site_plan_dwg';
      final allowedExtensions = isSitePlan
          ? ['pdf', 'dwg']
          : ['pdf', 'jpg', 'png'];
      final picked = widget.pickerSeam != null
          ? await widget.pickerSeam!(allowedExtensions: allowedExtensions)
          : await FilePickerUtil.pickSingleFile(
              allowedExtensions: allowedExtensions,
            );

      if (picked == null) return;

      final maxBytes = isSitePlan ? 50 * 1024 * 1024 : 10 * 1024 * 1024;
      if (picked.size > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File melebihi batas maksimal ${maxBytes ~/ (1024 * 1024)} MB. Berkas lama tetap tersimpan.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _selectedFileName = picked.name;
        _selectedFileSize =
            '${(picked.size / (1024 * 1024)).toStringAsFixed(1)} MB';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Berkas tidak dapat dipilih. Berkas lama tetap tersimpan.',
          ),
        ),
      );
    }
  }

  void _handleKirimPerbaikan() {
    if (_selectedFileName == null) return;

    Navigator.of(context).pop<Map<String, dynamic>>({
      'docKey': widget.docKey,
      'fileName': _selectedFileName,
      'fileSize': _selectedFileSize,
      'catatan': _catatanController.text.trim(),
    });
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
              height: 220,
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
                    size: 56,
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
            const SizedBox(height: 12),
            Text(
              'Dokumen ini tersimpan secara lokal pada sesi aktif pengembang.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
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

  void _showRiwayatVersiModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat Versi Dokumen (2 Versi)',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Daftar pembaruan dokumen ini sejak pengajuan verifikasi.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _buildRiwayatCard(
                versionLabel: 'Versi 2 (Revisi Siap Kirim)',
                badgeLabel: 'Siap Diunggah',
                badgeBg: AppColors.statusSuccessSurface,
                badgeFg: AppColors.statusSuccessText,
                fileName: _selectedFileName ?? 'KTP_Direktur_Revisi_2026.pdf',
                metaText:
                    '${_selectedFileSize ?? '2.1 MB'} • 14 Mar 2026, 10:20 WIB',
                noteText:
                    'Catatan Pengembang: ${_catatanController.text.trim()}',
                iconColor: AppColors.statusSuccessText,
              ),
              const SizedBox(height: 12),
              _buildRiwayatCard(
                versionLabel: 'Versi 1 (Ditolak Verifikator)',
                badgeLabel: 'Ditolak',
                badgeBg: const Color(0xFFFEE2E2),
                badgeFg: const Color(0xFFDC2626),
                fileName: _oldFileName,
                metaText: '$_oldFileSize • 12 Mar 2026, 09:15 WIB',
                noteText: 'Catatan Admin: $_adminReason',
                iconColor: const Color(0xFFDC2626),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMain,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatCard({
    required String versionLabel,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeFg,
    required String fileName,
    required String metaText,
    required String noteText,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                versionLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      metaText,
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
          const SizedBox(height: 8),
          Text(
            noteText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate600,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isHighTextScale = textScaler.scale(14) > 20;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _documentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Perbarui Berkas • ${widget.pengajuanId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardAlasanAdmin(),
            const SizedBox(height: 16),
            _buildCardBerkasDitolak(isHighTextScale),
            const SizedBox(height: 16),
            _buildCardUnggahPengganti(isHighTextScale),
            const SizedBox(height: 16),
            _buildCardCatatanAdmin(),
            const SizedBox(height: 20),
            _buildLinkRiwayatVersi(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomActionBar(isHighTextScale),
    );
  }

  // ─── 1. WIDGET CARD: ALASAN PERBAIKAN DARI ADMIN ───────────────────────────
  Widget _buildCardAlasanAdmin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alasan Perbaikan dari Admin',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB91C1C),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _adminReason,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Oleh Tim Verifikator Disperwaskim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '14 Mar 2026',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. WIDGET CARD: BERKAS SAAT INI (DITOLAK) ─────────────────────────────
  Widget _buildCardBerkasDitolak(bool isHighTextScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BERKAS SAAT INI (DITOLAK)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Versi 1',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: isHighTextScale
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.primaryRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _oldFileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_oldFileSize • Diunggah 12 Mar 2026',
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
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: const BorderSide(color: AppColors.slate300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _showPratinjauDialog(
                          _oldFileName,
                          'Berkas Saat Ini (Ditolak) - Versi 1',
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Pratinjau',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.primaryRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _oldFileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_oldFileSize • Diunggah 12 Mar 2026',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: const BorderSide(color: AppColors.slate300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _showPratinjauDialog(
                          _oldFileName,
                          'Berkas Saat Ini (Ditolak) - Versi 1',
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Pratinjau',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 3. WIDGET CARD: UNGGAH BERKAS PENGGANTI ───────────────────────────────
  Widget _buildCardUnggahPengganti(bool isHighTextScale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'UNGGAH BERKAS PENGGANTI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                    letterSpacing: 0.4,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Wajib Diisi',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dashed Dropzone
          CustomPaint(
            painter: DashedBorderPainter(
              color: const Color(0xFFDC2626),
              strokeWidth: 1.5,
              dashWidth: 6,
              dashSpace: 4,
              borderRadius: 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFFB91C1C),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ketuk untuk memilih berkas PDF',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maks. 10 MB, format PDF (BR-002)',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handlePickFile,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text(
                      'Pilih Berkas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected File Section
          if (_selectedFileName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Berkas yang Dipilih:',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isHighTextScale)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Color(0xFF16A34A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFileName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMain,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _selectedFileSize ?? '2.1 MB',
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF15803D),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Siap Diunggah',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF15803D),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF16A34A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedFileSize ?? '2.1 MB',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF15803D),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Siap Diunggah',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF15803D),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: const BorderSide(color: AppColors.slate300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => _showPratinjauDialog(
                          _selectedFileName!,
                          'Berkas Pengganti (Siap Diunggah)',
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text(
                          'Pratinjau',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedFileName = null;
                            _selectedFileSize = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Info Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.slate500,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketentuan File: PDF max 10 MB (BR-002), DWG & PDF max 50 MB khusus berkas Site Plan (BR-004).',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate600,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. WIDGET CARD: CATATAN UNTUK ADMIN (OPSIONAL) ────────────────────────
  Widget _buildCardCatatanAdmin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan untuk Admin (Opsional)',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catatan pengembang terkait dokumen ini:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            maxLength: 250,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Tuliskan catatan penjelasan perbaikan...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.slate400,
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.all(12),
              counterText: '${_catatanController.text.length}/250 karakter',
              counterStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. WIDGET LINK: LIHAT RIWAYAT VERSI DOKUMEN ───────────────────────────
  Widget _buildLinkRiwayatVersi() {
    return InkWell(
      onTap: _showRiwayatVersiModal,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.history, color: Color(0xFFB91C1C), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lihat Riwayat Versi Dokumen (2 Versi)',
                style: AppTextStyles.labelMedium.copyWith(
                  color: const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB91C1C), size: 20),
          ],
        ),
      ),
    );
  }

  // ─── 6. STICKY BOTTOM ACTION BAR ───────────────────────────────────────────
  Widget _buildStickyBottomActionBar(bool isHighTextScale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isHighTextScale
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKirimPerbaikanButton(),
                const SizedBox(height: 8),
                _buildBatalButton(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _buildBatalButton()),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildKirimPerbaikanButton()),
              ],
            ),
    );
  }

  Widget _buildBatalButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          side: const BorderSide(color: AppColors.slate300, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Batal',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildKirimPerbaikanButton() {
    final isEnabled = _selectedFileName != null;
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB91C1C),
          disabledBackgroundColor: AppColors.slate200,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.slate400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isEnabled ? _handleKirimPerbaikan : null,
        icon: const Icon(Icons.check, size: 20),
        label: Text(
          'Kirim Perbaikan',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isEnabled ? Colors.white : AppColors.slate400,
          ),
        ),
      ),
    );
  }
}

/// Custom painter untuk garis putus-putus merah di area dropzone
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = dashWidth.clamp(0.0, metric.length - distance);
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.borderRadius != borderRadius;
}
