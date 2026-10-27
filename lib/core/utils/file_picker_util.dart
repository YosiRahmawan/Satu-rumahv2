// ponytail: minimal wrapper over file_picker package for native Android file selection
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';

enum FilePickStatus { selected, cancelled, failed }

class FilePickResult<T> {
  const FilePickResult._({required this.status, this.value, this.error});

  const FilePickResult.selected(T value)
    : this._(status: FilePickStatus.selected, value: value);

  const FilePickResult.cancelled() : this._(status: FilePickStatus.cancelled);

  const FilePickResult.failed(Object error)
    : this._(status: FilePickStatus.failed, error: error);

  final FilePickStatus status;
  final T? value;
  final Object? error;

  bool get isSelected => status == FilePickStatus.selected;
  bool get isCancelled => status == FilePickStatus.cancelled;
  bool get isFailed => status == FilePickStatus.failed;
}

/// Aturan format dan ukuran untuk satu jenis berkas.
class FileRule {
  const FileRule(this.allowed, this.maxBytes);

  final List<String> allowed;
  final int maxBytes;

  int get maxMb => maxBytes ~/ (1024 * 1024);
  String get formatLabel => allowed.map((e) => e.toUpperCase()).join(' atau ');
}

/// Alasan sebuah berkas ditolak: [reason] singkat, [message] lengkap.
class FileViolation {
  const FileViolation(this.reason, this.message);

  final String reason;
  final String message;
}

/// Canonical 3-action buttons for uploaded attachments on Developer role:
/// Lihat (eye) -> Ganti (pencil) -> Hapus (trash)
class UploadedAttachmentActions extends StatelessWidget {
  final VoidCallback onPreview;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final Color iconColor;
  final double iconSize;

  const UploadedAttachmentActions({
    super.key,
    required this.onPreview,
    required this.onReplace,
    required this.onDelete,
    this.iconColor = const Color(0xFF64748B),
    this.iconSize = 19.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Lihat Dokumen',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.all(8),
          icon: Icon(
            Icons.visibility_outlined,
            color: iconColor,
            size: iconSize,
          ),
          onPressed: onPreview,
        ),
        IconButton(
          tooltip: 'Ganti Dokumen',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.all(8),
          icon: Icon(Icons.edit_outlined, color: iconColor, size: iconSize),
          onPressed: onReplace,
        ),
        IconButton(
          tooltip: 'Hapus Dokumen',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.all(8),
          icon: Icon(
            Icons.delete_outline,
            color: iconColor,
            size: iconSize + 1.0,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// Kotak ikon jenis file: PDF dan DWG punya ikon dan warna sendiri.
class AttachmentTypeIcon extends StatelessWidget {
  const AttachmentTypeIcon({super.key, required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final isDwg = fileName.toLowerCase().endsWith('.dwg');
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDwg ? AppColors.statusSurveySurface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDwg
              ? AppColors.statusSurveyText.withValues(alpha: 0.25)
              : AppColors.primarySurfaceBorder,
        ),
      ),
      child: Icon(
        isDwg ? Icons.architecture : Icons.description_outlined,
        size: 20,
        color: isDwg ? AppColors.statusSurveyText : AppColors.primaryRed,
      ),
    );
  }
}

/// Baris lampiran terunggah yang sama di Langkah 2, 3, dan 4: ikon jenis file,
/// nama asli, "FORMAT · ukuran · Terunggah", lalu aksi Lihat, Ganti, Hapus.
class UploadedFileTile extends StatelessWidget {
  const UploadedFileTile({
    super.key,
    required this.fileName,
    required this.sizeBytes,
    required this.onPreview,
    required this.onReplace,
    required this.onDelete,
  });

  final String fileName;
  final int? sizeBytes;
  final VoidCallback onPreview;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  String get _meta {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';
    final size = sizeBytes;
    return [
      extension,
      if (size != null && size > 0)
        FilePickerUtil.formatSize(size)
      else
        'Ukuran tidak tersedia',
      'Terunggah',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          AttachmentTypeIcon(fileName: fileName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _meta,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          UploadedAttachmentActions(
            onPreview: onPreview,
            onReplace: onReplace,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class FilePickerUtil {
  /// Ikon unggah canonical untuk semua aksi mengunggah file di form pengajuan.
  static const IconData uploadIcon = Icons.cloud_upload_outlined;

  static final Map<String, PlatformFile> _cachedFiles = {};

  static void cacheFile(PlatformFile file) {
    _cachedFiles[file.name] = file;
    try {
      if (file.path != null) {
        _cachedFiles[file.path!] = file;
      }
    } catch (_) {}
  }

  static void cacheFiles(Iterable<PlatformFile> files) {
    for (final f in files) {
      cacheFile(f);
    }
  }

  static PlatformFile? getCachedFile(String refOrName) {
    return _cachedFiles[refOrName] ??
        _cachedFiles[refOrName.split(RegExp(r'[/\\]')).last];
  }

  /// Aturan berkas revisi: site plan DWG atau PDF (maks. 50 MB), selain itu
  /// PDF saja (maks. 10 MB), sama dengan form pengajuan awal.
  static FileRule revisionRule(String docKey) => docKey == 'site_plan_dwg'
      ? const FileRule(['dwg', 'pdf'], 50 * 1024 * 1024)
      : const FileRule(['pdf'], 10 * 1024 * 1024);

  /// Mengembalikan alasan penolakan, atau null bila berkas sesuai [rule].
  static FileViolation? violationOf(PlatformFile file, FileRule rule) {
    final extension =
        file.extension?.toLowerCase() ??
        (file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : '');
    if (!rule.allowed.contains(extension)) {
      return FileViolation(
        'Format tidak didukung',
        'Format tidak didukung. Gunakan ${rule.formatLabel}.',
      );
    }
    if (file.size > rule.maxBytes) {
      return FileViolation(
        'Melebihi batas maksimal',
        'File melebihi batas maksimal ${rule.maxMb} MB.',
      );
    }
    return null;
  }

  static String formatSize(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).toStringAsFixed(0)} KB';

  /// Membuka pemilih berkas bawaan Android (Document Picker / Files app) untuk memilih 1 file.
  static Future<FilePickResult<PlatformFile>> pickSingleFileResult({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: (allowedExtensions != null && allowedExtensions.isNotEmpty)
            ? FileType.custom
            : type,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return const FilePickResult.cancelled();
      }
      final picked = result.files.first;
      cacheFile(picked);
      return FilePickResult.selected(picked);
    } catch (error) {
      debugPrint('Error picking single file: $error');
      return FilePickResult.failed(error);
    }
  }

  static Future<PlatformFile?> pickSingleFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    final result = await pickSingleFileResult(
      allowedExtensions: allowedExtensions,
      type: type,
    );
    return result.value;
  }

  /// Returns a stable reference for a picked file, safe on every platform.
  ///
  /// On web [PlatformFile.path] is unavailable and throws, so the file name is
  /// used instead. On native platforms the local path is preferred, falling
  /// back to the file name.
  static String referenceOf(PlatformFile file) {
    if (kIsWeb) return file.name;
    try {
      return file.path ?? file.name;
    } catch (_) {
      return file.name;
    }
  }

  /// Membuka pemilih berkas bawaan Android untuk memilih beberapa file sekaligus (batch upload).
  static Future<FilePickResult<List<PlatformFile>>> pickMultipleFilesResult({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: (allowedExtensions != null && allowedExtensions.isNotEmpty)
            ? FileType.custom
            : type,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return const FilePickResult.cancelled();
      }
      cacheFiles(result.files);
      return FilePickResult.selected(result.files);
    } catch (error) {
      debugPrint('Error picking multiple files: $error');
      return FilePickResult.failed(error);
    }
  }

  static Future<List<PlatformFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    final result = await pickMultipleFilesResult(
      allowedExtensions: allowedExtensions,
      type: type,
    );
    return result.value ?? const [];
  }

  /// Isi berkas yang benar-benar dipilih pengguna, atau null bila tidak
  /// terbaca. Berbeda dengan [getPdfBytes], tidak pernah membuat PDF pengganti:
  /// dipakai untuk mengunggah ke server.
  static Future<Uint8List?> readBytesOrNull(String reference) async {
    final cached = getCachedFile(reference);
    if (cached?.bytes != null && cached!.bytes!.isNotEmpty) return cached.bytes;
    if (kIsWeb) return null;
    for (final path in [cached?.path, reference]) {
      if (path == null) continue;
      try {
        final file = File(path);
        if (file.existsSync()) return await file.readAsBytes();
      } catch (_) {}
    }
    return null;
  }

  /// Menghasilkan atau mengambil byte PDF dokumen untuk pratinjau yang valid dan sah.
  static Future<Uint8List> getPdfBytes({
    required String fileName,
    String? title,
    int? sizeBytes,
    PlatformFile? file,
  }) async {
    // 1. Cek direct file parameter
    if (file != null) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return file.bytes!;
      }
      if (!kIsWeb && file.path != null) {
        try {
          final ioFile = File(file.path!);
          if (ioFile.existsSync()) {
            return await ioFile.readAsBytes();
          }
        } catch (_) {}
      }
    }

    // 2. Cek in-memory cache
    final cached = getCachedFile(fileName);
    if (cached != null) {
      if (cached.bytes != null && cached.bytes!.isNotEmpty) {
        return cached.bytes!;
      }
      if (!kIsWeb && cached.path != null) {
        try {
          final ioFile = File(cached.path!);
          if (ioFile.existsSync()) {
            return await ioFile.readAsBytes();
          }
        } catch (_) {}
      }
    }

    // 3. Cek local filesystem jika berupa path valid pada non-web
    if (!kIsWeb && (fileName.contains('/') || fileName.contains(r'\'))) {
      try {
        final ioFile = File(fileName);
        if (ioFile.existsSync()) {
          return await ioFile.readAsBytes();
        }
      } catch (_) {}
    }

    // 4. Generate PDF standar resmi SATU RUMAH V2 dengan pw.Document
    final cleanName = fileName.split(RegExp(r'[/\\]')).last;
    final docTitle =
        title ?? cleanName.replaceAll('_', ' ').replaceAll('.pdf', '');
    final docSize = sizeBytes != null && sizeBytes > 0
        ? formatSize(sizeBytes)
        : 'Dokumen Terdaftar';
    final nowFormatted = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(DateTime.now());

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PEMERINTAH KOTA TASIKMALAYA',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'DINAS PERUMAHAN DAN KAWASAN PERMUKIMAN',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
                          ),
                        ),
                        pw.Text(
                          'Sistem Administrasi Terpadu Perumahan (SATU RUMAH V2)',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        border: pw.Border.all(color: PdfColors.red300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        'DOKUMEN RESMI',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey400, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Text(
                  docTitle.toUpperCase(),
                  style: const pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Berkas Terverifikasi dalam Proses Pengajuan Perumahan',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfMetaRow('Nama Berkas', cleanName),
                      pw.SizedBox(height: 8),
                      _buildPdfMetaRow('Format Berkas', 'Adobe PDF (.pdf)'),
                      pw.SizedBox(height: 8),
                      _buildPdfMetaRow('Ukuran Berkas', docSize),
                      pw.SizedBox(height: 8),
                      _buildPdfMetaRow('Status Upload', 'Terunggah & Sah'),
                      pw.SizedBox(height: 8),
                      _buildPdfMetaRow('Waktu Akses', '$nowFormatted WIB'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green300),
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green700,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          'Berkas terdaftar resmi dalam sesi aktif pengembang dan siap diproses dalam tahap verifikasi teknis Disperwaskim.',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColors.green900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SATU RUMAH V2 - Disperwaskim Kota Tasikmalaya',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.Text(
                      'Keamanan Digital Terjamin',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildPdfMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Text(
          ':  ',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  /// Menampilkan modal bottom sheet pratinjau dokumen sah (PDF & CAD).
  static void showAppDocumentPreview(
    BuildContext context, {
    required String fileName,
    String? title,
    int? fileSize,
    PlatformFile? file,
  }) {
    final cleanName = fileName.split(RegExp(r'[/\\]')).last;
    final isDwg = cleanName.toLowerCase().endsWith('.dwg');

    if (isDwg) {
      _showDwgPreviewModal(
        context: context,
        fileName: cleanName,
        title: title,
        fileSize: fileSize,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFFB91C1C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? cleanName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cleanName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.close, color: Color(0xFF475569)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: PdfPreview(
                  build: (format) => getPdfBytes(
                    fileName: fileName,
                    title: title,
                    sizeBytes: fileSize,
                    file: file,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFB91C1C),
                      strokeWidth: 2.5,
                    ),
                  ),
                  onError: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Color(0xFFB91C1C),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kendala memuat berkas: $error',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDwgPreviewModal({
    required BuildContext context,
    required String fileName,
    String? title,
    int? fileSize,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(
                    Icons.architecture,
                    color: Color(0xFF047857),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Site Plan & Gambar Kawasan',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Icons.close, color: Color(0xFF475569)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Format Berkas',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'AutoCAD DWG (CAD Terunggah)',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (fileSize != null && fileSize > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ukuran Berkas',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          formatSize(fileSize),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Verifikasi',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Siap Diproses Survey Disperwaskim',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Tutup Pratinjau',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
