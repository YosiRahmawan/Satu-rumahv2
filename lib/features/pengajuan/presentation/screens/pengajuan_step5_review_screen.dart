import '../../../../core/auth/role_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../../../notifikasi/data/models/notifikasi_model.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_form_controller.dart';

/// Halaman Tinjau & Kirim Pengajuan (Langkah 5 dari 5).
/// Redesain UI Google Stitch dengan Smart Document Accordions.
class PengajuanStep5ReviewScreen extends ConsumerStatefulWidget {
  const PengajuanStep5ReviewScreen({super.key});

  @override
  ConsumerState<PengajuanStep5ReviewScreen> createState() =>
      _PengajuanStep5ReviewScreenState();
}

class _PengajuanStep5ReviewScreenState
    extends ConsumerState<PengajuanStep5ReviewScreen> {
  bool _isSubmitting = false;

  // State ekspansi accordion
  bool _ptExpanded = false;
  bool _housingExpanded = false;
  bool _technicalExpanded = false;
  bool _hasInitializedExpansion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedExpansion) {
      final state = ref.read(pengajuanFormProvider);
      // Kelompok lengkap collapsed secara default, kelompok bermasalah expanded secara default
      _ptExpanded = !state.isStep2Valid;
      _housingExpanded = !state.isStep3Valid;
      _technicalExpanded = !state.isStep4Valid;
      _hasInitializedExpansion = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pengajuanFormProvider);
    final compact =
        MediaQuery.sizeOf(context).width < 500 ||
        MediaQuery.textScalerOf(context).scale(14) > 19;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PengajuanStepHeader(
              title: 'Pengajuan Baru',
              subtitle: 'Langkah 5 dari 5',
              onBackPressed: _backToStep4,
            ),
            const StepperHeader(currentStep: 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Introduction
                  const Text(
                    'Tinjau Kembali Data Pengajuan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pastikan data dan berkas sudah sesuai sebelum dikirim.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // B. Ringkasan Pengajuan (Single White Card)
                  _buildSummaryCard(context, state),
                  const SizedBox(height: 14),

                  // C. Overall Document Completeness Banner
                  _buildCompletenessSummary(state),
                  const SizedBox(height: 14),

                  // D. Smart Document Accordion 1: Berkas PT
                  _buildPtAccordion(state),
                  const SizedBox(height: 12),

                  // E. Smart Document Accordion 2: Berkas Perumahan
                  _buildHousingAccordion(state),
                  const SizedBox(height: 12),

                  // F. Smart Document Accordion 3: Dokumen Teknis
                  _buildTechnicalAccordion(state),
                  const SizedBox(height: 16),

                  // G. Contextual Alert Box (hanya jika ada yang belum valid)
                  if (!state.isAllValid) ...[
                    _warning(state),
                    const SizedBox(height: 14),
                  ],

                  // H. Legal Declaration Card
                  _declaration(state),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(state, compact),
    );
  }

  // ---------------------------------------------------------------------------
  // B. Ringkasan Pengajuan Card
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(BuildContext context, PengajuanFormState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Pengajuan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Informasi utama permohonan site plan.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/pengajuan/step1'),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Ubah'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 320;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryField('Tipe Pengajuan', state.tipePengajuan),
                    const SizedBox(height: 10),
                    _summaryField('Nama Perumahan', state.namaPerumahan),
                    const SizedBox(height: 10),
                    _summaryField('Alamat Proyek', state.alamatProyek),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF8FAFC),
                    ),
                    const SizedBox(height: 12),
                    if (isWide) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _summaryField('Nama PT', 'Belum tersedia'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryField(
                              'Nama Direktur',
                              'Belum tersedia',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _summaryField(
                              'NPWP Perusahaan',
                              state.npwpPerusahaan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryField(
                              'Tipe Perumahan',
                              state.tipePerumahan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _summaryField(
                              'Luas Lahan',
                              '${_number(state.luasLahan)} m²',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryField(
                              'Jumlah Unit',
                              '${state.jumlahUnit} Unit',
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _summaryField('Nama PT', 'Belum tersedia'),
                      const SizedBox(height: 10),
                      _summaryField('Nama Direktur', 'Belum tersedia'),
                      const SizedBox(height: 10),
                      _summaryField('NPWP Perusahaan', state.npwpPerusahaan),
                      const SizedBox(height: 10),
                      _summaryField('Tipe Perumahan', state.tipePerumahan),
                      const SizedBox(height: 10),
                      _summaryField(
                        'Luas Lahan',
                        '${_number(state.luasLahan)} m²',
                      ),
                      const SizedBox(height: 10),
                      _summaryField('Jumlah Unit', '${state.jumlahUnit} Unit'),
                    ],
                    if (state.dayaListrik.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _summaryField('Daya Listrik PLN', state.dayaListrik),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.trim().isEmpty ? 'Belum tersedia' : value,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // C. Overall Document Completeness Banner
  // ---------------------------------------------------------------------------
  Widget _buildCompletenessSummary(PengajuanFormState state) {
    final ptCount = _companyCount(state);
    final ptTotal = PengajuanStep2DocumentContract.slots.length; // 5

    final housingCount = _housingCount(state);
    final housingTotal = PengajuanStep3DocumentContract.slots
        .where((s) => !s.isOptional)
        .length; // 10

    final technicalFiles = [
      ...state.technicalFiles,
      ...state.technicalOtherFiles,
    ];
    final technicalCount = technicalFiles.length;
    final technicalTarget = technicalCount > 0 ? technicalCount : 1;

    final totalAvailable = ptCount + housingCount + technicalCount;
    final totalTarget = ptTotal + housingTotal + technicalTarget;
    final isComplete =
        state.isStep2Valid && state.isStep3Valid && state.isStep4Valid;

    final bgColor = isComplete
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFFBEB);
    final borderColor = isComplete
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFDE68A);
    final iconColor = isComplete
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);
    final textColor = isComplete
        ? const Color(0xFF064E3B)
        : const Color(0xFF78350F);
    final badgeTextColor = isComplete
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kelengkapan Dokumen',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '$totalAvailable/$totalTarget Berkas Tersedia',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Accordion: Berkas PT
  // ---------------------------------------------------------------------------
  Widget _buildPtAccordion(PengajuanFormState state) {
    final count = _companyCount(state);
    final total = PengajuanStep2DocumentContract.slots.length;
    return _ReviewAccordionCard(
      title: 'Berkas PT',
      summary: '$count dari $total berkas tersedia.',
      badgeText: '$count/$total Berkas',
      isComplete: state.isStep2Valid,
      isExpanded: _ptExpanded,
      onToggle: () => setState(() => _ptExpanded = !_ptExpanded),
      onEdit: () => context.push('/pengajuan/step2'),
      child: Column(
        children: PengajuanStep2DocumentContract.slots
            .map((d) => _document(d.label, state.uploadedDocs[d.key]))
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // E. Accordion: Berkas Perumahan
  // ---------------------------------------------------------------------------
  Widget _buildHousingAccordion(PengajuanFormState state) {
    final count = _housingCount(state);
    final totalMandatory = PengajuanStep3DocumentContract.slots
        .where((s) => !s.isOptional)
        .length;
    return _ReviewAccordionCard(
      title: 'Berkas Perumahan',
      summary: '$count dari $totalMandatory berkas wajib tersedia.',
      badgeText: '$count/$totalMandatory Berkas',
      isComplete: state.isStep3Valid,
      isExpanded: _housingExpanded,
      onToggle: () => setState(() => _housingExpanded = !_housingExpanded),
      onEdit: () => context.push('/pengajuan/step3'),
      child: Column(
        children: PengajuanStep3DocumentContract.slots
            .map(
              (s) => _document(
                s.label,
                state.uploadedDocs[s.key],
                optional: s.isOptional,
              ),
            )
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F. Accordion: Dokumen Teknis
  // ---------------------------------------------------------------------------
  Widget _buildTechnicalAccordion(PengajuanFormState state) {
    final count = _technicalCount(state);
    return _ReviewAccordionCard(
      title: 'Dokumen Teknis',
      summary: '$count berkas teknis tersedia.',
      badgeText: '$count Berkas',
      isComplete: state.isStep4Valid,
      isExpanded: _technicalExpanded,
      onToggle: () => setState(() => _technicalExpanded = !_technicalExpanded),
      onEdit: () => context.push('/pengajuan/step4'),
      child: _technical(state),
    );
  }

  // ---------------------------------------------------------------------------
  // Document Row Item
  // ---------------------------------------------------------------------------
  Widget _document(String label, String? file, {bool optional = false}) {
    final exists = file?.trim().isNotEmpty == true;
    final color = exists
        ? AppColors.statusSuccessText
        : optional
        ? AppColors.textSecondary
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                if (exists) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fileName(file!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exists
                    ? Icons.check_circle_rounded
                    : optional
                    ? Icons.insert_drive_file_outlined
                    : Icons.warning_amber_rounded,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                exists
                    ? 'Tersedia'
                    : optional
                    ? 'Opsional · Belum Ada'
                    : 'Belum Ada',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _technical(PengajuanFormState state) {
    final files = [...state.technicalFiles, ...state.technicalOtherFiles];
    return files.isEmpty
        ? _document('Berkas teknis utama', null)
        : Column(
            children: files
                .map((file) => _document('Berkas teknis', file))
                .toList(),
          );
  }

  // ---------------------------------------------------------------------------
  // G. Contextual Alert Box
  // ---------------------------------------------------------------------------
  Widget _warning(PengajuanFormState state) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFDE68A)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: Color(0xFFD97706),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _missing(state),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11.5,
              color: Color(0xFF78350F),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // H. Legal Declaration Card
  // ---------------------------------------------------------------------------
  Widget _declaration(PengajuanFormState state) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Harap setujui pernyataan di bawah ini sebelum mengirim pengajuan.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            value: state.isAgreed,
            onChanged: (value) => ref
                .read(pengajuanFormProvider.notifier)
                .toggleAgreement(value ?? false),
            activeColor: AppColors.primaryRed,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text:
                        'Saya menyatakan bahwa seluruh data dan dokumen yang saya lampirkan adalah ',
                  ),
                  TextSpan(
                    text: 'benar, sah, dan dapat dipertanggungjawabkan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextSpan(text: ' secara hukum.'),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Fixed Bottom Bar
  // ---------------------------------------------------------------------------
  Widget _bottomBar(PengajuanFormState state, bool compact) {
    final submit = ElevatedButton(
      onPressed: state.isAllValid && !_isSubmitting ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF94A3B8),
        elevation: 0,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Kirim Pengajuan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    final draft = OutlinedButton(
      onPressed: _saveDraft,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryRed,
        side: const BorderSide(color: AppColors.primaryRed),
        elevation: 0,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: const Text(
        'Simpan sebagai Draft',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [draft, const SizedBox(height: 8), submit],
              )
            : Row(
                children: [
                  Expanded(child: draft),
                  const SizedBox(width: 12),
                  Expanded(child: submit),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  void _saveDraft() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Draft formulir disimpan untuk sesi ini. Perubahan aman selama aplikasi aktif.',
      ),
    ),
  );

  void _backToStep4() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pengajuan/step4');
    }
  }

  void _submit() {
    if (_isSubmitting) return;
    final state = ref.read(pengajuanFormProvider);
    if (!state.isAllValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_missing(state))));
      return;
    }
    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final id = _newId(now, ref.read(pengajuanListProvider));
    final technicalFiles = <String>{
      ...state.technicalFiles,
      ...state.technicalOtherFiles,
    }.toList();
    final item = Pengajuan(
      id: id,
      tipePengajuan: state.tipePengajuan,
      namaPerumahan: state.namaPerumahan.trim(),
      alamatProyek: state.alamatProyek.trim(),
      namaPt: '',
      namaDirektur: '',
      npwpPerusahaan: state.npwpPerusahaan.trim(),
      luasLahan: state.luasLahan,
      jumlahUnit: state.jumlahUnit,
      tipePerumahan: state.tipePerumahan,
      status: 'Dalam Proses',
      tanggal: '${now.day} ${_month(now.month)} ${now.year}',
      uploadedDocs: Map<String, String>.from(state.uploadedDocs),
      technicalFiles: technicalFiles,
      selectedCakupanGambar: state.selectedCakupanGambar.toList(),
    );
    if (!ref.read(pengajuanListProvider.notifier).addPengajuanIfAbsent(item)) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan sudah tercatat. Silakan buka daftar pengajuan.',
          ),
        ),
      );
      return;
    }
    ref
        .read(notifikasiProvider.notifier)
        .addNotification(
          NotifikasiModel(
            id: 'notif-$id',
            jenis: JenisNotifikasi.pengajuanBaru,
            judul: 'Pengajuan Baru: ${state.namaPerumahan}',
            deskripsi:
                'Pengajuan ($id) telah diterima dan dalam verifikasi administrasi.',
            waktu: DateTime.now(),
            targetRoute: '/pengajuan/detail/$id',
            pengajuanId: id,
            penerima: AppRole.developer,
          ),
        );
    ref.read(pengajuanFormProvider.notifier).reset();
    context.pushReplacement('/pengajuan/success', extra: id);
  }

  int _companyCount(PengajuanFormState state) => PengajuanStep2DocumentContract
      .slots
      .where((d) => _has(state, d.key))
      .length;

  int _housingCount(PengajuanFormState state) => PengajuanStep3DocumentContract
      .slots
      .where((s) => !s.isOptional && _has(state, s.key))
      .length;

  int _technicalCount(PengajuanFormState state) =>
      state.technicalFiles.length + state.technicalOtherFiles.length;

  bool _has(PengajuanFormState state, String key) =>
      state.uploadedDocs[key]?.trim().isNotEmpty == true;

  String _fileName(String file) => file.split(RegExp(r'[/\\\\]')).last;

  String _number(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  String _missing(PengajuanFormState state) {
    final missing = <String>[];
    if (!state.isStep1Valid) missing.add('data dasar Step 1');
    if (!state.isStep2Valid) missing.add('5 dokumen Step 2');
    if (!state.isStep3Valid) missing.add('dokumen wajib Step 3');
    if (!state.isStep4Valid) missing.add('minimal 1 berkas teknis Step 4');
    if (!state.isAgreed) missing.add('persetujuan pernyataan');
    return "Lengkapi ${missing.join(', ')} sebelum mengirim pengajuan.";
  }

  String _newId(DateTime now, List<Pengajuan> existing) {
    final date =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    var sequence = now.millisecondsSinceEpoch % 900;
    for (var attempt = 0; attempt < 900; attempt++) {
      final id = 'SR-$date-${sequence + 100}';
      if (!existing.any((item) => item.id == id)) return id;
      sequence = (sequence + 1) % 900;
    }
    return 'SR-$date-${now.microsecondsSinceEpoch}';
  }

  String _month(int month) => const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ][month - 1];
}

// -----------------------------------------------------------------------------
// Smart Accordion Card Widget
// -----------------------------------------------------------------------------
class _ReviewAccordionCard extends StatelessWidget {
  final String title;
  final String summary;
  final String badgeText;
  final bool isComplete;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Widget child;

  const _ReviewAccordionCard({
    required this.title,
    required this.summary,
    required this.badgeText,
    required this.isComplete,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    final badgeBg = isComplete
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFFBEB);
    final badgeBorder = isComplete
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFDE68A);
    final badgeColor = isComplete
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: badgeBorder),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ubah Button
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Ubah'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Chevron Button
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: duration,
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated Collapsible Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: child,
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: duration,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
