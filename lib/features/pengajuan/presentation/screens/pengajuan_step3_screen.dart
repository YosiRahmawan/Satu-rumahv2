// The few string concatenations below keep this screen easy to generate and
// readable around platform-specific file references.
// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_const_constructors, unused_element_parameter

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../providers/pengajuan_form_controller.dart';

typedef Step3FilePickerSeam =
    Future<List<PlatformFile>> Function({
      required bool allowMultiple,
      List<String>? allowedExtensions,
    });

class PengajuanStep3Screen extends ConsumerStatefulWidget {
  const PengajuanStep3Screen({super.key, this.pickerSeam});

  final Step3FilePickerSeam? pickerSeam;

  @override
  ConsumerState<PengajuanStep3Screen> createState() =>
      _PengajuanStep3ScreenState();
}

class _SlotFailure {
  const _SlotFailure(this.fileName, this.message);
  final String fileName;
  final String message;
}

class _PengajuanStep3ScreenState extends ConsumerState<PengajuanStep3Screen> {
  static const _slots = PengajuanStep3DocumentContract.slots;

  final _loading = <String>{};
  final _failures = <String, _SlotFailure>{};

  int get _totalSlotCount => _slots.length;
  int get _requiredCount => _slots.where((slot) => !slot.isOptional).length;

  Future<List<PlatformFile>> _pick({required bool allowMultiple}) async {
    if (widget.pickerSeam != null) {
      return widget.pickerSeam!(
        allowMultiple: allowMultiple,
        allowedExtensions: const ['pdf'],
      );
    }
    if (allowMultiple) {
      return FilePickerUtil.pickMultipleFiles(allowedExtensions: const ['pdf']);
    }
    final file = await FilePickerUtil.pickSingleFile(
      allowedExtensions: const ['pdf'],
    );
    return file == null ? const [] : [file];
  }

  Future<void> _select(PengajuanStep3DocumentConfig slot) async {
    setState(() {
      _loading.add(slot.key);
      _failures.remove(slot.key);
    });

    List<PlatformFile> files;
    try {
      files = await _pick(allowMultiple: slot.allowsMultiple);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading.remove(slot.key);
        _failures[slot.key] = const _SlotFailure(
          'Kendala perangkat',
          'Terjadi kendala saat mengakses berkas. Silakan coba lagi.',
        );
      });
      return;
    }

    if (!mounted) return;
    if (files.isEmpty) {
      setState(() => _loading.remove(slot.key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada berkas dipilih. Data tetap tidak berubah.'),
        ),
      );
      return;
    }

    final invalid = files.firstWhere(
      (file) => !_isPdf(file),
      orElse: () => PlatformFile(name: '', size: 0),
    );
    if (invalid.name.isNotEmpty) {
      setState(() {
        _loading.remove(slot.key);
        _failures[slot.key] = _SlotFailure(
          invalid.name,
          'Format berkas harus PDF. Silakan pilih berkas PDF dan coba lagi.',
        );
      });
      return;
    }

    final tooLarge = files.firstWhere(
      (file) => file.size > slot.maxBytes,
      orElse: () => PlatformFile(name: '', size: 0),
    );
    if (tooLarge.name.isNotEmpty) {
      final old = ref.read(pengajuanFormProvider).uploadedDocs[slot.key];
      setState(() {
        _loading.remove(slot.key);
        _failures[slot.key] = _SlotFailure(
          tooLarge.name,
          'File melebihi batas maksimal ' +
              (slot.maxBytes ~/ (1024 * 1024)).toString() +
              ' MB.' +
              (old == null ? '' : ' Berkas lama tetap tersimpan.'),
        );
      });
      return;
    }

    final references = files.map(FilePickerUtil.referenceOf).toList();
    final notifier = ref.read(pengajuanFormProvider.notifier);
    if (slot.allowsMultiple) {
      notifier.uploadDocuments(slot.key, references);
    } else {
      notifier.uploadDocument(slot.key, references.first);
    }
    setState(() {
      _loading.remove(slot.key);
      _failures.remove(slot.key);
    });
  }

  bool _isPdf(PlatformFile file) {
    final reference = file.path ?? file.name;
    final name = reference.split(RegExp(r'[/\\]')).last.toLowerCase();
    return name.endsWith('.pdf');
  }

  void _delete(PengajuanStep3DocumentConfig slot) {
    ref.read(pengajuanFormProvider.notifier).deleteDocument(slot.key);
    setState(() => _failures.remove(slot.key));
  }

  bool _hasFile(PengajuanStep3DocumentConfig slot, PengajuanFormState state) {
    if (slot.allowsMultiple) {
      return state.multiUploadedDocs[slot.key]?.isNotEmpty == true ||
          state.uploadedDocs[slot.key]?.trim().isNotEmpty == true;
    }
    return state.uploadedDocs[slot.key]?.trim().isNotEmpty == true;
  }

  int _uploadedRequired(PengajuanFormState state) =>
      _slots.where((slot) => !slot.isOptional && _hasFile(slot, state)).length;

  int _uploadedCount(PengajuanFormState state) =>
      _slots.where((slot) => _hasFile(slot, state)).length;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pengajuanFormProvider);
    final uploaded = _uploadedCount(state);
    final isComplete = _uploadedRequired(state) == _requiredCount;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Column(
        children: [
          PengajuanStepHeader(
            subtitle: 'Langkah 3 dari 5',
            onBackPressed: () => context.pop(),
          ),
          const StepperHeader(currentStep: 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _buildVerificationBanner(uploaded, isComplete),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Berkas Persyaratan (11)',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _statusPill(
                      isComplete ? 'Lengkap' : 'Mandatori SIPP',
                      isComplete
                          ? AppColors.statusSuccessText
                          : AppColors.textSecondary,
                      isComplete
                          ? AppColors.statusSuccessSurface
                          : AppColors.slate100,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._slots.map(
                  (slot) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildSlot(slot, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isComplete),
    );
  }

  Widget _buildVerificationBanner(int uploaded, bool isComplete) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statusPill(
                  'Fase Verifikasi Administratif',
                  AppColors.primaryRed,
                  AppColors.primarySurfaceSoft,
                ),
              ),
              const Icon(
                Icons.folder_copy_outlined,
                color: AppColors.primaryRed,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Kelengkapan Dokumen Perizinan Perumahan',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status Pengunggahan',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                uploaded.toString() +
                    ' dari ' +
                    _totalSlotCount.toString() +
                    ' berkas telah siap',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isComplete
                      ? AppColors.statusSuccessText
                      : AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadii.pill,
            child: LinearProgressIndicator(
              minHeight: 6,
              value: uploaded / _totalSlotCount,
              backgroundColor: AppColors.primarySurfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.statusSuccessText : AppColors.primaryRed,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.statusUrgentText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Format berkas PDF wajib terlegalisir pejabat berwenang / instansi teknis terkait Kota Tasikmalaya (Maks. 10 MB per file).',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(
    PengajuanStep3DocumentConfig slot,
    PengajuanFormState state,
  ) {
    final files = state.multiUploadedDocs[slot.key] ?? const <String>[];
    final singleFile = state.uploadedDocs[slot.key];
    final hasFile = _hasFile(slot, state);
    final failure = _failures[slot.key];
    final loading = _loading.contains(slot.key);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.control,
        border: Border.all(
          color: failure != null
              ? AppColors.statusUrgentText
              : AppColors.borderSubtle,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _statusPill(
                  hasFile
                      ? (slot.allowsMultiple
                            ? 'Multi-file: ' +
                                  files.length.toString() +
                                  ' Berkas Terlampir'
                            : 'Telah Terunggah')
                      : (loading
                            ? 'Mengunggah...'
                            : failure != null
                            ? 'Gagal'
                            : 'Belum Diunggah'),
                  hasFile
                      ? AppColors.statusSuccessText
                      : loading
                      ? AppColors.statusWarningText
                      : failure != null
                      ? AppColors.statusUrgentText
                      : AppColors.textSecondary,
                  hasFile
                      ? AppColors.statusSuccessSurface
                      : loading
                      ? AppColors.statusWarningSurface
                      : failure != null
                      ? AppColors.statusUrgentSurface
                      : AppColors.slate100,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                slot.isOptional ? 'Opsional' : 'Wajib',
                style: AppTextStyles.labelSmall.copyWith(
                  color: slot.isOptional
                      ? AppColors.textSecondary
                      : AppColors.statusUrgentText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slot.number + '. ' + slot.label + (slot.isOptional ? '' : ' *'),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (slot.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              slot.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildFailure(slot, failure),
          ] else if (loading) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(
              minHeight: 5,
              color: AppColors.primaryRed,
            ),
          ] else if (hasFile) ...[
            const SizedBox(height: AppSpacing.sm),
            ..._buildFiles(
              slot,
              files.isEmpty && singleFile != null ? [singleFile] : files,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            _uploadButton(slot),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFiles(
    PengajuanStep3DocumentConfig slot,
    List<String> files,
  ) {
    return [
      ...files.map(
        (file) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: AppRadii.small,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 18,
                  color: AppColors.statusUrgentText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    file.split(RegExp(r'[/\\\\]')).last,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                if (slot.allowsMultiple)
                  IconButton(
                    tooltip: 'Hapus berkas',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _delete(slot),
                  )
                else
                  TextButton(
                    onPressed: () => _select(slot),
                    child: const Text('Ganti'),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (slot.allowsMultiple)
        OutlinedButton.icon(
          onPressed: () => _select(slot),
          icon: const Icon(Icons.add, size: 18),
          label: Text(slot.actionLabel),
        ),
    ];
  }

  Widget _buildFailure(
    PengajuanStep3DocumentConfig slot,
    _SlotFailure failure,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentSurface,
        borderRadius: AppRadii.small,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.statusUrgentText,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failure.fileName + '\n' + failure.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusUrgentText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _select(slot),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _uploadButton(PengajuanStep3DocumentConfig slot) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _select(slot),
        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
        label: Text(
          slot.actionLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _statusPill(String text, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.tight,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isComplete) {
    final useStackedActions =
        MediaQuery.textScalerOf(context).scale(14) > 20 ||
        MediaQuery.sizeOf(context).width < 370;
    return Material(
      color: AppColors.cardSurface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 14,
                    color: AppColors.statusSuccessText,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Tersimpan otomatis untuk sesi ini',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Draft formulir disimpan untuk sesi ini.',
                        ),
                      ),
                    ),
                    child: const Text('Simpan Draft'),
                  ),
                ],
              ),
              if (useStackedActions) ...[
                AppButton.secondary(
                  text: 'Kembali',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.primary(
                  text: 'Lanjut ke Langkah 4',
                  trailingIcon: const Icon(Icons.arrow_forward, size: 18),
                  onPressed: isComplete
                      ? () => context.push('/pengajuan/step4')
                      : null,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        text: 'Kembali',
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Lanjut ke Langkah 4',
                        trailingIcon: const Icon(Icons.arrow_forward, size: 18),
                        onPressed: isComplete
                            ? () => context.push('/pengajuan/step4')
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
