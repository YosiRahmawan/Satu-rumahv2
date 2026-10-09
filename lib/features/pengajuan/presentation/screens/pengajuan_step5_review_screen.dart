import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../../../notifikasi/data/models/notifikasi_model.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_form_controller.dart';

class PengajuanStep5ReviewScreen extends ConsumerStatefulWidget {
  const PengajuanStep5ReviewScreen({super.key});
  @override
  ConsumerState<PengajuanStep5ReviewScreen> createState() =>
      _PengajuanStep5ReviewScreenState();
}

class _PengajuanStep5ReviewScreenState
    extends ConsumerState<PengajuanStep5ReviewScreen> {
  bool _isSubmitting = false;

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
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tinjau Kembali Data Pengajuan',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pastikan data dan berkas sudah sesuai sebelum dikirim.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!state.isAllValid) ...[
                    const SizedBox(height: AppSpacing.md),
                    _warning(state),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _section(
                    'Ringkasan Pengajuan',
                    'Informasi utama permohonan site plan.',
                    '/pengajuan/step1',
                    Column(
                      children: [
                        _info('Tipe Pengajuan', state.tipePengajuan),
                        _info('Nama Perumahan', state.namaPerumahan),
                        _info('Alamat Proyek', state.alamatProyek),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    'Data PT & Perumahan',
                    'Data identitas dan rencana perumahan.',
                    '/pengajuan/step1',
                    Column(
                      children: [
                        _info('Nama PT', 'Belum tersedia'),
                        _info('Nama Direktur', 'Belum tersedia'),
                        _info('NPWP Perusahaan', state.npwpPerusahaan),
                        _info('Luas Lahan', '${_number(state.luasLahan)} m²'),
                        _info('Jumlah Unit', '${state.jumlahUnit} Unit'),
                        _info('Tipe Perumahan', state.tipePerumahan),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    'Berkas PT',
                    '${_companyCount(state)} dari ${PengajuanStep2DocumentContract.slots.length} berkas tersedia.',
                    '/pengajuan/step2',
                    Column(
                      children: PengajuanStep2DocumentContract.slots
                          .map(
                            (d) =>
                                _document(d.label, state.uploadedDocs[d.key]),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    'Berkas Perumahan',
                    '${_housingCount(state)} dari ${PengajuanStep3DocumentContract.slots.where((s) => !s.isOptional).length} berkas wajib tersedia.',
                    '/pengajuan/step3',
                    Column(
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
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _section(
                    'Dokumen Teknis',
                    '${_technicalCount(state)} berkas teknis tersedia.',
                    '/pengajuan/step4',
                    _technical(state),
                  ),
                  const SizedBox(height: AppSpacing.md),
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

  Widget _warning(PengajuanFormState state) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: .12),
      borderRadius: AppRadii.small,
      border: Border.all(color: AppColors.warning.withValues(alpha: .35)),
    ),
    child: Text(_missing(state), style: AppTextStyles.bodySmall),
  );

  Widget _section(String title, String subtitle, String route, Widget child) =>
      Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(route),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Ubah'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              child,
            ],
          ),
        ),
      );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value.trim().isEmpty ? 'Belum tersedia' : value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _document(String label, String? file, {bool optional = false}) {
    final exists = file?.trim().isNotEmpty == true;
    final color = exists
        ? AppColors.statusSuccessText
        : optional
        ? AppColors.textSecondary
        : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      exists
                          ? Icons.check_circle
                          : optional
                          ? Icons.insert_drive_file_outlined
                          : Icons.warning_amber_rounded,
                      size: 17,
                      color: color,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      exists
                          ? 'Tersedia'
                          : optional
                          ? 'Opsional · Belum Ada'
                          : 'Belum Ada',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (exists)
                  Text(
                    _fileName(file!),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
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

  Widget _declaration(PengajuanFormState state) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
    child: CheckboxListTile(
      value: state.isAgreed,
      onChanged: (value) => ref
          .read(pengajuanFormProvider.notifier)
          .toggleAgreement(value ?? false),
      activeColor: AppColors.primaryRed,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text(
        'Saya menyatakan bahwa seluruh data dan dokumen yang saya lampirkan adalah benar, sah, dan dapat dipertanggungjawabkan secara hukum.',
        style: AppTextStyles.bodySmall,
      ),
    ),
  );

  Widget _bottomBar(PengajuanFormState state, bool compact) {
    final submit = AppButton.primary(
      text: 'Kirim Pengajuan',
      isLoading: _isSubmitting,
      onPressed: state.isAllValid && !_isSubmitting ? _submit : null,
    );
    final draft = AppButton.secondary(
      text: 'Simpan sebagai Draft',
      onPressed: _saveDraft,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: compact
            ? Column(
                children: [
                  submit,
                  const SizedBox(height: AppSpacing.sm),
                  draft,
                ],
              )
            : Row(
                children: [
                  Expanded(child: draft),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: submit),
                ],
              ),
      ),
    );
  }

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
            id: 'notif-\$id',
            jenis: JenisNotifikasi.pengajuanBaru,
            judul: 'Pengajuan Baru: ${state.namaPerumahan}',
            deskripsi:
                'Pengajuan (\$id) telah diterima dan dalam verifikasi administrasi.',
            waktu: DateTime.now(),
            targetRoute: '/admin/pengajuan/detail/\$id',
          ),
        );
    ref.read(pengajuanFormProvider.notifier).reset();
    context.pushReplacement('/pengajuan/success', extra: id);
  }

  int _companyCount(PengajuanFormState state) =>
      PengajuanStep2DocumentContract.slots.where((d) => _has(state, d.key)).length;
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
