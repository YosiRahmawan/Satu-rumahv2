import 'package:flutter/material.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';

enum JenisNotifikasi {
  pengajuanBaru,
  dokumenDiunggahUlang,
  reminderSurvey,
  deadlineVerifikasi,

  /// Verifikator meminta Pengembang memperbaiki berkas. Berbeda dari
  /// [dokumenDiunggahUlang], yang dipakai untuk kabar unggahan berkas
  /// (revisi Pengembang atau berita acara survey) kepada Admin.
  perluRevisi,

  /// Tahap verifikasi atau alur pengajuan maju ke tahap berikutnya.
  tahapLanjut,

  /// Tugas survei baru diterbitkan untuk Petugas Lapangan.
  penugasanSurvei,

  /// Jadwal survei dibatalkan oleh Admin.
  jadwalDibatalkan,

  /// Tugas survei dibatalkan untuk Petugas Lapangan.
  penugasanDibatalkan,

  /// Berita Acara survei resmi diterbitkan oleh Admin.
  baDiterbitkan,

  /// Keputusan akhir pengajuan disetujui.
  keputusanDisetujui,

  /// Keputusan akhir pengajuan ditolak.
  keputusanDitolak,

  /// Pengingat batas waktu perbaikan berkas oleh Pengembang (mendekat atau terlewat).
  batasPerbaikan,
}

extension JenisNotifikasiX on JenisNotifikasi {
  String get label {
    switch (this) {
      case JenisNotifikasi.pengajuanBaru:
        return 'Pengajuan Baru';
      case JenisNotifikasi.dokumenDiunggahUlang:
        return 'Perbaikan Dokumen';
      case JenisNotifikasi.reminderSurvey:
        return 'Reminder Survey';
      case JenisNotifikasi.deadlineVerifikasi:
        return 'Deadline Verifikasi';
      case JenisNotifikasi.perluRevisi:
        return 'Perlu Revisi';
      case JenisNotifikasi.tahapLanjut:
        return 'Tahap Lanjutan';
      case JenisNotifikasi.penugasanSurvei:
        return 'Tugas Survei';
      case JenisNotifikasi.jadwalDibatalkan:
        return 'Survei Dibatalkan';
      case JenisNotifikasi.penugasanDibatalkan:
        return 'Tugas Dibatalkan';
      case JenisNotifikasi.baDiterbitkan:
        return 'BA Diterbitkan';
      case JenisNotifikasi.keputusanDisetujui:
        return 'Pengajuan Disetujui';
      case JenisNotifikasi.keputusanDitolak:
        return 'Pengajuan Ditolak';
      case JenisNotifikasi.batasPerbaikan:
        return 'Batas Perbaikan';
    }
  }

  IconData get icon {
    switch (this) {
      case JenisNotifikasi.pengajuanBaru:
        return Icons.note_add_outlined;
      case JenisNotifikasi.dokumenDiunggahUlang:
        return Icons.replay_outlined;
      case JenisNotifikasi.reminderSurvey:
        return Icons.event_available_outlined;
      case JenisNotifikasi.deadlineVerifikasi:
        return Icons.timer_outlined;
      case JenisNotifikasi.perluRevisi:
        return Icons.sync_problem_outlined;
      case JenisNotifikasi.tahapLanjut:
        return Icons.trending_up_rounded;
      case JenisNotifikasi.penugasanSurvei:
        return Icons.assignment_outlined;
      case JenisNotifikasi.jadwalDibatalkan:
        return Icons.event_busy_outlined;
      case JenisNotifikasi.penugasanDibatalkan:
        return Icons.cancel_outlined;
      case JenisNotifikasi.baDiterbitkan:
        return Icons.verified_rounded;
      case JenisNotifikasi.keputusanDisetujui:
        return Icons.check_circle_outline_rounded;
      case JenisNotifikasi.keputusanDitolak:
        return Icons.highlight_off_rounded;
      case JenisNotifikasi.batasPerbaikan:
        return Icons.hourglass_bottom_outlined;
    }
  }

  Color get color {
    switch (this) {
      case JenisNotifikasi.pengajuanBaru:
        return AppColors.info;
      case JenisNotifikasi.dokumenDiunggahUlang:
        return const Color(0xFFE65100);
      case JenisNotifikasi.reminderSurvey:
        return const Color(0xFF2E7D32);
      case JenisNotifikasi.deadlineVerifikasi:
        return AppColors.primaryRed;
      case JenisNotifikasi.perluRevisi:
        return const Color(0xFFE65100);
      case JenisNotifikasi.tahapLanjut:
        return const Color(0xFF0284C7);
      case JenisNotifikasi.penugasanSurvei:
        return const Color(0xFF0D9488);
      case JenisNotifikasi.jadwalDibatalkan:
      case JenisNotifikasi.penugasanDibatalkan:
      case JenisNotifikasi.keputusanDitolak:
        return AppColors.primaryRed;
      case JenisNotifikasi.baDiterbitkan:
      case JenisNotifikasi.keputusanDisetujui:
        return const Color(0xFF16A34A);
      case JenisNotifikasi.batasPerbaikan:
        return const Color(0xFFE65100);
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }
}

class NotifikasiModel {
  final String id;
  final JenisNotifikasi jenis;
  final String judul;
  final String deskripsi;
  final DateTime waktu;
  final bool isRead;
  final String? targetRoute;

  /// Pengajuan yang dirujuk, bila ada. Sumber relasi utama; jangan menebak id
  /// dari teks deskripsi.
  final String? pengajuanId;

  /// Role penerima. Null = penerima belum jelas (data lama): tidak pernah
  /// dianggap milik Pengembang. Status baca masih satu untuk semua akun
  /// (design.md Q10).
  final AppRole? penerima;

  /// Data contoh lokal, bukan hasil alur kerja nyata.
  final bool isSimulasi;

  /// Payload metadata tambahan dari backend (misal: assignment_id, report_id).
  final Map<String, dynamic>? data;

  NotifikasiModel({
    required this.id,
    required this.jenis,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    this.isRead = false,
    this.targetRoute,
    this.pengajuanId,
    this.penerima,
    this.isSimulasi = false,
    this.data,
  });

  int? get assignmentId => (data?['assignment_id'] as num?)?.toInt();
  int? get reportId => (data?['report_id'] as num?)?.toInt();

  /// Apakah notifikasi ini boleh tampil untuk [role]. Pengembang hanya melihat
  /// yang ditujukan kepadanya; role lain tetap melihat yang tanpa penerima.
  bool untukRole(AppRole role) {
    if (role == AppRole.developer) return penerima == AppRole.developer;
    return penerima == null || penerima == role;
  }

  NotifikasiModel copyWith({
    String? id,
    JenisNotifikasi? jenis,
    String? judul,
    String? deskripsi,
    DateTime? waktu,
    bool? isRead,
    String? targetRoute,
    String? pengajuanId,
    AppRole? penerima,
    bool? isSimulasi,
    Map<String, dynamic>? data,
  }) {
    return NotifikasiModel(
      id: id ?? this.id,
      jenis: jenis ?? this.jenis,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      waktu: waktu ?? this.waktu,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute ?? this.targetRoute,
      pengajuanId: pengajuanId ?? this.pengajuanId,
      penerima: penerima ?? this.penerima,
      isSimulasi: isSimulasi ?? this.isSimulasi,
      data: data ?? this.data,
    );
  }
}
