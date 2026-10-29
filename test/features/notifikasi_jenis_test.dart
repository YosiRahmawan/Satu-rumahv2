import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/data/notifikasi_api_repository.dart';

void main() {
  test('setiap jenis dari server dipetakan ke jenis tampilan yang sesuai', () {
    const peta = {
      'revision_requested': JenisNotifikasi.perluRevisi,
      'assignment': JenisNotifikasi.penugasanSurvei,
      'assignment_rescheduled': JenisNotifikasi.reminderSurvey,
      'survey_scheduled': JenisNotifikasi.reminderSurvey,
      'resubmitted': JenisNotifikasi.dokumenDiunggahUlang,
      'report_submitted': JenisNotifikasi.dokumenDiunggahUlang,
      'stage_advanced': JenisNotifikasi.tahapLanjut,
      'survey_cancelled': JenisNotifikasi.jadwalDibatalkan,
      'assignment_cancelled': JenisNotifikasi.penugasanDibatalkan,
      'assignment_reassigned': JenisNotifikasi.penugasanDibatalkan,
      'report_published': JenisNotifikasi.baDiterbitkan,
      'deadline_reminder': JenisNotifikasi.batasPerbaikan,
      'deadline_overdue': JenisNotifikasi.batasPerbaikan,
      'submitted': JenisNotifikasi.pengajuanBaru,
    };
    peta.forEach((type, jenis) {
      expect(jenisFromApi(type), jenis, reason: type);
    });
  });

  test('keputusan dibedakan antara disetujui dan ditolak lewat judul', () {
    expect(
      jenisFromApi('decided', 'Pengajuan disetujui'),
      JenisNotifikasi.keputusanDisetujui,
    );
    expect(
      jenisFromApi('decided', 'Pengajuan ditolak'),
      JenisNotifikasi.keputusanDitolak,
    );
    expect(
      jenisFromApi('decided', 'PENGAJUAN DITOLAK'),
      JenisNotifikasi.keputusanDitolak,
    );
    expect(jenisFromApi('decided'), JenisNotifikasi.keputusanDisetujui);
  });

  test(
    'jenis tak dikenal tetap aman dan tiap jenis punya label, ikon, dan warna',
    () {
      expect(
        jenisFromApi('jenis_baru_dari_server'),
        JenisNotifikasi.pengajuanBaru,
      );
      expect(jenisFromApi(null), JenisNotifikasi.pengajuanBaru);
      for (final j in JenisNotifikasi.values) {
        expect(j.label, isNotEmpty);
        expect(j.icon, isNotNull);
        expect(j.color, isNotNull);
      }
      // Ditolak tidak berlabel sama dengan pengajuan baru.
      expect(JenisNotifikasi.keputusanDitolak.label, 'Pengajuan Ditolak');
      expect(
        JenisNotifikasi.keputusanDitolak.label,
        isNot(JenisNotifikasi.pengajuanBaru.label),
      );
    },
  );
}
