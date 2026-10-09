// ponytail: minimal wrapper over file_picker package for native Android file selection
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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

class FilePickerUtil {
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
      return FilePickResult.selected(result.files.first);
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
}
