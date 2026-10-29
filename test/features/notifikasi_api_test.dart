import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/auth/token_store.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/data/notifikasi_api_repository.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';

import '../support/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late NotifikasiApiRepository repo;

  setUp(() {
    adapter = FakeHttpAdapter();
    final dio = buildApiDio(
      baseUrl: 'http://uji.test/api/v1/',
      tokenStore: MemoryTokenStore('tok'),
      onUnauthorized: () {},
    )..httpClientAdapter = adapter;
    repo = NotifikasiApiRepository(dio);
  });

  Map<String, dynamic> row(int id, String type, {bool read = false}) => {
    'id': id,
    'type': type,
    'title': 'Judul $id',
    'body': 'Isi $id',
    'submission_number': 'SR-2026-0001',
    'read': read,
    'created_at': '2026-10-26T09:30:00+07:00',
  };

  test('memetakan notifikasi server untuk Pengembang', () async {
    adapter.reply(200, {
      'data': [row(1, 'revision_requested'), row(2, 'decided', read: true)],
      'meta': {'unread_count': 1},
    });

    final list = await repo.list(AppRole.developer);

    expect(list.first.id, 'srv-1');
    expect(list.first.jenis, JenisNotifikasi.perluRevisi);
    expect(list.first.pengajuanId, 'SR-2026-0001');
    expect(list.first.targetRoute, '/pengajuan/detail/SR-2026-0001');
    expect(list.first.untukRole(AppRole.developer), isTrue);
    expect(list.last.isRead, isTrue);
  });

  test(
    'refresh mempertahankan notifikasi lokal dan menandai dibaca ke server',
    () async {
      adapter.reply(200, {
        'data': [row(1, 'assignment')],
        'meta': {},
      });
      final notifier = NotifikasiNotifier(
        remote: repo,
        role: AppRole.perwaskim,
      );
      notifier.addNotification(
        NotifikasiModel(
          id: 'n-lokal',
          jenis: JenisNotifikasi.pengajuanBaru,
          judul: 'L',
          deskripsi: 'L',
          waktu: DateTime(2026),
        ),
      );

      await notifier.refresh();

      expect(notifier.state.map((e) => e.id), ['srv-1', 'n-lokal']);
      expect(notifier.state.first.jenis, JenisNotifikasi.penugasanSurvei);

      adapter.reply(200, {'message': 'ok'});
      notifier.markAsRead('srv-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.first.isRead, isTrue);
      expect(adapter.requests.last.path, endsWith('notifications/1/read'));
    },
  );

  test('memetakan seluruh tipe notifikasi backend dan mempertahankan data payload', () async {
    adapter.reply(200, {
      'data': [
        {
          'id': 10,
          'type': 'assignment',
          'title': 'Penugasan Survei Lapangan',
          'body': 'Tugas baru',
          'submission_number': 'SR-001',
          'data': {'assignment_id': 99, 'report_id': 88},
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 11,
          'type': 'survey_scheduled',
          'title': 'Jadwal Survei Lapangan',
          'body': 'Survei dijadwalkan',
          'submission_number': 'SR-002',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 12,
          'type': 'survey_cancelled',
          'title': 'Jadwal Survei Dibatalkan',
          'body': 'Batal',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 13,
          'type': 'assignment_cancelled',
          'title': 'Penugasan Dibatalkan',
          'body': 'Penugasan dicabut',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 14,
          'type': 'report_published',
          'title': 'Berita Acara Diterbitkan',
          'body': 'BA siap diunduh',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 15,
          'type': 'stage_advanced',
          'title': 'Tahap Pengajuan Lanjut',
          'body': 'Lanjut',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 16,
          'type': 'decided',
          'title': 'Pengajuan Disetujui',
          'body': 'Selamat',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
        {
          'id': 17,
          'type': 'decided',
          'title': 'Pengajuan Ditolak',
          'body': 'Mohon maaf',
          'read': false,
          'created_at': '2026-10-26T09:30:00+07:00',
        },
      ],
      'meta': {},
    });

    final list = await repo.list(AppRole.perwaskim);
    expect(list.length, 8);
    expect(list[0].jenis, JenisNotifikasi.penugasanSurvei);
    expect(list[0].assignmentId, 99);
    expect(list[0].reportId, 88);
    expect(list[0].targetRoute, '/monitoring/lapangan');

    expect(list[1].jenis, JenisNotifikasi.reminderSurvey);
    expect(list[2].jenis, JenisNotifikasi.jadwalDibatalkan);
    expect(list[3].jenis, JenisNotifikasi.penugasanDibatalkan);
    expect(list[4].jenis, JenisNotifikasi.baDiterbitkan);
    expect(list[5].jenis, JenisNotifikasi.tahapLanjut);
    expect(list[6].jenis, JenisNotifikasi.keputusanDisetujui);
    expect(list[7].jenis, JenisNotifikasi.keputusanDitolak);
  });

  test('addNotification menduplikasi pencegahan ID yang sama', () {
    final notifier = NotifikasiNotifier();
    final notif1 = NotifikasiModel(
      id: 'duplikat-1',
      jenis: JenisNotifikasi.pengajuanBaru,
      judul: 'Awal',
      deskripsi: 'Awal',
      waktu: DateTime(2026),
    );
    final notif2 = NotifikasiModel(
      id: 'duplikat-1',
      jenis: JenisNotifikasi.pengajuanBaru,
      judul: 'Update',
      deskripsi: 'Update',
      waktu: DateTime(2026),
    );

    notifier.addNotification(notif1);
    expect(notifier.state.where((e) => e.id == 'duplikat-1').length, 1);
    expect(notifier.state.first.judul, 'Awal');

    notifier.addNotification(notif2);
    expect(notifier.state.where((e) => e.id == 'duplikat-1').length, 1);
    expect(notifier.state.first.judul, 'Update');
  });

  test('jaringan gagal tidak menghapus daftar yang ada', () async {
    final notifier = NotifikasiNotifier(remote: repo, role: AppRole.developer);
    notifier.addNotification(
      NotifikasiModel(
        id: 'n-1',
        jenis: JenisNotifikasi.pengajuanBaru,
        judul: 'A',
        deskripsi: 'A',
        waktu: DateTime(2026),
      ),
    );
    await notifier.refresh(); // tanpa jawaban terantri -> galat
    expect(notifier.state, hasLength(1));
  });
}
