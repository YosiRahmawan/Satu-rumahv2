import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_verifikasi_controller.dart';
import 'detail_perbarui_dokumen_screen.dart';
import 'status_perbaikan_berkas_screen.dart';
import '../widgets/konfirmasi_kirim_perbaikan_dialog.dart';

/// Item model lokal untuk dokumen yang memerlukan revisi pada halaman Perbarui Berkas.
class _DocRevisiData {
  final String key;
  final String number;
  final String title;
  final String catatan;
  final bool isMultipleFiles;
  final int fileCount;
  final String? formatHint;
  String status; // 'Sudah Diperbarui' | 'Perlu Perbaikan'
  String fileName;
  String fileSize;
  String uploadTime;
  List<String> files;

  _DocRevisiData({
    required this.key,
    required this.number,
    required this.title,
    required this.catatan,
    required this.status,
    required this.fileName,
    required this.fileSize,
    required this.uploadTime,
    this.isMultipleFiles = false,
    this.fileCount = 1,
    this.formatHint,
    this.files = const [],
  });
}

/// Halaman "Perbarui Berkas" Pengembang
/// Berdasarkan spesifikasi visual Prototype/Pase 1 - Perbaikan.png & design.md.
class PerbaruiBerkasScreen extends ConsumerStatefulWidget {
  final String id;

  const PerbaruiBerkasScreen({super.key, required this.id});

  @override
  ConsumerState<PerbaruiBerkasScreen> createState() =>
      _PerbaruiBerkasScreenState();
}

class _PerbaruiBerkasScreenState extends ConsumerState<PerbaruiBerkasScreen> {
  bool _isVerifiedExpanded = true;
  bool _isPillExpanded = false;
  String _lastSavedTime = '10:24';
  bool _isSubmittingRevisi = false;

  late List<_DocRevisiData> _revisiDocs;

  // Daftar 17 dokumen yang sudah terverifikasi dan terkunci
  static const List<String> _lockedVerifiedDocs = [
    'NPWP Perusahaan',
    'Akta Pendirian Perusahaan',
    'Nomor Induk Berusaha (NIB)',
    'KTA Asosiasi Pengembang (REI/APERSI)',
    'Surat Permohonan Pengesahan Site Plan',
    'Keterangan Rencana Kota (KRK)',
    'Perjanjian Penyediaan Lahan TPU',
    'Kesesuaian Pemanfaatan Ruang (KKPR)',
    'PBG Induk Persetujuan Bangunan',
    'Dokumen Lingkungan (UKL-UPL DLH)',
    'Surat Pelepasan Hak Kas Desa',
    'Surat Pernyataan Keabsahan Dokumen',
    'Surat Kesanggupan Penyerahan PSU',
    'Rekomendasi Andalalin Dishub',
    'Peta Kontur & Elevasi Tanah',
    'Laporan Soil Test Geoteknik',
    'Surat Keterangan Bebas Banjir',
  ];

  @override
  void initState() {
    super.initState();
    _revisiDocs = [
      _DocRevisiData(
        key: 'ktp',
        number: '1',
        title: 'KTP Direktur / Penanggung Jawab',
        catatan: 'Catatan: Pindaian buram, tanda tangan terpotong',
        status: 'Sudah Diperbarui',
        fileName: 'KTP_Direktur_GreenTasik_Revisi.pdf',
        fileSize: '1.8 MB',
        uploadTime: 'Diunggah 10:15 WIB',
      ),
      _DocRevisiData(
        key: 'bukti_kepemilikan_lahan',
        number: '2',
        title: 'Sertifikat Hak Atas Tanah (SHGB / SHM)',
        catatan:
            'Catatan: Masa berlaku SK hak perlu diverifikasi ulang lampiran BPN',
        status: 'Perlu Perbaikan',
        fileName: 'SHGB_No401_GreenTasik.pdf (4.2 MB)',
        fileSize: '4.2 MB',
        uploadTime: '12 Sep 2026',
        formatHint: 'Perlu diganti dokumen baru',
      ),
      _DocRevisiData(
        key: 'site_plan_dwg',
        number: '3',
        title: 'Dokumen Perencanaan & Perancangan Site Plan',
        catatan: 'Catatan: Lampirkan file DWG AutoCAD dan PDF skala 1:1000',
        status: 'Perlu Perbaikan',
        fileName: 'siteplan_topografi_v1.dwg',
        fileSize: '12.4 MB',
        uploadTime: '12 Sep 2026',
        isMultipleFiles: true,
        fileCount: 3,
        formatHint: 'Format didukung: DWG dan PDF (BR-004), maks 50 MB',
        files: ['siteplan_utama.dwg', 'denah_rth.dwg', 'peta_utilitas.pdf'],
      ),
    ];
  }

  Pengajuan? _findSubmission() {
    final list = ref.watch(pengajuanListProvider);
    final targetId = widget.id.trim();
    if (targetId.isNotEmpty) {
      for (final item in list) {
        if (item.id == targetId) return item;
      }
    }
    // Fallback default untuk testing/prototype
    return list.isNotEmpty ? list.first : null;
  }

  int get _completedCount =>
      _revisiDocs.where((d) => d.status == 'Sudah Diperbarui').length;

  int get _totalCount => _revisiDocs.length;

  int get _remainingCount => _totalCount - _completedCount;

  double get _progress =>
      _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    final submission = _findSubmission();
    final namaPerumahan = submission?.namaPerumahan ?? 'Perumahan Green Tasik';
    final regId =
        submission?.id ?? (widget.id.isNotEmpty ? widget.id : 'REG-2026-0142');

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── 1. HEADER MERAH BRAND SATU RUMAH ────────────────────────────
            _buildHeader(context, namaPerumahan, regId),

            // ─── KONTEN SCROLLABLE ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 2. PROGRESS PERBAIKAN BERKAS ────────────────────────
                    _buildProgressCard(),

                    // ─── 3. CATATAN DARI ADMIN VERIFIKATOR ───────────────────
                    _buildCatatanVerifikatorBox(context),

                    // ─── 4. SECTION PERLU DIPERBAIKI (3) ─────────────────────
                    _buildSectionPerluDiperbaikiHeader(),

                    // Kartu 1: KTP Direktur (Sudah Diperbarui)
                    _buildDocCardItem(context, _revisiDocs[0]),

                    // Kartu 2: Sertifikat Hak Atas Tanah (Perlu Perbaikan)
                    _buildDocCardItem(context, _revisiDocs[1]),

                    // Kartu 3: Dokumen Perencanaan Site Plan (Multi-file)
                    _buildDocCardItem(context, _revisiDocs[2]),

                    // ─── 5. SECTION TERVERIFIKASI DAN TERKUNCI (17) ──────────
                    _buildSectionTerverifikasiTerkunci(),

                    const SizedBox(
                      height: 100,
                    ), // Spacing for sticky bottom bar
                  ],
                ),
              ),
            ),

            // ─── 6. STICKY BOTTOM ACTION BAR ─────────────────────────────────
            _buildBottomActionBar(context, submission),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String perumahan, String regId) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.zero,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        MediaQuery.of(context).padding.top + 8,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Kembali',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/pengajuan/detail/$regId');
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Perbarui Berkas',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Right Pill: "Perumahan Green Tasik • REG-2026-0142" (Interactive tap to reveal continuation)
          Flexible(
            child: Tooltip(
              message: _isPillExpanded
                  ? 'Ketuk untuk meringkas'
                  : '$perumahan • $regId',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _isPillExpanded = !_isPillExpanded;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: _isPillExpanded ? 0.32 : 0.22,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: _isPillExpanded ? 0.35 : 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      '$perumahan • $regId',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: _isPillExpanded ? 3 : 1,
                      overflow: _isPillExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. PROGRESS CARD ──────────────────────────────────────────────────────
  Widget _buildProgressCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Berkas yang sudah diperbarui',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$_completedCount/$_totalCount Berkas',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 7,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Perbarui semua berkas yang ditandai sebelum mengirim',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. CATATAN DARI ADMIN VERIFIKATOR ─────────────────────────────────────
  Widget _buildCatatanVerifikatorBox(BuildContext context) {
    const noteText =
        'Mohon lakukan revisi pada KTP Penanggung Jawab karena pindaian buram dan nomor NIK tidak terbaca jelas. Pada Site Plan, lampirkan format DWG dan PDF terbaru yang memuat garis sempadan bangunan sesuai revisi Dinas PUPR.';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'CATATAN DARI ADMIN VERIFIKATOR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            noteText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate700,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final isLargeScale =
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              if (isLargeScale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oleh: Hendra Wijaya, S.T. (Verifikator) • 18 Mar 2026',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showFullNoteDialog(context, noteText),
                      child: Text(
                        'Selengkapnya',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Oleh: Hendra Wijaya, S.T. (Verifikator) • 18 Mar 2026',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showFullNoteDialog(context, noteText),
                    child: Text(
                      'Selengkapnya',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFullNoteDialog(BuildContext context, String note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rate_review_outlined, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Text('Catatan Verifikator', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Verifikator: Hendra Wijaya, S.T.\nTanggal: 18 Maret 2026, 09:30 WIB\nInstansi: Dinas Perumahan dan Kawasan Permukiman Kota Tasikmalaya',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. SECTION PERLU DIPERBAIKI (3) HEADER ────────────────────────────────
  Widget _buildSectionPerluDiperbaikiHeader() {
    return Builder(
      builder: (context) {
        final isLargeScale = MediaQuery.textScalerOf(context).scale(1) > 1.2;

        if (isLargeScale) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perlu Diperbaiki ($_totalCount)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tindakan Wajib',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Perlu Diperbaiki ($_totalCount)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tindakan Wajib',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── DOCUMENT CARD ITEM (GENERIC UNTUK DOKUMEN 1, 2, 3) ───────────────────
  Widget _buildDocCardItem(BuildContext context, _DocRevisiData doc) {
    final isSudahDiperbarui = doc.status == 'Sudah Diperbarui';
    final hasAmberBorder = !isSudahDiperbarui;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAmberBorder
              ? const Color(0xFFFDE68A)
              : AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris 1: Nomor & Judul Dokumen + Status Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScale =
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;

              Widget buildBadge() {
                if (isSudahDiperbarui) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sudah Diperbarui',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!doc.isMultipleFiles) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Perlu Perbaikan',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              if (isLargeScale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${doc.number}. ${doc.title}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        fontSize: 14,
                      ),
                    ),
                    if (isSudahDiperbarui || !doc.isMultipleFiles) ...[
                      const SizedBox(height: 6),
                      buildBadge(),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${doc.number}. ${doc.title}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isSudahDiperbarui || !doc.isMultipleFiles) buildBadge(),
                ],
              );
            },
          ),

          // Khusus Dokumen 3 (Multi-file chips)
          if (doc.isMultipleFiles) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PDF, banyak file',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${doc.fileCount} file',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSudahDiperbarui
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSudahDiperbarui
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSudahDiperbarui
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 12,
                          color: isSudahDiperbarui
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSudahDiperbarui
                              ? 'Sudah Diperbarui'
                              : 'Perlu Perbaikan',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                            color: isSudahDiperbarui
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Catatan sub-box (Merah muda)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc.catatan,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF991B1B),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // File info box (Abu-abu terang)
          if (!doc.isMultipleFiles || isSudahDiperbarui)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLargeScale =
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;

                  Widget buildPratinjauBtn() {
                    return InkWell(
                      onTap: () => _showPreviewDialog(context, doc),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: AppColors.slate700,
                            ),
                            const SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Pratinjau',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.slate700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (isLargeScale) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSudahDiperbarui) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFFB91C1C),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.fileName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (isSudahDiperbarui)
                                    Text(
                                      '${doc.fileSize} • ${doc.uploadTime}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                    )
                                  else if (doc.formatHint != null)
                                    Text(
                                      doc.formatHint!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: const Color(0xFFD97706),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        buildPratinjauBtn(),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      if (isSudahDiperbarui) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFFB91C1C),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (isSudahDiperbarui)
                              Text(
                                '${doc.fileSize} • ${doc.uploadTime}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              )
                            else if (doc.formatHint != null)
                              Text(
                                doc.formatHint!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: const Color(0xFFD97706),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      buildPratinjauBtn(),
                    ],
                  );
                },
              ),
            ),

          // Format hint untuk Multi-file ketika belum diperbarui
          if (doc.isMultipleFiles &&
              !isSudahDiperbarui &&
              doc.formatHint != null) ...[
            Text(
              doc.formatHint!,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.slate500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol Aksi Bawah: Ubah Berkas / Perbarui Berkas
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isSudahDiperbarui
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handlePickAndReplaceFile(context, doc),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        doc.isMultipleFiles
                            ? 'Ubah Berkas (3 File)'
                            : 'Ubah Berkas',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handlePickAndReplaceFile(context, doc),
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        doc.isMultipleFiles
                            ? 'Perbarui Berkas (${doc.fileCount} File)'
                            : 'Perbarui Berkas',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 5. SECTION TERVERIFIKASI DAN TERKUNCI (17) ────────────────────────────
  Widget _buildSectionTerverifikasiTerkunci() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terverifikasi dan Terkunci (${_lockedVerifiedDocs.length})',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                // Header Accordion
                InkWell(
                  onTap: () {
                    setState(() {
                      _isVerifiedExpanded = !_isVerifiedExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.slate600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_lockedVerifiedDocs.length} Berkas Sudah Terverifikasi',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tidak dapat diubah atau dihapus',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isVerifiedExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.slate600,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded List
                if (_isVerifiedExpanded) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Berkas ini sudah diverifikasi oleh tim Disperwaskim dan tidak dapat diubah.',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.slate600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lockedVerifiedDocs.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final docName = _lockedVerifiedDocs[index];
                            final isLargeScale =
                                MediaQuery.textScalerOf(context).scale(1) > 1.15;

                            Widget buildBadges() {
                              return Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Badge Terkunci
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_rounded,
                                          size: 10,
                                          color: Color(0xFF475569),
                                        ),
                                        const SizedBox(width: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Terkunci',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  fontSize: 10,
                                                  color:
                                                      const Color(0xFF475569),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badge Terverifikasi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Terverifikasi',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: const Color(0xFF16A34A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (isLargeScale) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  buildBadges(),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    docName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                buildBadges(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. STICKY BOTTOM ACTION BAR ───────────────────────────────────────────
  Widget _buildBottomActionBar(BuildContext context, Pengajuan? submission) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-row: Simpan Sementara & Timestamp auto-save
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: InkWell(
                  onTap: () {
                    final now = DateFormat('HH:mm').format(DateTime.now());
                    setState(() {
                      _lastSavedTime = now;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Draft perbaikan berkas berhasil disimpan sementara.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Simpan Sementara',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tersimpan otomatis pukul $_lastSavedTime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.slate400,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Utama "Tinjau Perbaikan"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _handleTinjauPerbaikan(submission),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tinjau Perbaikan',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Caption di bawah tombol
          Text(
            _remainingCount > 0
                ? 'Perbarui $_remainingCount berkas lagi untuk melanjutkan'
                : 'Semua berkas siap ditinjau dan dikirim',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── FILE PICKER & REPLACEMENT LOGIC (FASE 3 NAVIGASI) ────────────────────
  Future<void> _handlePickAndReplaceFile(
    BuildContext context,
    _DocRevisiData doc,
  ) async {
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => DetailPerbaruiDokumenScreen(
            pengajuanId: widget.id,
            docKey: doc.key,
            docData: {
              'title': doc.title,
              'catatan': doc.catatan,
              'fileName': doc.fileName,
              'fileSize': doc.fileSize,
              'status': doc.status,
              'isMultipleFiles': doc.isMultipleFiles,
              'revisiFileName': doc.key == 'ktp'
                  ? 'KTP_Direktur_Revisi_2026.pdf'
                  : (doc.isMultipleFiles
                      ? 'SitePlan_Revisi_Final_2026.dwg'
                      : 'SHGB_No401_GreenTasik_Revisi.pdf'),
              'revisiFileSize': doc.key == 'ktp'
                  ? '2.1 MB'
                  : (doc.isMultipleFiles ? '14.2 MB' : '4.5 MB'),
            },
          ),
        ),
      );

      if (result != null) {
        final now = DateFormat('HH:mm').format(DateTime.now());
        setState(() {
          doc.status = 'Sudah Diperbarui';
          doc.uploadTime = 'Diunggah $now WIB';
          if (result['fileName'] != null) {
            doc.fileName = result['fileName'] as String;
          }
          if (result['fileSize'] != null) {
            doc.fileSize = result['fileSize'] as String;
          }
        });

        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berkas "${doc.title}" berhasil diperbarui.'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to detail perbarui dokumen: $e');
    }
  }

  // ─── MODAL PREVIEW FILE ───────────────────────────────────────────────────
  void _showPreviewDialog(BuildContext context, _DocRevisiData doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(ctx).padding.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pratinjau Dokumen',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.fileName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ukuran: ${doc.fileSize} • Status: ${doc.status}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 48,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pratinjau Digital Dokumen Sah',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dokumen terdaftar resmi dalam sistem SATU RUMAH',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup Pratinjau'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TINJAU PERBAIKAN CONFIRMATION / SUBMIT (FASE 4) ──────────────────────
  Future<void> _handleTinjauPerbaikan(
    Pengajuan? submission,
  ) async {
    if (_remainingCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text('Berkas Belum Lengkap', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Masih ada $_remainingCount berkas yang perlu diperbarui sebelum Anda dapat mengirimkan revisi ke verifikator Disperwaskim.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Lengkapi Sekarang',
                style: TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_isSubmittingRevisi) return;

    final updatedCount =
        _revisiDocs.where((d) => d.status == 'Sudah Diperbarui').length;

    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showKonfirmasiKirimPerbaikanDialog(
      context: context,
      jumlahBerkas: updatedCount > 0 ? updatedCount : _revisiDocs.length,
      onConfirm: () async {
        _isSubmittingRevisi = true;
        final id = submission?.id ?? widget.id;
        final mapDocs = {
          for (final d in _revisiDocs) d.key: d.fileName,
        };
        ref
            .read(pengajuanVerifikasiControllerProvider.notifier)
            .kirimRevisi(id, mapDocs);
      },
    );

    if (confirmed == true && mounted) {
      final id = submission?.id ?? widget.id;
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Revisi berkas berhasil dikirim ke Verifikator!',
              ),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatusPerbaikanBerkasScreen(
            pengajuanId: id,
          ),
        ),
      );
    }
  }
}
