import '../../../../core/widgets/app_loading_spinner.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../providers/pengajuan_form_controller.dart';
import '../widgets/pengajuan_draft_ui.dart';
import '../widgets/smart_validation_bottom_sheet.dart';

/// Persists document file size metadata across screen transitions/navigation in the session.
final pengajuanStep2DocSizesProvider = StateProvider<Map<String, int>>(
  (ref) => {},
);

/// Testable seam for file picking to allow deterministic widget and unit testing.
typedef FilePickerSeam =
    Future<PlatformFile?> Function({List<String>? allowedExtensions});

/// Slot configuration for the 5 mandatory legal documents in Fase 2 - Berkas PT.
class _DocSlotConfig {
  final String key;
  final String number;
  final String title;
  final String? subtitle;
  final String uploadPrompt;

  const _DocSlotConfig({
    required this.key,
    required this.number,
    required this.title,
    this.subtitle,
    required this.uploadPrompt,
  });
}

/// Represents an active validation or file selection failure.
class _SlotError {
  final String fileName;
  final int? fileSize;
  final String reason;
  final String detailedError;

  const _SlotError({
    required this.fileName,
    this.fileSize,
    required this.reason,
    required this.detailedError,
  });
}

/// Screen Pengajuan Baru Fase 2 — Berkas Legalitas Perusahaan (Berkas PT).
///
/// Implements:
/// - Canonical hero [PengajuanStepHeader] & 5-step [StepperHeader].
/// - Single PDF file picker per document slot (max 10 MB validation).
/// - 4 honest UI states: Belum Unggah, Proses, Gagal, and Siap Dikirim.
/// - Dynamic completion percentage and progress bar.
/// - Sticky bottom bar with local draft persistence and navigation guard.
/// - Fully responsive for 360dp, 412dp, and 200% text scale.
class PengajuanStep2Screen extends ConsumerStatefulWidget {
  const PengajuanStep2Screen({super.key, this.pickerSeam});

  /// Optional test seam to inject custom picker behavior for tests.
  final FilePickerSeam? pickerSeam;

  @override
  ConsumerState<PengajuanStep2Screen> createState() =>
      _PengajuanStep2ScreenState();
}

class _PengajuanStep2ScreenState extends ConsumerState<PengajuanStep2Screen> {
  static const List<_DocSlotConfig> _slots = [
    _DocSlotConfig(
      key: 'ktp',
      number: '1',
      title: '1. KTP-el Pemohon / Direktur Utama *',
      uploadPrompt: 'Unggah KTP-el Pemohon (PDF)',
    ),
    _DocSlotConfig(
      key: 'nib',
      number: '2',
      title: '2. Nomor Induk Berusaha (NIB) *',
      uploadPrompt: 'Unggah NIB (PDF)',
    ),
    _DocSlotConfig(
      key: 'npwp_doc',
      number: '3',
      title: '3. NPWP Perusahaan *',
      uploadPrompt: 'Unggah NPWP (PDF)',
    ),
    _DocSlotConfig(
      key: 'asosiasi',
      number: '4',
      title: '4. Bukti Keanggotaan Asosiasi *',
      subtitle: 'REI / APERSI / HIMPERRA yang masih aktif',
      uploadPrompt: 'Unggah Bukti Asosiasi (PDF)',
    ),
    _DocSlotConfig(
      key: 'legalitas',
      number: '5',
      title: '5. Akta Pendirian & SK Kemenkumham *',
      uploadPrompt: 'Unggah Akta Pendirian & SK (PDF)',
    ),
  ];

  final Map<String, _SlotError> _slotErrors = {};
  final Map<String, int> _slotFileSizes = {};
  final Set<String> _loadingKeys = {};

  final ScrollController _scrollController = ScrollController();
  late final Map<String, GlobalKey> _slotKeys = {
    for (final slot in _slots) slot.key: GlobalKey(),
  };
  String? _highlightedSlotKey;
  Timer? _highlightTimer;
  bool _isModalShowing = false;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Ukuran tidak tersedia';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primaryRed),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Panduan Berkas PT',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        content: const Text(
          'Unggah 5 berkas legalitas perusahaan dalam format PDF dengan ukuran maksimal 10 MB per file.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Mengerti',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(String key) async {
    setState(() {
      _loadingKeys.add(key);
    });

    PlatformFile? file;
    Object? pickerError;
    try {
      if (widget.pickerSeam != null) {
        file = await widget.pickerSeam!(allowedExtensions: ['pdf']);
      } else {
        file = await FilePickerUtil.pickSingleFile(allowedExtensions: ['pdf']);
      }
    } catch (e) {
      debugPrint('Error picking file for $key: $e');
      pickerError = e;
    }

    if (!mounted) return;

    if (pickerError != null) {
      setState(() {
        _loadingKeys.remove(key);
        _slotErrors[key] = const _SlotError(
          fileName: 'Gagal memilih berkas',
          reason: 'Kendala perangkat',
          detailedError:
              'Terjadi kendala saat mengakses berkas. Silakan coba lagi.',
        );
      });
      return;
    }

    if (file == null) {
      // Cancellation without state mutation
      setState(() {
        _loadingKeys.remove(key);
      });
      return;
    }

    // PDF extension check
    final fileName = file.name;
    final ext =
        file.extension?.toLowerCase() ??
        (fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '');
    final isPdf = ext == 'pdf' || fileName.toLowerCase().endsWith('.pdf');

    // Max 10 MB validation (10 * 1024 * 1024 = 10,485,760 bytes)
    final isTooLarge = file.size > 10 * 1024 * 1024;

    if (!isPdf) {
      setState(() {
        _loadingKeys.remove(key);
        _slotErrors[key] = _SlotError(
          fileName: fileName,
          fileSize: file!.size,
          reason: 'Bukan format PDF',
          detailedError: 'Format berkas harus berupa dokumen PDF.',
        );
      });
      // CRITICAL: Preserve existing selection so validCount does not drop
      return;
    }

    if (isTooLarge) {
      setState(() {
        _loadingKeys.remove(key);
        _slotErrors[key] = _SlotError(
          fileName: fileName,
          fileSize: file!.size,
          reason: 'Melebihi batas maksimal',
          detailedError: 'File melebihi batas maksimal 10 MB.',
        );
      });
      // CRITICAL: Preserve existing selection so validCount does not drop
      return;
    }

    // Valid file selection
    setState(() {
      _loadingKeys.remove(key);
      _slotErrors.remove(key);
      _slotFileSizes[key] = file!.size;
    });

    ref
        .read(pengajuanStep2DocSizesProvider.notifier)
        .update((m) => {...m, key: file!.size});

    ref
        .read(pengajuanFormProvider.notifier)
        .uploadDocument(key, FilePickerUtil.referenceOf(file));
  }

  void _deleteFile(String key) {
    setState(() {
      _slotErrors.remove(key);
      _slotFileSizes.remove(key);
      _loadingKeys.remove(key);
    });
    ref.read(pengajuanStep2DocSizesProvider.notifier).update((m) {
      final updated = Map<String, int>.from(m);
      updated.remove(key);
      return updated;
    });
    ref.read(pengajuanFormProvider.notifier).deleteDocument(key);
  }

  void _clearError(String key) {
    setState(() {
      _slotErrors.remove(key);
    });
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pengajuan/step1');
    }
  }

  void _highlightAndScrollTo(String? slotKey) {
    if (slotKey == null) return;
    setState(() {
      _highlightedSlotKey = slotKey;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _slotKeys[slotKey];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });

    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _highlightedSlotKey == slotKey) {
        setState(() {
          _highlightedSlotKey = null;
        });
      }
    });
  }

  Future<void> _onNext() async {
    if (_isModalShowing) return;

    final formState = ref.read(pengajuanFormProvider);
    final isStep2Valid = formState.isStep2Valid && _slotErrors.isEmpty;

    if (isStep2Valid) {
      context.push('/pengajuan/step3');
      return;
    }

    final missingSlots = _slots.where((slot) {
      if (_slotErrors.containsKey(slot.key)) return true;
      final doc = formState.uploadedDocs[slot.key];
      return doc == null || doc.trim().isEmpty;
    }).toList();

    final validCount = _slots.length - missingSlots.length;
    final remainingCount = missingSlots.length;

    final missingItems = missingSlots.map((slot) {
      final hasError = _slotErrors.containsKey(slot.key);
      final errorReason = hasError ? _slotErrors[slot.key]!.reason : null;
      return MissingValidationItem(
        key: slot.key,
        title: slot.title,
        subtitle: hasError ? errorReason : 'PDF maks 10MB',
        statusText: hasError ? 'Format Gagal' : 'Belum diunggah',
        icon: Icons.description_outlined,
      );
    }).toList();

    _isModalShowing = true;
    await showSmartValidationBottomSheet(
      context: context,
      title: 'Berkas Belum Lengkap',
      subtitle: 'Lengkapi dokumen wajib sebelum ke Langkah 3.',
      completedCount: validCount,
      totalCount: _slots.length,
      statusBadgeText: '$validCount dari ${_slots.length} berkas lengkap',
      warningText: '$remainingCount berkas wajib belum diunggah',
      sectionTitle: 'DAFTAR DOKUMEN YANG PERLU DIUNGGAH',
      missingItems: missingItems,
      actionButtonText: 'Lengkapi Berkas Sekarang',
      cancelButtonText: 'Kembali ke Formulir',
      onActionPressed: (firstKey) {
        _highlightAndScrollTo(firstKey);
      },
    );
    if (mounted) {
      _isModalShowing = false;
    }
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotHeader(
    _DocSlotConfig slot,
    Widget badge,
    bool isTextScaled,
  ) {
    if (isTextScaled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          if (slot.subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              slot.subtitle!,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          badge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              if (slot.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  slot.subtitle!,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }

  Widget _buildEmptySlot(_DocSlotConfig slot, bool isTextScaled) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlotHeader(
            slot,
            _buildStatusBadge(
              label: 'Belum Unggah',
              color: AppColors.slate600,
              bgColor: AppColors.slate100,
              borderColor: AppColors.slate300,
            ),
            isTextScaled,
          ),
          const SizedBox(height: 12),
          CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.slate300,
              radius: 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FilePickerUtil.uploadIcon,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slot.uploadPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tarik file ke sini atau pilih dari perangkat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pickFile(slot.key),
                    icon: const Icon(
                      FilePickerUtil.uploadIcon,
                      size: 16,
                      color: AppColors.primaryRed,
                    ),
                    label: const Text(
                      'Pilih Berkas',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSlot(_DocSlotConfig slot, bool isTextScaled) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlotHeader(
            slot,
            _buildStatusBadge(
              label: 'Proses',
              color: AppColors.statusWarningText,
              bgColor: AppColors.statusWarningSurface,
              borderColor: AppColors.statusWarningText.withValues(alpha: 0.3),
              icon: Icons.sync,
            ),
            isTextScaled,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLoadingSpinner.small(color: AppColors.primaryRed),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Memeriksa dan memproses berkas...',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _loadingKeys.remove(slot.key);
                        });
                      },
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.primarySurface,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryRed),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSlot(
    _DocSlotConfig slot,
    _SlotError error,
    bool isTextScaled, {
    String? existingFilePath,
  }) {
    final hasExistingFile =
        existingFilePath != null && existingFilePath.trim().isNotEmpty;
    final previousFileName = hasExistingFile
        ? existingFilePath.split(RegExp(r'[/\\]')).last
        : null;
    final retryActionLabel = hasExistingFile ? 'Coba Lagi' : 'Ganti Berkas';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryRed.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlotHeader(
            slot,
            _buildStatusBadge(
              label: 'Gagal',
              color: AppColors.statusUrgentText,
              bgColor: AppColors.primarySurface,
              borderColor: AppColors.statusUrgentText.withValues(alpha: 0.3),
              icon: Icons.error_outline,
            ),
            isTextScaled,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primarySurfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
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
                            error.fileName,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            error.fileSize != null
                                ? '${_formatFileSize(error.fileSize!)} • ${error.reason}'
                                : error.reason,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup pesan kesalahan',
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.slate400,
                        size: 18,
                      ),
                      onPressed: () => _clearError(slot.key),
                    ),
                  ],
                ),
                if (hasExistingFile) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppColors.statusSuccessText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Berkas lama ($previousFileName) tetap tersimpan.',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (isTextScaled) ...[
                  Text(
                    error.detailedError,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _pickFile(slot.key),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        retryActionLabel,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          error.detailedError,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11.5,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _pickFile(slot.key),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          retryActionLabel,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidSlot(
    _DocSlotConfig slot,
    String filePath,
    bool isTextScaled,
    Map<String, int> docSizes,
  ) {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final cachedSize = docSizes[slot.key] ?? _slotFileSizes[slot.key];
    int effectiveSize = cachedSize ?? 0;
    // dart:io is unavailable on web; the stored reference is the file name there.
    if (effectiveSize == 0 && !kIsWeb) {
      try {
        final f = File(filePath);
        if (f.existsSync()) {
          effectiveSize = f.lengthSync();
          _slotFileSizes[slot.key] = effectiveSize;
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlotHeader(
            slot,
            _buildStatusBadge(
              label: 'Siap Dikirim',
              color: AppColors.statusSuccessText,
              bgColor: AppColors.statusSuccessSurface,
              borderColor: AppColors.statusSuccessText.withValues(alpha: 0.3),
              icon: Icons.check_circle_outline,
            ),
            isTextScaled,
          ),
          const SizedBox(height: 12),
          UploadedFileTile(
            fileName: fileName,
            sizeBytes: effectiveSize,
            onPreview: () => FilePickerUtil.showAppDocumentPreview(
              context,
              fileName: fileName,
              title: slot.title,
              fileSize: effectiveSize,
            ),
            onReplace: () => _pickFile(slot.key),
            onDelete: () => _deleteFile(slot.key),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int validCount, bool isTextScaled) {
    final percentage = (validCount * 20);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTextScaled) ...[
            const Text(
              'Kelengkapan Berkas Legalitas Perusahaan',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadii.pill,
              ),
              child: const Text(
                'Wajib 5',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Kelengkapan Berkas Legalitas Perusahaan',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: AppRadii.pill,
                  ),
                  child: const Text(
                    'Wajib 5',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Unggah dokumen resmi untuk validasi perizinan.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Completion status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$validCount dari 5 berkas dipilih',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: validCount / 5.0,
              backgroundColor: AppColors.primarySurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // Guidance notice container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryRed, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Format dokumen PDF, ukuran maksimal 10 MB per berkas.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
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

  Widget _buildBackButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.backgroundCanvas,
      ),
      onPressed: _onBack,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Kembali',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isStep2Valid) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      onPressed: _onNext,
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Lanjut ke Langkah 3',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(pengajuanFormProvider);
    final docSizes = ref.watch(pengajuanStep2DocSizesProvider);
    final isTextScaled = MediaQuery.textScalerOf(context).scale(14) > 20;

    // Count how many of the 5 specific slots are uploaded
    final validCount = _slots.where((slot) {
      final doc = formState.uploadedDocs[slot.key];
      return doc != null && doc.trim().isNotEmpty;
    }).length;

    final isStep2Valid = formState.isStep2Valid;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Canonical Hero Header matching prototype
            PengajuanStepHeader(
              title: 'Pengajuan Baru',
              subtitle: 'Langkah 2 dari 5',
              onBackPressed: _onBack,
              onHelpPressed: () => _showHelpDialog(context),
            ),

            // Stepper indicator
            const StepperHeader(currentStep: 2),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary & progress card
                  _buildSummaryCard(validCount, isTextScaled),

                  const SizedBox(height: AppSpacing.md),

                  // The 5 document slots
                  ..._slots.map((slot) {
                    Widget slotWidget;
                    if (_loadingKeys.contains(slot.key)) {
                      slotWidget = _buildLoadingSlot(slot, isTextScaled);
                    } else if (_slotErrors.containsKey(slot.key)) {
                      slotWidget = _buildErrorSlot(
                        slot,
                        _slotErrors[slot.key]!,
                        isTextScaled,
                        existingFilePath: formState.uploadedDocs[slot.key],
                      );
                    } else {
                      final uploadedDoc = formState.uploadedDocs[slot.key];
                      if (uploadedDoc != null &&
                          uploadedDoc.trim().isNotEmpty) {
                        slotWidget = _buildValidSlot(
                          slot,
                          uploadedDoc,
                          isTextScaled,
                          docSizes,
                        );
                      } else {
                        slotWidget = _buildEmptySlot(slot, isTextScaled);
                      }
                    }

                    final isHighlighted = _highlightedSlotKey == slot.key;
                    return KeyedSubtree(
                      key: _slotKeys[slot.key],
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: isHighlighted
                              ? Border.all(
                                  color: AppColors.primaryRed,
                                  width: 2.0,
                                )
                              : null,
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryRed.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: slotWidget,
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status simpan otomatis dan tombol Simpan Draft
              const DraftStatusRow(),
              const SizedBox(height: 10),

              // Action buttons (Kembali & Lanjut ke Langkah 3)
              if (isTextScaled) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNextButton(isStep2Valid),
                    const SizedBox(height: 8),
                    _buildBackButton(),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(flex: 4, child: _buildBackButton()),
                    const SizedBox(width: 12),
                    Expanded(flex: 6, child: _buildNextButton(isStep2Valid)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw clean dashed borders matching the prototype upload area.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _strokeWidth = 1.2;
  static const double _dash = 6.0;
  static const double _gap = 4.0;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + _dash < metric.length)
            ? _dash
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
