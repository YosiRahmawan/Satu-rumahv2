// The few string concatenations below keep this screen easy to generate and
// readable around platform-specific file references.
// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_const_constructors, unused_element_parameter

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../providers/pengajuan_form_controller.dart';
import '../widgets/pengajuan_draft_ui.dart';
import '../widgets/smart_validation_bottom_sheet.dart';

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
  final Map<String, int> _slotFileSizes = {};

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
      final result = await FilePickerUtil.pickMultipleFilesResult(
        allowedExtensions: const ['pdf'],
      );
      if (result.isFailed) {
        throw result.error ?? StateError('File picker gagal.');
      }
      return result.value ?? const [];
    }
    final result = await FilePickerUtil.pickSingleFileResult(
      allowedExtensions: const ['pdf'],
    );
    if (result.isFailed) {
      throw result.error ?? StateError('File picker gagal.');
    }
    final file = result.value;
    return file == null ? const [] : [file];
  }

  Future<void> _select(PengajuanStep3DocumentConfig slot) async {
    if (_loading.contains(slot.key)) return;

    setState(() {
      _loading.add(slot.key);
      _failures.remove(slot.key);
    });

    try {
      final files = await _pick(allowMultiple: slot.allowsMultiple);
      if (!mounted) return;
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada berkas dipilih. Data tetap tidak berubah.',
            ),
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
      for (final f in files) {
        final refName = FilePickerUtil.referenceOf(f);
        _slotFileSizes[refName] = f.size;
        _slotFileSizes[f.name] = f.size;
        _slotFileSizes[slot.key] = f.size;
      }
      final notifier = ref.read(pengajuanFormProvider.notifier);
      if (slot.allowsMultiple) {
        notifier.uploadDocuments(slot.key, references);
      } else {
        notifier.uploadDocument(slot.key, references.first);
      }
      setState(() => _failures.remove(slot.key));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failures[slot.key] = const _SlotFailure(
          'Kendala perangkat',
          'Terjadi kendala saat mengakses berkas. Silakan coba lagi.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading.remove(slot.key));
      }
    }
  }

  bool _isPdf(PlatformFile file) {
    final reference = FilePickerUtil.referenceOf(file);
    final name = reference.split(RegExp(r'[/\\]')).last.toLowerCase();
    return name.endsWith('.pdf');
  }

  void _delete(PengajuanStep3DocumentConfig slot) {
    ref.read(pengajuanFormProvider.notifier).deleteDocument(slot.key);
    setState(() {
      _failures.remove(slot.key);
      _slotFileSizes.remove(slot.key);
    });
  }

  void _deleteFile(PengajuanStep3DocumentConfig slot, String file) {
    if (slot.allowsMultiple) {
      ref
          .read(pengajuanFormProvider.notifier)
          .deleteMultiDocumentFile(slot.key, file);
      setState(() {
        _failures.remove(slot.key);
        _slotFileSizes.remove(file);
        _slotFileSizes.remove(file.split(RegExp(r'[/\\]')).last);
      });
    } else {
      _delete(slot);
    }
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

  bool _isModalShowing = false;

  void _backToStep2() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pengajuan/step2');
    }
  }

  void _onNext() async {
    final formState = ref.read(pengajuanFormProvider);
    final isStep3Valid = formState.isStep3Valid;

    if (isStep3Valid) {
      context.push('/pengajuan/step4');
      return;
    }

    if (_isModalShowing) return;

    final missingSlots = _slots.where((slot) {
      if (slot.isOptional) return false;
      final doc = formState.uploadedDocs[slot.key];
      return doc == null || doc.trim().isEmpty;
    }).toList();

    final completedCount = _requiredCount - missingSlots.length;

    final missingItems = missingSlots.map((slot) {
      final hasFailure = _failures.containsKey(slot.key);
      final failureMessage = hasFailure ? _failures[slot.key]!.message : null;
      return MissingValidationItem(
        key: slot.key,
        title: '${slot.number}. ${slot.label} *',
        subtitle: failureMessage ?? slot.description ?? 'Format PDF maks 10MB',
        statusText: hasFailure ? 'Format Gagal' : 'Belum diunggah',
        icon: Icons.description_outlined,
      );
    }).toList();

    _isModalShowing = true;
    await showSmartValidationBottomSheet(
      context: context,
      title: 'Berkas Belum Lengkap',
      subtitle: 'Lengkapi dokumen wajib sebelum ke Langkah 4.',
      completedCount: completedCount,
      totalCount: _requiredCount,
      statusBadgeText: '$completedCount dari $_requiredCount berkas lengkap',
      warningText: '${missingSlots.length} berkas wajib belum diunggah',
      sectionTitle: 'DAFTAR DOKUMEN YANG PERLU DIUNGGAH',
      missingItems: missingItems,
      actionButtonText: 'Lengkapi Berkas Sekarang',
      cancelButtonText: 'Kembali ke Formulir',
    );
    if (mounted) {
      _isModalShowing = false;
    }
  }

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
            onBackPressed: _backToStep2,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar berkas ($_totalSlotCount)',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Wajib diisi bertanda *',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
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
    final statusColor = isComplete
        ? AppColors.statusSuccessText
        : AppColors.primaryRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE4E6)),
            ),
            child: const Text(
              'Fase Verifikasi Administratif',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBE123C),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text(
                  'Dokumen perumahan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '$uploaded dari $_totalSlotCount siap',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: uploaded / _totalSlotCount,
              backgroundColor: const Color(0xFFFFE4E6),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'PDF, maks. 10 MB per file, dilegalisir pejabat berwenang.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: failure != null
              ? AppColors.statusUrgentText
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(
                hasFile: hasFile,
                loading: loading,
                failure: failure != null,
                count: files.length,
                allowsMultiple: slot.allowsMultiple,
              ),
              _buildRequirementTag(slot.isOptional),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${slot.number}. ${slot.label}${slot.isOptional ? '' : ' *'}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          if (slot.description != null) ...[
            const SizedBox(height: 4),
            Text(
              slot.description!,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (failure != null)
            _buildFailure(slot, failure)
          else if (loading)
            _buildLoading(slot)
          else if (hasFile)
            ..._buildFiles(
              slot,
              files.isEmpty && singleFile != null ? [singleFile] : files,
            )
          else
            _uploadButton(slot),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool hasFile,
    required bool loading,
    required bool failure,
    required int count,
    required bool allowsMultiple,
  }) {
    final String text;
    final Color textColor;
    final Color bgColor;
    final Color borderColor;

    if (hasFile) {
      text = allowsMultiple
          ? 'Multi-file: $count Berkas Terlampir'
          : 'Telah Terunggah';
      textColor = const Color(0xFF047857);
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
    } else if (loading) {
      text = 'Mengunggah...';
      textColor = const Color(0xFFB45309);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
    } else if (failure) {
      text = 'Gagal';
      textColor = const Color(0xFFB91C1C);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECDD3);
    } else {
      text = 'Belum Diunggah';
      textColor = const Color(0xFF475569);
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildRequirementTag(bool isOptional) {
    if (isOptional) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Opsional',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }
    return const Text(
      'Wajib',
      style: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryRed,
      ),
    );
  }

  Widget _buildLoading(PengajuanStep3DocumentConfig slot) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryRed,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Memeriksa dan memproses berkas...',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(
              minHeight: 4,
              color: AppColors.primaryRed,
              backgroundColor: Color(0xFFFEE2E2),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFiles(
    PengajuanStep3DocumentConfig slot,
    List<String> files,
  ) {
    return [
      ...files.map((file) {
        final fileName = file.split(RegExp(r'[/\\\\]')).last;
        final size =
            _slotFileSizes[file] ??
            _slotFileSizes[fileName] ??
            _slotFileSizes[slot.key];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: UploadedFileTile(
            fileName: fileName,
            sizeBytes: size,
            onPreview: () => FilePickerUtil.showAppDocumentPreview(
              context,
              fileName: fileName,
              title: slot.label,
              fileSize: size,
            ),
            onReplace: () => _select(slot),
            onDelete: () => _deleteFile(slot, file),
          ),
        );
      }),
      if (slot.allowsMultiple)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _select(slot),
              icon: const Icon(FilePickerUtil.uploadIcon, size: 18),
              label: Text(slot.actionLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFailure(
    PengajuanStep3DocumentConfig slot,
    _SlotFailure failure,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.primaryRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${failure.fileName}\n${failure.message}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _select(slot),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(54, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadButton(PengajuanStep3DocumentConfig slot) {
    final isOptional = slot.isOptional;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _select(slot),
        icon: Icon(
          FilePickerUtil.uploadIcon,
          size: 16,
          color: isOptional ? const Color(0xFF64748B) : AppColors.primaryRed,
        ),
        label: Text(
          slot.actionLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isOptional ? const Color(0xFF334155) : AppColors.primaryRed,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isOptional
              ? const Color(0xFF334155)
              : AppColors.primaryRed,
          side: BorderSide(
            color: isOptional ? const Color(0xFFCBD5E1) : AppColors.primaryRed,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isComplete) {
    final useStackedActions =
        MediaQuery.textScalerOf(context).scale(14) > 20 ||
        MediaQuery.sizeOf(context).width < 370;
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.1),
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
              const DraftStatusRow(),
              const SizedBox(height: 10),
              if (useStackedActions) ...[
                AppButton.secondary(text: 'Kembali', onPressed: _backToStep2),
                const SizedBox(height: AppSpacing.sm),
                AppButton.primary(
                  text: 'Lanjut ke Langkah 4',
                  onPressed: _onNext,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        text: 'Kembali',
                        onPressed: _backToStep2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Lanjut ke Langkah 4',
                        onPressed: _onNext,
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
