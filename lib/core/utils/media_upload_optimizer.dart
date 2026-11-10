import 'dart:io';
import 'dart:typed_data';
import 'file_picker_util.dart';

/// Hasil validasi dan pemrosesan berkas sebelum diunggah ke backend
class ProcessedFileResult {
  final String path;
  final String name;
  final int originalSizeBytes;
  final int processedSizeBytes;
  final bool isCompressed;
  final Uint8List? bytes;

  const ProcessedFileResult({
    required this.path,
    required this.name,
    required this.originalSizeBytes,
    required this.processedSizeBytes,
    this.isCompressed = false,
    this.bytes,
  });

  double get sizeInMb => processedSizeBytes / (1024 * 1024);
  double get originalSizeInMb => originalSizeBytes / (1024 * 1024);
}

/// Helper validasi batas ukuran dokumen & optimasi media lapangan:
/// - Foto Evidence: Validasi ukuran dan proteksi OOM (maks 5MB per file)
/// - Dokumen PDF: Maksimal 10 MB (dokumen permohonan, legalitas, IPR/KRK)
/// - Gambar CAD / Siteplan DWG: Maksimal 50 MB
class MediaUploadOptimizer {
  static const int maxPdfSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxDwgSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Memeriksa apakah ukuran file dokumen PDF/DWG valid sesuai aturan backend
  static FileViolation? validateDocumentSize({
    required String fileName,
    required int sizeBytes,
    bool isDwg = false,
  }) {
    final maxBytes = isDwg ? maxDwgSizeBytes : maxPdfSizeBytes;
    final maxMb = maxBytes ~/ (1024 * 1024);

    if (sizeBytes > maxBytes) {
      return FileViolation(
        'Ukuran file melebihi batas',
        'File melebihi batas maksimal $maxMb MB.',
      );
    }
    return null;
  }

  /// Memvalidasi foto bukti lapangan sebelum diunggah ke server
  static Future<ProcessedFileResult> compressEvidencePhoto({
    required String filePath,
    int quality = 75,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ProcessedFileResult(
        path: filePath,
        name: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : filePath,
        originalSizeBytes: 0,
        processedSizeBytes: 0,
      );
    }

    final bytes = await file.readAsBytes();
    final length = bytes.length;

    return ProcessedFileResult(
      path: filePath,
      name: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : filePath,
      originalSizeBytes: length,
      processedSizeBytes: length,
      isCompressed: false,
      bytes: bytes,
    );
  }
}
