import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../data/models/geo_stamp.dart';
import '../utils/geo_stamp_signer.dart';

/// Ukuran maksimum satu foto yang diimpor dari galeri.
const int kMaxImportBytes = 10 * 1024 * 1024;

class PickedPhotoFile {
  final String name;
  final Uint8List bytes;
  const PickedPhotoFile(this.name, this.bytes);
}

/// Pemilih foto dari galeri. Dapat diganti pada tes.
abstract class PhotoPickerGateway {
  /// Daftar foto terpilih; kosong bila pemilih dibatalkan.
  Future<List<PickedPhotoFile>> pickImages();
}

class FilePhotoPickerGateway implements PhotoPickerGateway {
  const FilePhotoPickerGateway();

  @override
  Future<List<PickedPhotoFile>> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return const [];
    return [
      for (final file in result.files)
        if (file.bytes != null) PickedPhotoFile(file.name, file.bytes!),
    ];
  }
}

/// Hasil memeriksa satu foto galeri: [stamp] bila sah, [error] bila ditolak.
class PhotoImportResult {
  final String name;
  final GeoStamp? stamp;
  final String? error;

  const PhotoImportResult.accepted(this.name, GeoStamp this.stamp)
    : error = null;
  const PhotoImportResult.rejected(this.name, String this.error)
    : stamp = null;

  bool get isAccepted => stamp != null;
}

/// Foto galeri hanya diterima bila memuat tanda geotag Satu Rumah yang sah.
PhotoImportResult verifyGalleryPhoto(String name, Uint8List bytes) {
  if (bytes.length > kMaxImportBytes) {
    return PhotoImportResult.rejected(name, 'Ukuran melebihi 10 MB.');
  }
  final check = GeoStampSigner.verify(bytes);
  final stamp = check.stamp;
  if (stamp != null) return PhotoImportResult.accepted(name, stamp);
  return PhotoImportResult.rejected(name, switch (check.failure) {
    GeoStampFailure.notJpeg =>
      'Bukan berkas JPEG. Hanya foto bergeotag dari kamera aplikasi yang diterima.',
    GeoStampFailure.tampered =>
      'Foto diubah setelah diberi geotag, jadi tidak diterima.',
    _ =>
      'Tidak ada geotag Satu Rumah pada foto ini. Ambil fotonya lewat kamera aplikasi.',
  });
}
