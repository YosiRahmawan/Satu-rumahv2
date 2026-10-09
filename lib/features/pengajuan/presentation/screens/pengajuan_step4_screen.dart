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

typedef Step4FilePickerSeam =
    Future<List<PlatformFile>> Function({
      required bool allowMultiple,
      List<String>? allowedExtensions,
    });

class PengajuanStep4Screen extends ConsumerStatefulWidget {
  const PengajuanStep4Screen({super.key, this.pickerSeam});

  final Step4FilePickerSeam? pickerSeam;

  @override
  ConsumerState<PengajuanStep4Screen> createState() =>
      _PengajuanStep4ScreenState();
}

class _FileFailure {
  const _FileFailure(this.fileName, this.message);

  final String fileName;
  final String message;
}

class _PengajuanStep4ScreenState extends ConsumerState<PengajuanStep4Screen> {
  static const _maxTechnicalFileBytes = 50 * 1024 * 1024;
  static const _sitePlanKey = 'site_plan';
  static const _otherKey = PengajuanFormState.technicalOtherDocumentsKey;
  static const _sitePlanExtensions = ['dwg', 'pdf'];
  static const _otherExtensions = ['pdf'];

  final _loadingGroups = <String>{};
  final _cancelRequested = <String>{};
  final _failures = <String, _FileFailure>{};
  final _fileSizes = <String, int>{};
  final _selectionGenerations = <String, int>{};

  Future<List<PlatformFile>> _pick({
    required List<String> allowedExtensions,
  }) async {
    if (widget.pickerSeam != null) {
      return widget.pickerSeam!(
        allowMultiple: true,
        allowedExtensions: allowedExtensions,
      );
    }
    return FilePickerUtil.pickMultipleFiles(
      allowedExtensions: allowedExtensions,
    );
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String _displayName(String reference) =>
      reference.split(RegExp(r'[/\\]')).last;

  Future<void> _selectGroup({required String group}) async {
    final isSitePlan = group == _sitePlanKey;
    final allowed = isSitePlan ? _sitePlanExtensions : _otherExtensions;
    final generation = (_selectionGenerations[group] ?? 0) + 1;
    _selectionGenerations[group] = generation;
    setState(() {
      _loadingGroups.add(group);
      _cancelRequested.remove(group);
      _failures.remove(group);
    });

    List<PlatformFile> files;
    try {
      files = await _pick(allowedExtensions: allowed);
    } catch (_) {
      if (!mounted || generation != _selectionGenerations[group]) return;
      if (_cancelRequested.remove(group)) return;
      setState(() {
        _loadingGroups.remove(group);
        _failures[group] = const _FileFailure(
          'Kendala perangkat',
          'Pemilih berkas tidak dapat dibuka. Silakan coba lagi.',
        );
      });
      return;
    }

    if (!mounted || generation != _selectionGenerations[group]) return;
    final cancelled = _cancelRequested.remove(group);
    setState(() => _loadingGroups.remove(group));
    if (cancelled) return;
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada berkas dipilih. Data tetap tidak berubah.'),
        ),
      );
      return;
    }

    final valid = <String>[];
    final failures = <String>[];
    for (final file in files) {
      final reference = FilePickerUtil.referenceOf(file);
      final extension = _extension(file.name);
      if (!allowed.contains(extension)) {
        failures.add(
          '${isSitePlan ? 'Format tidak didukung. Gunakan DWG atau PDF.' : 'Format tidak didukung. Gunakan PDF.'} (${file.name})',
        );
        continue;
      }
      if (file.size > _maxTechnicalFileBytes) {
        failures.add('Ukuran melebihi batas 50 MB per file (${file.name})');
        continue;
      }
      if (valid.contains(reference)) continue;
      valid.add(reference);
      _fileSizes[reference] = file.size;
    }

    if (valid.isNotEmpty) {
      final notifier = ref.read(pengajuanFormProvider.notifier);
      if (isSitePlan) {
        notifier.addTechnicalFiles(valid);
      } else {
        notifier.uploadDocuments(_otherKey, valid);
      }
    }
    if (failures.isNotEmpty) {
      setState(
        () => _failures[group] = _FileFailure(
          failures.length == 1
              ? failures.first.split(': ').first
              : 'Berkas teknis',
          failures.join('\n'),
        ),
      );
    }
  }

  void _cancelSelection(String group) {
    if (_loadingGroups.contains(group)) {
      _selectionGenerations[group] = (_selectionGenerations[group] ?? 0) + 1;
      setState(() {
        _cancelRequested.add(group);
        _loadingGroups.remove(group);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pengajuanFormProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(184),
        child: PengajuanStepHeader(
          subtitle: 'Langkah 4 dari 5',
          onBackPressed: _backToStep3,
        ),
      ),
      body: Column(
        children: [
          const StepperHeader(currentStep: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTechnicalNotice(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGroup(
                    group: _sitePlanKey,
                    title:
                        'Dokumen Perencanaan & Perancangan Site Plan Perumahan',
                    subtitle:
                        'Wajib melampirkan berkas utama perencanaan teknis',
                    extensions: 'DWG / PDF',
                    files: state.technicalFiles,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGroup(
                    group: _otherKey,
                    title: 'Dokumen Kajian Teknis Lainnya',
                    subtitle:
                        'Laporan penyelidikan tanah (soil test), perhitungan hidrologi & kontur tanah.',
                    extensions: 'PDF',
                    files: state.technicalOtherFiles,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(state.isStep4Valid),
    );
  }

  Widget _buildTechnicalNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurfaceSoft,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.primarySurfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.primaryRed, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketentuan Format Teknis',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prototype lokal: Rencana Tapak (Site Plan) menampilkan kebutuhan file digital CAD (.DWG) skala koordinat ril UTM dan PDF legalisir berskala tinggi (maks. 50 MB per file). Status di layar ini belum berarti upload ke server.',
                  style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildGroup({
    required String group,
    required String title,
    required String subtitle,
    required String extensions,
    required List<String> files,
  }) {
    final isLoading = _loadingGroups.contains(group);
    final failure = _failures[group];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: _formatPills(extensions),
              ),
            ],
          ),
          if (files.isNotEmpty || failure != null || isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
          ],
          ...files.asMap().entries.map(
            (entry) => _buildFileRow(
              group: group,
              index: entry.key,
              reference: entry.value,
            ),
          ),
          if (isLoading) _buildLoadingRow(group),
          if (failure != null) _buildFailureRow(group, failure),
          const SizedBox(height: AppSpacing.sm),
          _buildAddButton(group: group, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _formatPills(String extensions) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: extensions
          .split(' / ')
          .map(
            (extension) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.slate100,
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                extension,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFileRow({
    required String group,
    required int index,
    required String reference,
  }) {
    final name = _displayName(reference);
    final isDwg = _extension(name) == 'dwg';
    final size = _fileSizes[reference];
    final notifier = ref.read(pengajuanFormProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDwg
                  ? AppColors.statusSurveySurface
                  : AppColors.primarySurface,
              borderRadius: AppRadii.small,
            ),
            child: Icon(
              isDwg ? Icons.architecture : Icons.picture_as_pdf,
              color: isDwg ? AppColors.statusSurveyText : AppColors.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (size != null)
                      Text(
                        _formatSize(size),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    _statusBadge(
                      isDwg ? 'CAD Validated' : 'Terverifikasi Otomatis',
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus ${_displayName(reference)}',
            onPressed: () => group == _sitePlanKey
                ? notifier.removeTechnicalFile(index)
                : notifier.removeTechnicalOtherFile(index),
            icon: const Icon(Icons.delete_outline, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRow(String group) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurfaceSoft,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.primarySurfaceBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Memeriksa berkas secara lokal...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryRed,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cancelSelection(group),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureRow(String group, _FileFailure failure) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentSurface,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${failure.fileName}\n${failure.message}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusUrgentText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _failures.remove(group)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({required String group, required bool isLoading}) {
    final isSitePlan = group == _sitePlanKey;
    return OutlinedButton.icon(
      onPressed: isLoading
          ? () => _cancelSelection(group)
          : () => _selectGroup(group: group),
      icon: Icon(isLoading ? Icons.close : Icons.add_circle_outline, size: 18),
      label: Text(
        isLoading
            ? 'Batal memilih berkas'
            : '+ Tambah File ${isSitePlan ? 'Site Plan (DWG/PDF)' : 'Kajian (PDF)'}',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isLoading ? AppColors.error : AppColors.primaryRed,
        side: BorderSide(
          color: isLoading ? AppColors.error : AppColors.primarySurfaceBorder,
        ),
        minimumSize: const Size.fromHeight(44),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.statusSuccessSurface,
        borderRadius: AppRadii.tight,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.statusSuccessText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isValid) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.circle,
                  color: AppColors.statusSuccessText,
                  size: 8,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tersimpan otomatis untuk sesi ini',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Simpan Draft')),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    MediaQuery.sizeOf(context).width < 600 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18;
                final back = AppButton.secondary(
                  text: 'Kembali',
                  onPressed: _backToStep3,
                );
                final next = isCompact
                    ? _buildCompactNextButton(isValid)
                    : AppButton.primary(
                        text: 'Lanjut ke Review & Submit',
                        onPressed: isValid ? _continueToStep5 : null,
                      );
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      back,
                      const SizedBox(height: AppSpacing.sm),
                      next,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: back),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: next),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _backToStep3() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pengajuan/step3');
    }
  }

  void _continueToStep5() => context.push('/pengajuan/step5');

  Widget _buildCompactNextButton(bool isValid) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isValid ? _continueToStep5 : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.textOnRed,
          disabledBackgroundColor: AppColors.grey300,
          disabledForegroundColor: AppColors.grey600,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
        child: const Text(
          'Lanjut ke Review & Submit',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}
