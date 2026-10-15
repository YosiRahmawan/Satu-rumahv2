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
  static const String jawabanDokumenWajib =
      'Formulir meminta 5 berkas perusahaan, 10 berkas perumahan wajib, dan '
      'minimal satu gambar teknis site plan. Berkas PDF maksimal 10 MB, gambar '
      'teknis DWG atau PDF maksimal 50 MB. Ketentuan resmi mengikuti '
      'Disperwaskim.';

  /// Jawaban untuk: "Apa yang harus dilakukan jika berkas diminta diperbaiki?"
  static const String jawabanPerbaikanBerkas =
      'Buka pengajuannya, baca catatan perbaikan, lalu tekan Perbaiki Berkas. '
      'Ganti hanya dokumen yang diminta, lalu kirim. Selama menunggu '
      'pemeriksaan, berkas tidak bisa diubah lagi.';

  /// Jawaban untuk: "Bagaimana jadwal survei lapangan ditentukan?"
  static const String jawabanJadwalSurvei =
      'Admin Disperwaskim menentukan tanggal dan petugas setelah berkas lolos '
      'pemeriksaan. Jadwalnya tampil di menu Jadwal Survey. Aturan penentuan '
      'jadwal ditetapkan Disperwaskim.';
}
