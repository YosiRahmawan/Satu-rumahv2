import 'package:dio/dio.dart';
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
      expect(notifier.state.first.jenis, JenisNotifikasi.reminderSurvey);

      adapter.reply(200, {'message': 'ok'});
      notifier.markAsRead('srv-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.first.isRead, isTrue);
      expect(adapter.requests.last.path, endsWith('notifications/1/read'));
    },
  );

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
