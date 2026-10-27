import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_verifikasi_controller.dart';
import 'detail_perbarui_dokumen_screen.dart';
import 'pengajuan_detail_screen.dart'
    show pengajuanDocTitle, pengajuanRevisionDocTitle;
import 'status_perbaikan_berkas_screen.dart';
import '../widgets/konfirmasi_kirim_perbaikan_dialog.dart';
import '../../../../core/widgets/app_illustration.dart';

/// Satu dokumen yang diminta revisi, diturunkan dari `Pengajuan` aktif
/// (`dokumenPerluRevisi`, `uploadedDocs`) plus berkas pengganti yang baru
/// dipilih pengguna di sesi ini.
class _DocRevisiData {
  final String key;
  final String number;
  final String title;
  final bool isMultipleFiles;
  final int fileCount;
  final String formatHint;
  final bool isUpdated;
  final String fileName;
  final String? fileSize;
  final String? uploadTime;

  const _DocRevisiData({
    required this.key,
    required this.number,
    required this.title,
    required this.isUpdated,
    required this.fileName,
    required this.formatHint,
    this.fileSize,
    this.uploadTime,
    this.isMultipleFiles = false,
    this.fileCount = 1,
  });
}

/// Berkas pengganti yang dipilih pengguna untuk satu dokumen.
class _DocUpdate {
  final String fileName;
  final String? fileSize;
  final String uploadTime;

  const _DocUpdate({
    required this.fileName,
    required this.fileSize,
    required this.uploadTime,
  });
}

const String _kVerifikatorBelumTersedia =
    'Informasi verifikator belum tersedia';

/// Halaman "Perbarui Berkas" Pengembang
/// Berdasarkan spesifikasi visual Prototype/Pase 1 - Perbaikan.png & design.md.
class PerbaruiBerkasScreen extends ConsumerStatefulWidget {
  final String id;

  /// Seam pemilih berkas untuk test; null memakai pemilih sistem.
  final DetailFilePickerSeam? pickerSeam;

  const PerbaruiBerkasScreen({super.key, required this.id, this.pickerSeam});

  @override
  ConsumerState<PerbaruiBerkasScreen> createState() =>
      _PerbaruiBerkasScreenState();
}

class _PerbaruiBerkasScreenState extends ConsumerState<PerbaruiBerkasScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _perluDiperbaikiKey = GlobalKey();
  bool _isVerifiedExpanded = true;
  String? _lastSavedTime;
  bool _isSubmittingRevisi = false;

  /// Berkas pengganti per kunci dokumen; daftar dokumennya sendiri selalu
  /// diturunkan dari pengajuan aktif.
  final Map<String, _DocUpdate> _updates = {};
  List<_DocRevisiData> _revisiDocs = const [];
  List<String> _verifiedDocTitles = const [];
  bool _revisionSent = false;

  // Floating Top Toast state & animation
  AnimationController? _toastAnimController;
  Animation<double>? _toastFadeAnim;
  Animation<Offset>? _toastSlideAnim;
  Timer? _toastDismissTimer;
  bool _showToast = false;
  String _toastTitle = '';
  String _toastSubtitle = '';
  bool _toastIsSuccess = true;

  @override
  void initState() {
    super.initState();
    _toastAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _toastFadeAnim = CurvedAnimation(
      parent: _toastAnimController!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _toastSlideAnim =
        Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _toastAnimController!,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _toastDismissTimer?.cancel();
    _toastAnimController?.dispose();
    super.dispose();
  }

  void _showTopToast({
    required String title,
    required String subtitle,
    bool isSuccess = true,
  }) {
    _toastDismissTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _toastTitle = title;
      _toastSubtitle = subtitle;
      _toastIsSuccess = isSuccess;
      _showToast = true;
    });

    _toastAnimController?.forward(from: 0.0);

    _toastDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      _toastAnimController?.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showToast = false;
          });
        }
      });
    });
  }

  void _dismissToast() {
    _toastDismissTimer?.cancel();
    if (!mounted) return;
    _toastAnimController?.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  /// Tidak ada penyimpanan: pilihan berkas hanya hidup selama layar ini
  /// terbuka (draf pengajuan baru memakai `PengajuanDraftStore`, kontraknya
  /// berbeda). Tombol ini hanya mencatat waktu dan menyatakannya terus terang.
  void _handleSimpanSementara() {
    try {
      final now = DateFormat('HH:mm').format(DateTime.now());
      setState(() {
        _lastSavedTime = now;
      });
      _showTopToast(
        title: 'Pilihan Berkas Dicatat Sementara',
        subtitle:
            'Belum disimpan permanen. Pilihan hilang jika halaman ditutup.',
        isSuccess: true,
      );
    } catch (e) {
      _showTopToast(
        title: 'Gagal Mencatat Pilihan',
        subtitle: 'Terjadi kesalahan saat mencatat pilihan berkas.',
        isSuccess: false,
      );
    }
  }

  /// Pengajuan aktif menurut id rute. Tanpa kecocokan: null (tidak ada
  /// pengganti diam-diam dengan pengajuan lain).
  Pengajuan? _findSubmission() {
    final list = ref.watch(pengajuanListProvider);
    final targetId = widget.id.trim();
    if (targetId.isEmpty) return null;
    for (final item in list) {
      if (item.id == targetId) return item;
    }
    return null;
  }

  void _deriveFrom(Pengajuan item) {
    _revisionSent = item.revisionSubmitted;
    final multiCount = item.technicalFiles.length;
    var index = 0;
    _revisiDocs = [
      for (final key in item.dokumenPerluRevisi)
        () {
          index++;
          final update = _updates[key];
          final rule = FilePickerUtil.revisionRule(key);
          final multi = key == 'site_plan_dwg' && multiCount > 1;
          return _DocRevisiData(
            key: key,
            number: '$index',
            title: pengajuanRevisionDocTitle(key),
            isUpdated: item.revisionSubmitted || update != null,
            fileName: update?.fileName ?? item.uploadedDocs[key] ?? '',
            fileSize: update?.fileSize,
            uploadTime: update?.uploadTime,
            formatHint: 'Format ${rule.formatLabel}, maks. ${rule.maxMb} MB',
            isMultipleFiles: multi,
            fileCount: multi ? multiCount : 1,
          );
        }(),
    ];
    // Berkas yang sudah terverifikasi (data verifikasi pengajuan), di luar
    // dokumen yang diminta revisi.
    _verifiedDocTitles = [
      for (final entry in item.verifiedDocs.entries)
        if (entry.value && !item.dokumenPerluRevisi.contains(entry.key))
          pengajuanDocTitle(entry.key),
    ];
  }

  int get _completedCount => _revisiDocs.where((d) => d.isUpdated).length;

  int get _totalCount => _revisiDocs.length;

  int get _remainingCount => _totalCount - _completedCount;

  double get _progress =>
      _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    final submission = _findSubmission();
    if (submission == null) return _buildNotFound(context);
    _deriveFrom(submission);
    final namaPerumahan = submission.namaPerumahan;
    final regId = submission.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── 1. HEADER MERAH BRAND SATU RUMAH ────────────────────────────
            _buildHeader(context, regId),

            // ─── KONTEN SCROLLABLE DENGAN FLOATING TOAST ─────────────────────
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── HOUSING IDENTITY CARD ────────────────────────────
                        _buildHousingIdentityCard(namaPerumahan, regId),

                        // ─── 2. PROGRESS PERBAIKAN BERKAS ────────────────────
                        _buildProgressCard(),

                        // ─── 3. CATATAN DARI ADMIN VERIFIKATOR ───────────────
                        _buildCatatanVerifikatorBox(context, submission),

                        // ─── 4. SECTION PERLU DIPERBAIKI ─────────────────────
                        _buildSectionPerluDiperbaikiHeader(),

                        if (_revisiDocs.isEmpty)
                          _buildEmptyRevisi()
                        else
                          for (final doc in _revisiDocs)
                            _buildDocCardItem(context, doc),

                        // ─── 5. SECTION TERVERIFIKASI DAN TERKUNCI ───────────
                        if (_verifiedDocTitles.isNotEmpty)
                          _buildSectionTerverifikasiTerkunci(),

                        const SizedBox(
                          height: 100,
                        ), // Spacing for sticky bottom bar
                      ],
                    ),
                  ),

                  // ─── FLOATING TOP TOAST FEEDBACK ─────────────────────────
                  if (_showToast)
                    Positioned(
                      top: 10,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      child: _buildFloatingToast(),
                    ),
                ],
              ),
            ),

            // ─── 6. STICKY BOTTOM ACTION BAR ─────────────────────────────────
            _buildBottomActionBar(context, submission),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Column(
        children: [
          _buildHeader(context, widget.id),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Pengajuan tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRevisi() {
    return Container(
      width: double.infinity,
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
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const AppIllustration(AppIllustration.semuaBeres, width: 180),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tidak ada berkas yang ditandai perlu perbaikan pada pengajuan ini.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String regId) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        MediaQuery.paddingOf(context).top + 8,
        AppSpacing.lg,
        AppSpacing.xl,
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
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HOUSING IDENTITY CARD ──────────────────────────────────────────────────
  Widget _buildHousingIdentityCard(String namaPerumahan, String regId) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFECACA).withValues(alpha: 0.6),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.home_work_outlined,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  namaPerumahan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                if (regId.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    regId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
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

  // ─── FLOATING TOP TOAST WIDGET ─────────────────────────────────────────────
  Widget _buildFloatingToast() {
    if (_toastFadeAnim == null || _toastSlideAnim == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _toastFadeAnim!,
      child: SlideTransition(
        position: _toastSlideAnim!,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _toastIsSuccess
                    ? const Color(0xFFE2E8F0)
                    : AppColors.primaryRed.withValues(alpha: 0.3),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _toastIsSuccess
                        ? const Color(0xFFDCFCE7)
                        : AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _toastIsSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 20,
                      color: _toastIsSuccess
                          ? const Color(0xFF16A34A)
                          : AppColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _toastTitle,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _toastSubtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _dismissToast,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 2. PROGRESS CARD ──────────────────────────────────────────────────────
  Widget _buildProgressCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 7,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. CATATAN DARI ADMIN VERIFIKATOR ─────────────────────────────────────
  Widget _buildCatatanVerifikatorBox(BuildContext context, Pengajuan item) {
    final rawNote = item.catatanPerbaikan?.trim() ?? '';
    final hasNote = rawNote.isNotEmpty;
    final noteText = hasNote
        ? rawNote
        : 'Belum ada catatan revisi dari verifikator.';

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
                      _kVerifikatorBelumTersedia,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasNote)
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
                      _kVerifikatorBelumTersedia,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasNote)
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup Catatan Verifikator',
      barrierColor: const Color(0x990F172A), // Slate 950 / 60% opacity backdrop
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curvedAnimation),
            child: _buildCatatanVerifikatorDialog(dialogContext, note),
          ),
        );
      },
    );
  }

  Widget _buildCatatanVerifikatorDialog(
    BuildContext dialogContext,
    String note,
  ) {
    // Model pengajuan belum menyimpan nama verifikator maupun waktu catatan.
    const verifikatorName = 'Belum tersedia';
    const dateStr = 'Waktu belum tercatat';
    const instansiName = 'Disperwaskim Kota Tasikmalaya';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.88,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330F172A),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.description_outlined,
                                color: Color(0xFFB91C1C),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catatan Verifikator',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.slate900,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Informasi perbaikan dokumen',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.slate500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scrollable Note Content & Metadata
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  note,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 13,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildMetaRow(
                                      label: 'Verifikator',
                                      value: verifikatorName,
                                      showDivider: true,
                                    ),
                                    _buildMetaRow(
                                      label: 'Tanggal',
                                      value: dateStr,
                                      showDivider: true,
                                    ),
                                    _buildMetaRow(
                                      label: 'Instansi',
                                      value: instansiName,
                                      showDivider: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _handlePerbaikiDokumenSekarang(dialogContext),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Perbaiki Dokumen Sekarang',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.slate500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Tutup',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top Right Close Button
                Positioned(
                  top: 14,
                  right: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required String label,
    required String value,
    required bool showDivider,
  }) {
    return Builder(
      builder: (context) {
        final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final content = isLargeText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate500,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate500,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: content,
            ),
            if (showDivider)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ],
        );
      },
    );
  }

  void _handlePerbaikiDokumenSekarang(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_perluDiperbaikiKey.currentContext != null) {
        Scrollable.ensureVisible(
          _perluDiperbaikiKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          180.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // ─── 4. SECTION PERLU DIPERBAIKI (3) HEADER ────────────────────────────────
  Widget _buildSectionPerluDiperbaikiHeader() {
    return Container(
      key: _perluDiperbaikiKey,
      child: Builder(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
      ),
    );
  }

  String get _catatanUntukDokumen =>
      _findSubmissionNoWatch()?.catatanPerbaikan?.trim() ?? '';

  Pengajuan? _findSubmissionNoWatch() {
    final targetId = widget.id.trim();
    for (final item in ref.read(pengajuanListProvider)) {
      if (item.id == targetId) return item;
    }
    return null;
  }

  String _updateMeta(_DocRevisiData doc) {
    final parts = [
      if (doc.fileSize != null && doc.fileSize!.isNotEmpty) doc.fileSize!,
      if (doc.uploadTime != null && doc.uploadTime!.isNotEmpty) doc.uploadTime!,
    ];
    return parts.isEmpty ? 'Revisi sudah dikirim' : parts.join(' • ');
  }

  // ─── DOCUMENT CARD ITEM ───────────────────────────────────────────────────
  Widget _buildDocCardItem(BuildContext context, _DocRevisiData doc) {
    final isSudahDiperbarui = doc.isUpdated;
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
                    doc.formatHint.split(',').first.replaceFirst('Format ', ''),
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
                                      _updateMeta(doc),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                    )
                                  else
                                    Text(
                                      doc.formatHint,
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
                                _updateMeta(doc),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              )
                            else
                              Text(
                                doc.formatHint,
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
          if (doc.isMultipleFiles && !isSudahDiperbarui) ...[
            Text(
              doc.formatHint,
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
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Revisi yang sudah terkirim tidak bisa diubah selama diverifikasi.
                    onPressed: _revisionSent
                        ? null
                        : () => _handlePickAndReplaceFile(context, doc),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        doc.isMultipleFiles
                            ? 'Ubah Berkas (${doc.fileCount} File)'
                            : 'Ubah Berkas',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Revisi yang sudah terkirim tidak bisa diubah selama diverifikasi.
                    onPressed: _revisionSent
                        ? null
                        : () => _handlePickAndReplaceFile(context, doc),
                    child: FittedBox(
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
            'Terverifikasi dan Terkunci (${_verifiedDocTitles.length})',
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
                                '${_verifiedDocTitles.length} Berkas Sudah Terverifikasi',
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
                          itemCount: _verifiedDocTitles.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final docName = _verifiedDocTitles[index];
                            final isLargeScale =
                                MediaQuery.textScalerOf(context).scale(1) >
                                1.15;

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
                                                  color: const Color(
                                                    0xFF475569,
                                                  ),
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
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
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
  Widget _buildBottomActionBar(BuildContext context, Pengajuan submission) {
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
          // Sub-row: Simpan Sementara & waktu simpan terakhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: InkWell(
                  onTap: _handleSimpanSementara,
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
                  _lastSavedTime == null
                      ? 'Belum disimpan permanen'
                      : 'Dicatat $_lastSavedTime · sementara',
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
              onPressed: (_revisiDocs.isEmpty || _revisionSent)
                  ? null
                  : () => _handleTinjauPerbaikan(submission),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Tinjau Perbaikan',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Caption di bawah tombol
          Text(
            _revisionSent
                ? 'Revisi sudah terkirim dan menunggu pemeriksaan verifikator'
                : _revisiDocs.isEmpty
                ? 'Tidak ada berkas yang perlu dikirim'
                : _remainingCount > 0
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
            pickerSeam: widget.pickerSeam,
            docKey: doc.key,
            docData: {
              'title': doc.title,
              'catatan': _catatanUntukDokumen,
              'fileName': doc.fileName,
              'fileSize': doc.fileSize ?? 'Ukuran tidak tersedia',
              'status': doc.isUpdated ? 'Sudah Diperbarui' : 'Perlu Perbaikan',
              'isMultipleFiles': doc.isMultipleFiles,
            },
          ),
        ),
      );

      if (result != null) {
        final now = DateFormat('HH:mm').format(DateTime.now());
        setState(() {
          _updates[doc.key] = _DocUpdate(
            fileName: (result['fileName'] as String?) ?? doc.fileName,
            fileSize: result['fileSize'] as String?,
            uploadTime: 'Diunggah $now WIB',
          );
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
                      'Ukuran: ${doc.fileSize ?? 'tidak tersedia'} • Status: ${doc.isUpdated ? 'Sudah Diperbarui' : 'Perlu Perbaikan'}',
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
                        'Pratinjau Dokumen Simulasi',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Isi berkas tidak dibuka pada pratinjau ini',
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
  Future<void> _handleTinjauPerbaikan(Pengajuan? submission) async {
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

    final updatedCount = _completedCount;
    PengajuanOperationResult? result;

    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showKonfirmasiKirimPerbaikanDialog(
      context: context,
      jumlahBerkas: updatedCount,
      onConfirm: () async {
        _isSubmittingRevisi = true;
        final mapDocs = {
          for (final d in _revisiDocs)
            if (_updates[d.key] != null) d.key: _updates[d.key]!.fileName,
        };
        result = await ref
            .read(pengajuanVerifikasiControllerProvider.notifier)
            .kirimRevisiAsync(submission!.id, mapDocs);
      },
    );
    _isSubmittingRevisi = false;

    if (confirmed == true && mounted && result?.success != true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result?.message ?? 'Revisi belum dapat dikirim.'),
        ),
      );
      return;
    }

    if (confirmed == true && mounted) {
      final id = submission!.id;
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Revisi berkas berhasil dikirim ke Verifikator!'),
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
          builder: (_) => StatusPerbaikanBerkasScreen(pengajuanId: id),
        ),
      );
    }
  }
}
