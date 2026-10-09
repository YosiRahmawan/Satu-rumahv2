import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/doc_upload_tile.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../monitoring/data/models/monitoring_model.dart';
import '../../../monitoring/presentation/providers/monitoring_form_provider.dart';
import '../../../monitoring/utils/ba_pdf_generator.dart';
import '../../data/models/hasil_survey_model.dart';
import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_verifikasi_controller.dart';

/// Returns a real linked final monitoring record with an available BA path.
/// A developer detail must never synthesize a report for export.
MonitoringModel? findLinkedFinalMonitoring(
  Iterable<MonitoringModel> reports,
  String pengajuanId, {
  String? beritaAcaraPath,
}) {
  final normalizedId = pengajuanId.trim();
  if (normalizedId.isEmpty || beritaAcaraPath?.trim().isNotEmpty != true) {
    return null;
  }

  for (final report in reports) {
    if (!report.isDraft && report.pengajuanId?.trim() == normalizedId) {
      return report;
    }
  }
  return null;
}

class PengajuanDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const PengajuanDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PengajuanDetailScreen> createState() =>
      _PengajuanDetailScreenState();
}

class _PengajuanDetailScreenState extends ConsumerState<PengajuanDetailScreen> {
  Map<String, String> localDocs = {};
  Set<String> clearedDocs = {};
  bool _isSubmittingRevision = false;
  int _selectedCategoryIndex = 2; // Default to 'Teknis (4)' matching prototype

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(pengajuanListProvider);
    Pengajuan? match;
    for (final candidate in list) {
      if (candidate.id == widget.id) {
        match = candidate;
        break;
      }
    }
    if (match == null) return _buildNotFound(context);
    final item = match;
    final isPerluPerbaikan =
        item.status == 'Perlu Perbaikan' ||
        item.statusTahap == StatusTahapPengajuan.perluPerbaikan;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      bottomNavigationBar: isPerluPerbaikan
          ? _buildBottomBar(context, item)
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Pengajuan
            _buildHeader(context, item),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Informasi Pengajuan
                  _buildInfoCard(item),
                  const SizedBox(height: AppSpacing.md),

                  if (isPerluPerbaikan) ...[
                    // 3. Persentase Verifikasi Berkas
                    _buildPersentaseCard(item),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Section Perlu Perbaikan
                    _buildSectionPerluPerbaikan(context, item),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Linimasa Status (6 Tahapan)
                    _buildLinimasaStatusCard(item),
                    const SizedBox(height: AppSpacing.md),

                    // 6. Riwayat Catatan Perbaikan
                    _buildRiwayatCatatanCard(item),
                    const SizedBox(height: AppSpacing.md),

                    // 7. Berkas Terkirim
                    _buildBerkasTerkirimCard(context, item),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    // Detail Informasi Survey Lapangan & Berita Acara (jika ada survey)
                    if (item.tanggalSurvey != null ||
                        item.riwayatSurvey.isNotEmpty ||
                        item.statusTahap ==
                            StatusTahapPengajuan.surveyLapangan ||
                        item.statusTahap == StatusTahapPengajuan.persetujuan ||
                        item.statusTahap == StatusTahapPengajuan.selesai) ...[
                      _buildHasilSurveyCard(context, item),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Dynamic Timeline Progress
                    const Text(
                      'Timeline Pengajuan',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDynamicTimelineCard(item),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. HEADER DETAIL PENGAJUAN ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Pengajuan item) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Row(
            children: [
              // Back Button
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  tooltip: 'Kembali',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Center Title & Subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Detail Pengajuan',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'DISPERWASKIM KOTA TASIKMALAYA',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right placeholder to balance back button
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 2. INFORMASI PENGAJUAN ──────────────────────────────────────────────
  Widget _buildInfoCard(Pengajuan item) {
    String formattedLuas;
    try {
      formattedLuas = NumberFormat('#,###', 'id_ID').format(item.luasLahan);
    } catch (_) {
      formattedLuas = '${item.luasLahan.toInt()}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Reg Pill & Status Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurfaceSoft,
                    borderRadius: BorderRadius.circular(
                      AppRadii.small.topLeft.x,
                    ),
                    border: Border.all(color: AppColors.primarySurfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.id,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  status: item.status,
                  showIcon: true,
                  showBorder: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Housing Name
            Text(
              item.namaPerumahan,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            // Submission Type Subtitle
            Text(
              item.tipePengajuan?.replaceAll(' (Tahap 2)', '') ??
                  'Pengajuan Site Plan Baru',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: AppSpacing.md),
            // 2-Column Info Grid
            _buildInfoRow(
              'NAMA PT',
              item.namaPt.trim().isEmpty ? 'Belum tersedia' : item.namaPt,
              'NAMA DIREKTUR',
              item.namaDirektur.trim().isEmpty
                  ? 'Belum tersedia'
                  : item.namaDirektur,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              'NIB',
              item.nib?.trim().isNotEmpty == true
                  ? item.nib!
                  : 'Belum tersedia',
              'NPWP PERUSAHAAN',
              item.npwpPerusahaan,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              'LUAS LAHAN',
              '$formattedLuas m²',
              'JUMLAH UNIT',
              '${item.jumlahUnit} Unit',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              'TIPE PERUMAHAN',
              item.tipePerumahan,
              'TANGGAL DIKIRIM',
              item.tanggal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoItem(label1, value1)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildInfoItem(label2, value2)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  // ─── 3. PERSENTASE VERIFIKASI BERKAS ─────────────────────────────────────
  Widget _buildPersentaseCard(Pengajuan item) {
    final totalCount = item.uploadedDocs.isNotEmpty
        ? item.uploadedDocs.length
        : 20;
    final verifiedCount = item.verifiedDocs.values
        .where((v) => v == true)
        .length;
    // Calculate percentage dynamically from verified documents ratio
    final percentage = totalCount > 0
        ? ((verifiedCount / totalCount) * 100).round()
        : 65;
    final progress = (percentage / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Persentase Verifikasi Berkas',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$percentage%',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.primarySurfaceSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryRed,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$verifiedCount dari $totalCount berkas terverifikasi resmi oleh verifikator Disperwaskim',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. SECTION PERLU PERBAIKAN ──────────────────────────────────────────
  Widget _buildSectionPerluPerbaikan(BuildContext context, Pengajuan item) {
    final count = item.dokumenPerluRevisi.isNotEmpty
        ? item.dokumenPerluRevisi.length
        : 2;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Perlu Perbaikan ($count Berkas)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(
                      AppRadii.small.topLeft.x,
                    ),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Revisi Diperlukan',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Catatan Tim Verifikator Disperwaskim Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'CATATAN TIM VERIFIKATOR DISPERWASKIM:',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '"${item.catatanPerbaikan ?? 'Format site plan teknis belum mencantumkan koordinat UTM dan luasan RTH minimum 30%. Bukti kepemilikan tanah belum dilegalisir basah.'}"',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'DAFTAR BERKAS YANG HARUS DIREVISI:',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
              InkWell(
                onTap: () =>
                    context.push('/pengajuan/perbarui-berkas/${item.id}'),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Perbarui Berkas',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Item 1: Gambar Rencana Site Plan (DWG/PDF)
          _buildRevisionItemCard(
            context: context,
            item: item,
            docKey: 'site_plan_dwg',
            icon: Icons.architecture,
            title: 'Gambar Rencana Site Plan (DWG/PDF)',
            status: 'Belum Diperbaiki',
            catatan:
                'Catatan: Tambahkan koordinat UTM & persentase luasan RTH minimum 30%.',
          ),
          const SizedBox(height: AppSpacing.sm),
          // Item 2: Sertifikat Tanah / Hak Milik (SHM/HGB)
          _buildRevisionItemCard(
            context: context,
            item: item,
            docKey: 'bukti_kepemilikan_lahan',
            icon: Icons.verified_user_outlined,
            title: 'Sertifikat Tanah / Hak Milik (SHM/HGB)',
            status: 'Belum Diperbaiki',
            catatan:
                'Catatan: Bukti legalisir basah notaris/kantah belum terlihat jelas pada scan berkas.',
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionItemCard({
    required BuildContext context,
    required Pengajuan item,
    required String docKey,
    required IconData icon,
    required String title,
    required String status,
    required String catatan,
  }) {
    final hasNewUpload = localDocs[docKey]?.trim().isNotEmpty == true;
    final displayStatus = hasNewUpload ? 'File Dipilih' : status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasNewUpload
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(
                      AppRadii.small.topLeft.x,
                    ),
                    border: Border.all(
                      color: hasNewUpload
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayStatus,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: hasNewUpload
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              catatan,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. LINIMASA STATUS (6 TAHAPAN) ──────────────────────────────────────
  Widget _buildLinimasaStatusCard(Pengajuan item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Linimasa Status',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(
                        AppRadii.small.topLeft.x,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '6 Tahapan',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // 6 Steps
            _buildStepRow(
              title: 'Pengajuan Dibuat (Draft)',
              timestamp: '10 Sep 2026, 09:30 WIB',
              statusBadge: 'Selesai',
              badgeColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF16A34A),
              isCompleted: true,
              isActive: false,
              isLast: false,
            ),
            _buildStepRow(
              title: 'Pengajuan Dikirim',
              timestamp: '12 Sep 2026, 14:15 WIB',
              statusBadge: 'Selesai',
              badgeColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF16A34A),
              isCompleted: true,
              isActive: false,
              isLast: false,
            ),
            _buildStepRow(
              title: 'Verifikasi Berkas oleh Admin',
              timestamp: '14 Sep 2026, 11:00 WIB',
              statusBadge: 'Selesai',
              badgeColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF16A34A),
              isCompleted: true,
              isActive: false,
              isLast: false,
            ),
            _buildStepRow(
              title: 'Perlu Perbaikan',
              timestamp: '15 Sep 2026, 16:20 WIB',
              statusBadge: 'Aktif',
              badgeColor: const Color(0xFFFEF3C7),
              badgeTextColor: const Color(0xFFB45309),
              isCompleted: false,
              isActive: true,
              isLast: false,
              calloutNote:
                  'Terdapat 2 berkas teknis yang masa berlaku habis dan format peta kontur belum sesuai koordinat UTM.',
            ),
            _buildStepRow(
              title: 'Survey Lapangan Dijadwalkan',
              timestamp: 'Menunggu perbaikan diserahkan',
              isCompleted: false,
              isActive: false,
              isLast: false,
            ),
            _buildStepRow(
              title: 'Hasil Verifikasi: SK Disetujui / Ditolak',
              timestamp: 'Menunggu seluruh tahapan selesai',
              isCompleted: false,
              isActive: false,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required String timestamp,
    String? statusBadge,
    Color? badgeColor,
    Color? badgeTextColor,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    String? calloutNote,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + Line Column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primaryRed
                        : isActive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE2E8F0),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : isActive
                        ? const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.primaryRed
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: isActive || isCompleted
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive || isCompleted
                                ? AppColors.textMain
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (statusBadge != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(
                                AppRadii.small.topLeft.x,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                statusBadge,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timestamp,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (calloutNote != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(
                          AppRadii.small.topLeft.x,
                        ),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Verifikator:',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"$calloutNote"',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. RIWAYAT CATATAN PERBAIKAN ────────────────────────────────────────
  Widget _buildRiwayatCatatanCard(Pengajuan item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.speaker_notes_outlined,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Riwayat Catatan Perbaikan',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFEE2E2),
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Perbaikan ke-1',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '15 Sep 2026',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Admin Verifikator: Ir. Deden Permana (Disperwaskim)',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"Mohon perbarui Keterangan Rencana Kota (KRK) terbaru dan peta kontur site plan elevasi format DWG/PDF berkoordinat."',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Document 1
            _buildRiwayatDocRow(
              icon: Icons.event_note_outlined,
              name: 'Surat KRK',
              status: 'Belum diperbaiki',
            ),
            const SizedBox(height: AppSpacing.xs),
            // Document 2
            _buildRiwayatDocRow(
              icon: Icons.map_outlined,
              name: 'Peta Kontur & Topografi',
              status: 'Belum diperbaiki',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatDocRow({
    required IconData icon,
    required String name,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD97706)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  status,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. BERKAS TERKIRIM ──────────────────────────────────────────────────
  Widget _buildBerkasTerkirimCard(BuildContext context, Pengajuan item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Berkas Terkirim',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Total 20 Berkas',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Category Tab Pills
            Row(
              children: [
                _buildCategoryTab(0, 'Perusahaan (5)'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryTab(1, 'Perumahan (11)'),
                const SizedBox(width: AppSpacing.xs),
                _buildCategoryTab(2, 'Teknis (4)'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Tab Content
            if (_selectedCategoryIndex == 2) ...[
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'KRK Kota Tasikmalaya',
                subtitle: 'krk_greentasik_2024.pdf • 2.4 MB • 12 Sep',
                status: 'Perlu Perbaikan',
                isNeedsRevision: true,
                fileName: 'krk_greentasik_2024.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'dwg',
                name: 'Peta Kontur & Elevasi',
                subtitle: 'siteplan_topografi_v1.dwg • 8.1 MB • 12 Sep',
                status: 'Perlu Perbaikan',
                isNeedsRevision: true,
                fileName: 'siteplan_topografi_v1.dwg',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'doc',
                name: 'Rekomendasi Andalalin',
                subtitle: 'andalalin_dishub_final.pdf • 3.2 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'andalalin_dishub_final.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'doc',
                name: 'Dokumen UKL-UPL DLH',
                subtitle: 'persetujuan_lingkungan.pdf • 4.5 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'persetujuan_lingkungan.pdf',
              ),
            ] else if (_selectedCategoryIndex == 0) ...[
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Akta Pendirian Perusahaan',
                subtitle: 'akta_pendirian_pt_tasik_indah.pdf • 3.8 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'akta_pendirian_pt_tasik_indah.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Nomor Induk Berusaha (NIB)',
                subtitle: 'nib_tasik_indah_sentosa.pdf • 1.2 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'nib_tasik_indah_sentosa.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'NPWP Perusahaan',
                subtitle: 'npwp_perusahaan_tasik_indah.pdf • 850 KB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'npwp_perusahaan_tasik_indah.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'KTP Direktur / Penanggung Jawab',
                subtitle: 'ktp_direktur_rahmat.pdf • 920 KB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'ktp_direktur_rahmat.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Keanggotaan Asosiasi Pengembang',
                subtitle: 'kta_asosiasi_pengembang_rei.pdf • 1.5 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'kta_asosiasi_pengembang_rei.pdf',
              ),
            ] else ...[
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Surat Permohonan Site Plan',
                subtitle:
                    'surat_permohonan_pengesahan_siteplan.pdf • 1.1 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'surat_permohonan_pengesahan_siteplan.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Bukti Kepemilikan Lahan (SHM)',
                subtitle:
                    'sertifikat_shm_tanah_greentasik.pdf • 5.4 MB • 12 Sep',
                status: 'Perlu Perbaikan',
                isNeedsRevision: true,
                fileName: 'sertifikat_shm_tanah_greentasik.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'Penyediaan Lahan TPU',
                subtitle:
                    'perjanjian_penyediaan_lahan_tpu.pdf • 2.1 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'perjanjian_penyediaan_lahan_tpu.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'KKPR Kesesuaian Tata Ruang',
                subtitle:
                    'kesesuaian_pemanfaatan_ruang_kkpr.pdf • 2.8 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'kesesuaian_pemanfaatan_ruang_kkpr.pdf',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSentDocTile(
                context: context,
                iconType: 'pdf',
                name: 'PBG Induk Persetujuan Gedung',
                subtitle: 'pbg_induk_persetujuan_gedung.pdf • 4.2 MB • 12 Sep',
                status: 'Terverifikasi',
                isNeedsRevision: false,
                fileName: 'pbg_induk_persetujuan_gedung.pdf',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(int index, String label) {
    final isSelected = _selectedCategoryIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryIndex = index),
        borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFF1F2)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
            border: Border.all(
              color: isSelected ? AppColors.primaryRed : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primaryRed
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentDocTile({
    required BuildContext context,
    required String iconType,
    required String name,
    required String subtitle,
    required String status,
    required bool isNeedsRevision,
    required String fileName,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isNeedsRevision
                  ? const Color(0xFFFFF1F2)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadii.small.topLeft.x),
            ),
            child: Icon(
              iconType == 'pdf'
                  ? Icons.picture_as_pdf
                  : iconType == 'dwg'
                  ? Icons.map_outlined
                  : Icons.description_outlined,
              color: isNeedsRevision
                  ? AppColors.primaryRed
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isNeedsRevision
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isNeedsRevision
                            ? const Color(0xFFB45309)
                            : const Color(0xFF16A34A),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.visibility_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showFilePreview(context, name, fileName),
            tooltip: 'Lihat Dokumen',
          ),
        ],
      ),
    );
  }

  // ─── 8. BOTTOM ACTION BAR ────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, Pengajuan item) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => _showRevisionBottomSheet(context, item),
            icon: const Icon(
              Icons.file_upload_outlined,
              size: 20,
              color: Colors.white,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.revisionSubmitted
                    ? 'Periksa Revisi Terkirim'
                    : 'Perbaiki Sekarang',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BOTTOM SHEET UPLOAD REVISI ──────────────────────────────────────────
  void _showRevisionBottomSheet(BuildContext context, Pengajuan item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final Map<String, String> docLabels = {
              'site_plan_dwg': 'Gambar Rencana Site Plan (DWG/PDF)',
              'bukti_kepemilikan_lahan':
                  'Sertifikat Tanah / Hak Milik (SHM/HGB)',
              'ktp': 'KTP Direktur / Penanggung Jawab',
              'nib': 'Nomor Induk Berusaha (NIB / OSS)',
              'npwp_doc': 'NPWP Perusahaan Wajib Pajak',
            };
            final revKeys = List<String>.from(
              item.dokumenPerluRevisi.isNotEmpty
                  ? item.dokumenPerluRevisi
                  : ['site_plan_dwg', 'bukti_kepemilikan_lahan'],
            );

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
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
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          color: AppColors.primaryRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Berkas Perbaikan',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih dokumen pengganti untuk berkas yang diminta revisi oleh verifikator:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.push('/pengajuan/perbarui-berkas/${item.id}');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppColors.primaryRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Buka Halaman Lengkap Perbarui Berkas',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...revKeys.map((key) {
                      final label = docLabels[key] ?? key;
                      final currentVal = clearedDocs.contains(key)
                          ? localDocs[key]
                          : (localDocs[key] ?? item.uploadedDocs[key]);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DocUploadTile(
                          title: label,
                          subtitle:
                              'Pilih file revisi baru dari HP (PDF / DWG / Gambar)',
                          fileName: currentVal,
                          onUpload: () async {
                            final file = await FilePickerUtil.pickSingleFile(
                              allowedExtensions: key == 'site_plan_dwg'
                                  ? ['dwg', 'pdf', 'zip']
                                  : ['pdf', 'jpg', 'jpeg', 'png'],
                            );
                            if (!ctx.mounted) return;
                            if (file != null) {
                              setModalState(() {
                                localDocs[key] = file.path ?? file.name;
                                clearedDocs.remove(key);
                              });
                              setState(() {
                                localDocs[key] = file.path ?? file.name;
                                clearedDocs.remove(key);
                              });
                            }
                          },
                          onDelete: () {
                            setModalState(() {
                              localDocs.remove(key);
                              clearedDocs.add(key);
                            });
                            setState(() {
                              localDocs.remove(key);
                              clearedDocs.add(key);
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    AppButton.primary(
                      text: _isSubmittingRevision
                          ? 'Mengirim Revisi...'
                          : 'Kirim Revisi Dokumen',
                      onPressed: _isSubmittingRevision
                          ? null
                          : () {
                              final missing = revKeys
                                  .where(
                                    (key) =>
                                        localDocs[key]?.trim().isNotEmpty !=
                                        true,
                                  )
                                  .toList();
                              if (missing.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pilih berkas revisi untuk: ${missing.map((k) => docLabels[k] ?? k).join(', ')}.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => _isSubmittingRevision = true);
                              setState(() => _isSubmittingRevision = true);
                              final result = ref
                                  .read(
                                    pengajuanVerifikasiControllerProvider
                                        .notifier,
                                  )
                                  .kirimRevisi(item.id, localDocs);
                              setModalState(
                                () => _isSubmittingRevision = false,
                              );
                              setState(() => _isSubmittingRevision = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.message)),
                              );
                              Navigator.of(ctx).pop();
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── PREVIEW HELPERS ──────────────────────────────────────────────────────

  void _showFilePreview(BuildContext context, String docName, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      docName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nama Berkas: $fileName',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.preview_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pratinjau Dokumen Simulasi (SATU RUMAH Mobile)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton.primary(
                text: 'Tutup',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── FALLBACK & LEGACY SURVEY / TIMELINE COMPATIBILITY ────────────────────
  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengajuan Tidak Ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.grey500),
              const SizedBox(height: 16),
              const Text(
                'Pengajuan tidak ditemukan',
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nomor ${widget.id} tidak ada di daftar pengajuan lokal.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: const Text('Kembali'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Lihat Daftar Pengajuan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTimelineCard(Pengajuan item) {
    final status = item.statusTahap;

    final bool step1Passed =
        status != StatusTahapPengajuan.pengajuanBaru &&
        status != StatusTahapPengajuan.verifikasiAdministrasi;
    final bool step1Current =
        status == StatusTahapPengajuan.verifikasiAdministrasi ||
        status == StatusTahapPengajuan.pengajuanBaru;

    final bool step2Passed =
        status == StatusTahapPengajuan.persetujuan ||
        status == StatusTahapPengajuan.selesai;
    final bool step2Current =
        status == StatusTahapPengajuan.verifikasiTeknis ||
        status == StatusTahapPengajuan.surveyLapangan ||
        status == StatusTahapPengajuan.perluPerbaikan;

    final bool step3Passed =
        status == StatusTahapPengajuan.persetujuan ||
        status == StatusTahapPengajuan.selesai;
    final bool step3Current =
        status == StatusTahapPengajuan.surveyLapangan &&
        item.beritaAcaraPath != null;

    final bool step4Passed = status == StatusTahapPengajuan.selesai;
    final bool step4Current =
        status == StatusTahapPengajuan.persetujuan ||
        status == StatusTahapPengajuan.selesai;

    String step2Desc = 'Belum dijadwalkan';
    if (item.tanggalSurvey != null) {
      try {
        step2Desc =
            'Dijadwalkan: ${DateFormat("d MMM yyyy, HH:mm", "id").format(item.tanggalSurvey!)} WIB';
      } catch (_) {
        step2Desc =
            'Survey dijadwalkan (${item.tanggalSurvey!.day}/${item.tanggalSurvey!.month}/${item.tanggalSurvey!.year})';
      }
    } else if (status == StatusTahapPengajuan.verifikasiTeknis) {
      step2Desc = 'Penjadwalan survey oleh Tim Disperwaskim';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimelineItem(
              'Verifikasi Administrasi',
              step1Passed
                  ? 'Dokumen terverifikasi sah'
                  : 'Pemeriksaan berkas kelengkapan',
              step1Passed,
              step1Current,
            ),
            _buildTimelineItem(
              'Verifikasi Teknis & Lapangan',
              step2Desc,
              step2Passed,
              step2Current,
            ),
            _buildTimelineItem(
              'Rekomendasi Tim Teknis & BA',
              item.beritaAcaraPath != null
                  ? 'Berita Acara diterbitkan (${item.beritaAcaraPath})'
                  : 'Menunggu pelaksanaan survey',
              step3Passed,
              step3Current,
            ),
            _buildTimelineItem(
              'Persetujuan Site Plan Terbit',
              status == StatusTahapPengajuan.selesai
                  ? 'Persetujuan disahkan (SK Terbit)'
                  : 'Tahap akhir penerbitan SK',
              step4Passed,
              step4Current,
            ),
          ],
        ),
      ),
    );
  }

  MonitoringModel? _getMonitoringModelForPengajuan(Pengajuan item) {
    final repo = ref.read(monitoringRepositoryProvider);
    return findLinkedFinalMonitoring(
      repo.getAllMonitoring(),
      item.id,
      beritaAcaraPath: item.beritaAcaraPath,
    );
  }

  Widget _buildHasilSurveyCard(BuildContext context, Pengajuan item) {
    final riwayat = item.riwayatSurvey;
    final HasilSurveyItem? surveyTerbaru = riwayat.isNotEmpty
        ? riwayat[0]
        : null;
    final finalMonitoring = _getMonitoringModelForPengajuan(item);
    final hasBa = finalMonitoring != null;
    final hasSk =
        item.skPersetujuanPath != null && item.skPersetujuanPath!.isNotEmpty;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SURVEY LAPANGAN & BERITA ACARA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Hasil Evaluasi Teknis Disperwaskim',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            if (item.tanggalSurvey != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.event,
                    size: 14,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Jadwal Survey: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  Text(
                    '${item.tanggalSurvey!.day}/${item.tanggalSurvey!.month}/${item.tanggalSurvey!.year} ${item.tanggalSurvey!.hour.toString().padLeft(2, '0')}:${item.tanggalSurvey!.minute.toString().padLeft(2, '0')} WIB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (item.catatanSurvey != null &&
                  item.catatanSurvey!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan Tim: ${item.catatanSurvey}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            if (surveyTerbaru != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCanvas,
                  borderRadius: BorderRadius.circular(12),
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
                            'Pelaksana: ${surveyTerbaru.pelaksanaNama}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: surveyTerbaru.statusHasilEvaluasi == 'sesuai'
                                ? AppColors.statusSuccessSurface
                                : AppColors.statusUrgentSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            surveyTerbaru.statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  surveyTerbaru.statusHasilEvaluasi == 'sesuai'
                                  ? AppColors.statusSuccessText
                                  : AppColors.statusUrgentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasBa
                      ? AppColors.primaryRed
                      : AppColors.grey600,
                  side: BorderSide(
                    color: hasBa ? AppColors.primaryRed : AppColors.grey300,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: hasBa
                    ? () async {
                        final monitoringModel = _getMonitoringModelForPengajuan(
                          item,
                        );
                        if (monitoringModel == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Berita Acara belum tersedia untuk diekspor.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await BaPdfGenerator.printAndShare(monitoringModel);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Berita Acara tidak dapat diekspor saat ini.',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: Icon(
                  hasBa ? Icons.picture_as_pdf : Icons.picture_as_pdf_outlined,
                  size: 16,
                ),
                label: Text(
                  hasBa
                      ? 'Lihat Berita Acara Survey (PDF)'
                      : 'Berita Acara Belum Diterbitkan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            if (hasSk) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusSuccessText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Membuka SK Persetujuan Site Plan: ${item.skPersetujuanPath}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Unduh SK Persetujuan Site Plan (PDF)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String desc,
    bool isPassed,
    bool isCurrent,
  ) {
    final Color circleColor = isPassed
        ? AppColors.statusSuccess
        : isCurrent
        ? AppColors.primaryRed
        : AppColors.grey300;

    final Color lineColor = isPassed
        ? AppColors.statusSuccess
        : AppColors.grey300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primarySurface : circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: circleColor,
                  width: isCurrent ? 3 : 2,
                ),
              ),
              child: isPassed
                  ? const Center(
                      child: Icon(Icons.check, size: 11, color: Colors.white),
                    )
                  : null,
            ),
            Container(width: 2, height: 38, color: lineColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isCurrent || isPassed
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primaryRed
                        : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
