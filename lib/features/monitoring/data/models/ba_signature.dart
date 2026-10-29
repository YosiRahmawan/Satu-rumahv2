/// Status persetujuan elektronik BA dari server (Ketua Pengawas lalu Admin).
/// Bukan tanda tangan elektronik tersertifikasi: hanya persetujuan berbasis akun.
class BaSignatureStatus {
  const BaSignatureStatus({
    this.ketuaSigned = false,
    this.adminSigned = false,
    this.ketuaAt,
    this.published = false,
    this.version,
  });

  final bool ketuaSigned;
  final bool adminSigned;
  final DateTime? ketuaAt;

  /// BA sudah diterbitkan Admin (setelah kedua persetujuan terpenuhi).
  final bool published;

  /// Versi BA di server yang disetujui; dipakai untuk mencegah menyetujui isi yang sudah berubah.
  final int? version;

  /// Dari detail laporan `officer/reports/{id}`.
  factory BaSignatureStatus.fromReport(Map<String, dynamic> json) {
    final sig =
        (json['signatures'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ketua = (sig['ketua'] as Map?)?.cast<String, dynamic>() ?? const {};
    final admin = (sig['admin'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BaSignatureStatus(
      ketuaSigned: ketua['signed'] == true,
      adminSigned: admin['signed'] == true,
      ketuaAt: DateTime.tryParse('${ketua['signed_at'] ?? ''}')?.toLocal(),
      published: json['published_at'] != null,
      version: (json['version'] as num?)?.toInt(),
    );
  }
}

/// Gambar tanda tangan siap kirim: PNG dari kanvas atau berkas yang dipilih.
class SignatureImage {
  const SignatureImage({
    required this.bytes,
    required this.method,
    this.filename = 'ttd.png',
    this.contentType = 'image/png',
  });

  final List<int> bytes;

  /// `draw` (gambar langsung) atau `upload` (unggah gambar).
  final String method;
  final String filename;
  final String contentType;
}
