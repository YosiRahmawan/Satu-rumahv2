import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

/// Mengapa kamera tidak bisa dipakai.
enum CameraFailure { denied, notFound, failed }

class CameraUnavailable implements Exception {
  final CameraFailure failure;

  /// Kode/pesan asli dari platform, untuk membantu mencari penyebab.
  final String? detail;
  const CameraUnavailable(this.failure, [this.detail]);

  @override
  String toString() => 'CameraUnavailable($failure)';
}

/// Satu sesi kamera yang sedang terbuka.
abstract class CameraSession {
  /// Tampilan pratinjau langsung dari kamera.
  Widget buildPreview();

  /// Rasio lebar/tinggi pratinjau dalam orientasi potret.
  double get aspectRatio;

  /// Memotret dan mengembalikan berkas JPEG mentah (belum berwatermark).
  Future<Uint8List> capture();

  /// Menyalakan/mematikan flash untuk pemotretan berikutnya. Mengembalikan
  /// false bila perangkat tidak mendukung.
  Future<bool> setFlash(bool on);

  Future<void> dispose();
}

/// Pintu masuk ke kamera perangkat. Dipisahkan agar layar kamera dapat diuji
/// tanpa perangkat keras.
abstract class CameraGateway {
  /// Membuka kamera belakang. Melempar [CameraUnavailable] bila gagal.
  Future<CameraSession> open();
}

class DeviceCameraGateway implements CameraGateway {
  const DeviceCameraGateway();

  @override
  Future<CameraSession> open() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw CameraUnavailable(_failureOf(e), '${e.code}: ${e.description}');
    }
    if (cameras.isEmpty) throw const CameraUnavailable(CameraFailure.notFound);
    final description = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      throw CameraUnavailable(_failureOf(e), '${e.code}: ${e.description}');
    }
    return _DeviceCameraSession(controller);
  }

  static CameraFailure _failureOf(CameraException e) {
    final code = e.code.toLowerCase();
    if (code.contains('access') || code.contains('permission')) {
      return CameraFailure.denied;
    }
    return CameraFailure.failed;
  }
}

class _DeviceCameraSession implements CameraSession {
  final CameraController _controller;
  _DeviceCameraSession(this._controller);

  @override
  Widget buildPreview() => CameraPreview(_controller);

  @override
  double get aspectRatio {
    final ratio = _controller.value.aspectRatio;
    // `aspectRatio` controller berorientasi lanskap; pratinjau potret = 1/ratio.
    return ratio > 1 ? 1 / ratio : ratio;
  }

  @override
  Future<Uint8List> capture() async {
    final file = await _controller.takePicture();
    return file.readAsBytes();
  }

  @override
  Future<bool> setFlash(bool on) async {
    try {
      await _controller.setFlashMode(on ? FlashMode.always : FlashMode.off);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() => _controller.dispose();
}
