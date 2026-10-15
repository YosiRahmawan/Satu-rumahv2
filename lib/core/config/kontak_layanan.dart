/// Nama instansi resmi yang digunakan pada antarmuka Pusat Bantuan.
const String namaInstansi = 'Disperwaskim';

/// Konfigurasi dan nilai konstanta kontak layanan & pertanyaan umum Pusat Bantuan.
/// Seluruh nilai awal bernilai null dan akan diisi setelah divalidasi resmi
/// oleh pihak Disperwaskim.
class KontakLayanan {
  const KontakLayanan._();

  static const String instansi = namaInstansi;

  // ─── Bagian 1: Kontak Layanan ─────────────────────────────────────────────
  /// Nomor telepon dinas (contoh format: '0265123456' untuk tel:0265123456).
  static const String? nomorTelepon = null;

  /// Nomor WhatsApp resmi (contoh format: '6281234567890' untuk https://wa.me/6281234567890).
  static const String? nomorWhatsApp = null;

  /// Alamat email layanan resmi (contoh format: 'layanan@disperwaskim.go.id' untuk mailto:...).
  static const String? email = null;

  /// Jam layanan operasional kedinasan (contoh: 'Senin - Jumat, 08.00 - 15.30 WIB').
  static const String? jamLayanan = null;

  // ─── Bagian 3: Pertanyaan Umum (FAQ) ──────────────────────────────────────
  /// Jawaban untuk: "Dokumen apa saja yang wajib diunggah?"
  static const String? jawabanDokumenWajib = null;

  /// Jawaban untuk: "Apa yang harus dilakukan jika berkas diminta diperbaiki?"
  static const String? jawabanPerbaikanBerkas = null;

  /// Jawaban untuk: "Bagaimana jadwal survei lapangan ditentukan?"
  static const String? jawabanJadwalSurvei = null;
}
