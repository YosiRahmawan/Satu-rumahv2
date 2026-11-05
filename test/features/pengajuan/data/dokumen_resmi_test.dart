import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/token_store.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/presentation/dokumen_resmi.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _pengajuan({bool terbit = true, bool sk = true}) => {
  'id': 5,
  'number': 'SR-2026-0001',
  'stage': 6,
  'sub_status': 'selesai',
  'status_tahap': 'selesai',
  'version': 4,
  'nama_perumahan': 'Griya Uji',
  'nama_pt': 'PT Uji',
  'npwp': '01.234',
  'luas_lahan': 1200,
  'jumlah_unit': 40,
  'tipe_perumahan': 'subsidi',
  'submitted_at': '2026-10-26T09:30:00+07:00',
  'updated_at': '2026-10-26T09:30:00+07:00',
  'developer_profile': {'nama_pt': 'PT Uji', 'nama_direktur': 'D', 'nib': '1'},
  'files': const [],
  'decision': {'number': 'SK-1/2026', 'date': '2026-11-10', 'sk_available': sk},
  'survey_reports': [
    {
      'id': 9,
      'report_number': '600.2.5/BA-MON/XI/2026/001',
      'monitoring_date': '2026-11-05',
      'pdf_available': terbit,
      'published_at': terbit ? '2026-11-05T10:00:00+07:00' : null,
    },
  ],
};

void main() {
  late FakeHttpAdapter adapter;

  PengajuanApiRepository build() {
    adapter = FakeHttpAdapter();
    final dio = buildApiDio(
      baseUrl: 'http://uji.test/api/v1/',
      tokenStore: MemoryTokenStore('tok'),
      onUnauthorized: () {},
    )..httpClientAdapter = adapter;
    return PengajuanApiRepository(dio, readBytes: (ref) async => Uint8List(0));
  }

  test(
    'pengajuan dari server memuat BA resmi yang terbit dan ketersediaan SK',
    () {
      final p = pengajuanFromApi(_pengajuan());
      expect(p.serverBaReportId, 9);
      expect(p.serverBaNomor, '600.2.5/BA-MON/XI/2026/001');
      expect(p.serverSkTersedia, isTrue);
      expect(
        baResmiSebagaiModel(p)?.nomorSuratBA,
        '600.2.5/BA-MON/XI/2026/001',
      );
      // Tetap ada setelah copyWith (dipakai saat daftar diperbarui di aplikasi).
      expect(p.copyWith(namaPerumahan: 'Baru').serverBaReportId, 9);

      final belum = pengajuanFromApi(_pengajuan(terbit: false, sk: false));
      expect(belum.serverBaReportId, isNull);
      expect(belum.serverSkTersedia, isFalse);
      expect(baResmiSebagaiModel(belum), isNull);
    },
  );

  test(
    'unduh BA resmi dan SK memakai alamat server untuk pengajuan bernomor itu',
    () async {
      final repo = build();
      adapter.reply(200, {
        'data': [_pengajuan()],
      }); // daftar untuk memetakan nomor ke id
      adapter.reply(200, {'data': []});
      // Jawaban berkas dibaca sebagai teks oleh adapter palsu; yang diuji alamat dan metodenya.
      try {
        await repo.downloadBaPdf('SR-2026-0001', 9);
      } catch (_) {}
      expect(adapter.requests.last.path, 'submissions/5/reports/9/pdf');
      expect(adapter.requests.last.method, 'GET');
    },
  );

  test('404 pada dokumen menjadi pesan yang jelas', () async {
    final repo = build();
    adapter.reply(200, {
      'data': [_pengajuan()],
    });
    adapter.reply(404, {
      'error': {'code': 'ERR-013', 'message': 'x'},
    });

    await expectLater(
      repo.downloadSk('SR-2026-0001'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'pesan',
          contains('belum tersedia'),
        ),
      ),
    );
  });
}
