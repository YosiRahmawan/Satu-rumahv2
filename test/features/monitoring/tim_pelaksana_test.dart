import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_beranda_monitoring.dart';

void main() {
  final json = {
    'id': 7,
    'status': 'dijadwalkan',
    'scheduled_date': '2026-11-02',
    'submission': {
      'number': 'SR-2026-0001',
      'nama_perumahan': 'Griya',
      'nama_pt': 'PT Uji',
    },
    'team': [
      {'nama': 'Ketua Satu', 'jabatan': 'Ketua Tim'},
      {'nama': 'Anggota Dua', 'jabatan': 'Staf'},
    ],
  };

  test('tugas membawa tim dari Admin', () {
    final a = OfficerAssignment.fromJson(json);
    expect(a.team.map((p) => p.nama), ['Ketua Satu', 'Anggota Dua']);
    expect(a.team.first.jabatan, 'Ketua Tim');
  });

  test('tim tugas dipakai mengisi form (nama pertama = ketua)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(monitoringFormProvider.notifier);
    n.setTimPelaksana(OfficerAssignment.fromJson(json).team);
    final s = c.read(monitoringFormProvider);
    expect(s.pelaksana.map((p) => p.nama), ['Ketua Satu', 'Anggota Dua']);
    expect(s.pelaksanaNama, 'Ketua Satu');
    expect(s.pelaksanaJabatan, 'Ketua Tim');
  });

  test('assignmentTeamProvider: null di mode contoh', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(assignmentTeamProvider('SR-2026-0001')), isNull);
  });

  test(
    'identitas petugas memakai nama asli dari server, bukan tebakan username',
    () {
      final id = PerwaskimIdentity.fromSession(
        const RoleSessionState(
          role: AppRole.perwaskim,
          username: 'tim_lapangan',
          nama: 'Petugas Lapangan Contoh',
          jabatan: 'Tim Perwaskim',
        ),
      );
      expect(id.nama, 'Petugas Lapangan Contoh');
      expect(id.jabatan, 'Tim Perwaskim');
      expect(id.initials, 'PC');
    },
  );

  test(
    'Pengawas menerima data proyek dan kontak pengembang dari pengajuan',
    () {
      final a = OfficerAssignment.fromJson({
        ...json,
        'submission': {
          'number': 'SR-2026-0001',
          'nama_perumahan': 'Griya',
          'nama_direktur': 'Pak Direktur',
          'no_hp_direktur': '0812345',
          'jumlah_unit': 40,
          'luas_lahan': 1500,
          'tipe_perumahan': 'komersil',
        },
      });
      final p = a.asPengajuan();
      expect(p.namaDirektur, 'Pak Direktur');
      expect(p.jumlahUnit, 40);
      expect(p.luasLahan, 1500);
      expect(p.tipePerumahan, 'Komersil');
    },
  );

  test('Pengembang melihat jadwal survei, tim, dan hasil BA dari server', () {
    final p = pengajuanFromApi({
      'id': 5,
      'number': 'SR-2026-0001',
      'status_tahap': 'surveyLapangan',
      'nama_perumahan': 'Griya',
      'survey': {
        'scheduled_date': '2026-11-02',
        'note': null,
        'team': [
          {'nama': 'Ketua Satu', 'jabatan': 'Ketua Tim'},
          {'nama': 'Anggota Dua', 'jabatan': 'Staf'},
        ],
      },
      'survey_reports': [
        {
          'id': 9,
          'report_number': '600.2.5/BA-MON/X/2026/001',
          'monitoring_date': '2026-11-02',
          'status_hasil_evaluasi': 'tidakSesuaiSiteplan',
          'temuan': ['Drainase belum selesai'],
          'rtl': ['Perbaiki drainase'],
          'tim_pelaksana': [
            {'nama': 'Ketua Satu', 'jabatan': 'Ketua Tim'},
          ],
        },
      ],
    });
    expect(p.tanggalSurvey, DateTime(2026, 11, 2));
    expect(p.catatanSurvey, 'Tim: Ketua Satu, Anggota Dua');
    final h = p.riwayatSurvey.single;
    expect(h.statusHasilEvaluasi, 'tidak_sesuai');
    expect(h.nomorSuratBA, '600.2.5/BA-MON/X/2026/001');
    expect(h.temuanLapangan, ['Drainase belum selesai']);
    expect(h.rencanaTindakLanjut, ['Perbaiki drainase']);
    expect(h.pelaksanaNama, 'Ketua Satu');
  });
}
