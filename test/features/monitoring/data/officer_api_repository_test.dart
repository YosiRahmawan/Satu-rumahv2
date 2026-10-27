import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/token_store.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _assignment({
  int id = 3,
  String? number = 'SR-2026-0001',
}) => {
  'id': id,
  'status': 'dijadwalkan',
  'scheduled_date': '2026-11-02',
  'note': 'Bawa gambar',
  'submission': {
    'id': 9,
    'number': number,
    'nama_perumahan': 'Griya Mangkubumi',
    'nama_pt': 'PT Uji',
    'alamat_proyek': 'Jl. Karikil',
  },
};

Map<String, dynamic> _report({
  int version = 1,
  List<Map<String, dynamic>> photos = const [],
  String? number,
}) => {
  'id': 11,
  'status': number == null ? 'draft' : 'final',
  'version': version,
  'report_number': number,
  'photos': photos,
};

ReportPhoto _photo(String id, {PhotoSource source = PhotoSource.camera}) =>
    ReportPhoto(
      id: id,
      source: source,
      stamp: GeoStamp(
        latitude: -7.3,
        longitude: 108.2,
        capturedAt: DateTime.utc(2026, 10, 26),
      ),
    );

MonitoringModel _draft({
  List<ReportPhoto> photos = const [],
  String? pengajuanId = 'SR-2026-0001',
}) => MonitoringModel(
  id: 'draf-1',
  pengajuanId: pengajuanId,
  tanggalMonitoring: DateTime(2026, 10, 26),
  namaPerumahan: 'Griya Mangkubumi',
  lokasiPerumahan: 'Jl. Karikil',
  maksudTujuan: 'Memastikan kesesuaian.',
  temuanLapangan: const ['Jalan selesai', '  ', 'Drainase belum'],
  kesimpulan: const ['Sesuai'],
  rencanaTindakLanjut: const ['Perbaiki drainase'],
  statusHasilEvaluasi: StatusHasilEvaluasi.tidakSesuaiSiteplan,
  pelaksana: const [
    MonitoringPerson(nama: 'Rian', jabatan: 'Ketua'),
    MonitoringPerson(nama: ' '),
  ],
  ditemui: const [MonitoringPerson(nama: 'Asep', jabatan: 'Direktur')],
  photos: photos,
  isDraft: true,
);

void main() {
  late FakeHttpAdapter adapter;
  final bytes = <String, Uint8List>{};

  OfficerApiRepository build() {
    adapter = FakeHttpAdapter();
    final dio = buildApiDio(
      baseUrl: 'http://uji.test/api/v1/',
      tokenStore: MemoryTokenStore('tok'),
      onUnauthorized: () {},
    )..httpClientAdapter = adapter;
    return OfficerApiRepository(dio, photoBytes: (id) => bytes[id]);
  }

  setUp(() {
    bytes
      ..clear()
      ..['p1'] = Uint8List.fromList(List.filled(40, 1))
      ..['p2'] = Uint8List.fromList(List.filled(50, 2));
  });

  test(
    'tugas diparse dan dipetakan ke Pengajuan untuk layar yang ada',
    () async {
      final repo = build();
      adapter.reply(200, {
        'data': [_assignment()],
      });

      final list = await repo.assignments();

      expect(list.single.id, 3);
      expect(adapter.requests.single.path, 'officer/assignments');
      final p = list.single.asPengajuan();
      expect(p.id, 'SR-2026-0001'); // nomor pengajuan, dipakai di laporan
      expect(p.namaPerumahan, 'Griya Mangkubumi');
      expect(p.namaPt, 'PT Uji');
      expect(p.alamatProyek, 'Jl. Karikil');
      expect(p.statusTahap, StatusTahapPengajuan.surveyLapangan);
      expect(p.tanggalSurvey, DateTime(2026, 11, 2));
      expect(p.catatanSurvey, 'Bawa gambar');
    },
  );

  test('tugas tanpa nomor pengajuan memakai id tugas', () {
    final p = OfficerAssignment.fromJson(
      _assignment(id: 8, number: null),
    ).asPengajuan();
    expect(p.id, 'TUGAS-8');
  });

  group('submitReport', () {
    test(
      'urutan: buat draf, isi, unggah tiap foto, kirim; mengembalikan nomor BA',
      () async {
        final repo = build();
        adapter.reply(201, {'data': _report()});
        adapter.reply(200, {'data': _report(version: 2)});
        adapter.reply(201, {
          'data': {'id': 1},
        });
        adapter.reply(201, {
          'data': {'id': 2},
        });
        adapter.reply(200, {
          'data': _report(version: 3, number: '600.2.5/BA-MON/X/2026/001'),
        });

        final steps = <String>[];
        final number = await repo.submitReport(
          _draft(
            photos: [
              _photo('p1'),
              _photo('p2', source: PhotoSource.gallery),
            ],
          ),
          draftKey: 'kunci-1',
          latitude: -7.3274,
          longitude: 108.2207,
          onProgress: (m, f) => steps.add(m),
        );

        expect(number, '600.2.5/BA-MON/X/2026/001');
        expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
          'POST officer/reports',
          'PUT officer/reports/11',
          'POST officer/reports/11/photos',
          'POST officer/reports/11/photos',
          'POST officer/reports/11/submit',
        ]);
        expect(adapter.requests[0].headers['Idempotency-Key'], 'kunci-1');
        expect(adapter.requests[0].data, {'submission_number': 'SR-2026-0001'});

        final fields = adapter.requests[1].data as Map;
        expect(fields['version'], 1);
        expect(fields['monitoring_date'], '2026-10-26');
        expect(fields['temuan'], [
          'Jalan selesai',
          'Drainase belum',
        ]); // kosong dibuang
        expect(fields['status_hasil_evaluasi'], 'tidakSesuaiSiteplan');
        expect(fields['tim_pelaksana'], [
          {'nama': 'Rian', 'jabatan': 'Ketua'},
        ]);
        expect(fields['pihak_ditemui'], [
          {'nama': 'Asep', 'jabatan': 'Direktur'},
        ]);
        expect(fields['maksud_tujuan'], 'Memastikan kesesuaian.');

        final sources = adapter.requests
            .where((r) => r.path.endsWith('/photos'))
            .map(
              (r) => (r.data as FormData).fields
                  .firstWhere((f) => f.key == 'source')
                  .value,
            )
            .toList();
        expect(sources, ['camera', 'gallery']);
        expect(adapter.requests.last.data, {
          'latitude': -7.3274,
          'longitude': 108.2207,
        });
        expect(steps.last, 'Selesai');
      },
    );

    test('laporan mandiri (tanpa pengajuan) mengirim nama perumahan', () async {
      final repo = build();
      adapter.reply(201, {'data': _report()});
      adapter.reply(200, {'data': _report(version: 2)});
      adapter.reply(200, {'data': _report(version: 3, number: 'N')});

      await repo.submitReport(
        _draft(pengajuanId: null),
        draftKey: 'k',
        latitude: 1,
        longitude: 1,
      );

      expect(adapter.requests[0].data, {'nama_perumahan': 'Griya Mangkubumi'});
    });

    test(
      'percobaan ulang tidak mengunggah foto yang sudah ada di server',
      () async {
        final repo = build();
        final onServer = sha256.convert(bytes['p1']!).toString();
        adapter.reply(200, {
          'data': _report(
            photos: [
              {'checksum': onServer},
            ],
          ),
        });
        adapter.reply(200, {'data': _report(version: 2)});
        adapter.reply(201, {
          'data': {'id': 2},
        }); // hanya p2
        adapter.reply(200, {'data': _report(version: 3, number: 'N')});

        await repo.submitReport(
          _draft(photos: [_photo('p1'), _photo('p2')]),
          draftKey: 'k',
          latitude: 1,
          longitude: 1,
        );

        expect(
          adapter.requests.where((r) => r.path.endsWith('/photos')),
          hasLength(1),
        );
      },
    );

    test('foto yang tidak terbaca menghentikan proses sebelum kirim', () async {
      final repo = build();
      adapter.reply(201, {'data': _report()});
      adapter.reply(200, {'data': _report(version: 2)});

      await expectLater(
        repo.submitReport(
          _draft(photos: [_photo('hilang')]),
          draftKey: 'k',
          latitude: 1,
          longitude: 1,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'pesan',
            contains('Foto 1'),
          ),
        ),
      );
      expect(adapter.requests.any((r) => r.path.endsWith('/submit')), isFalse);
    });

    test(
      'tugas tidak ditemukan: pesan menyuruh memuat ulang daftar tugas',
      () async {
        final repo = build();
        adapter.reply(404, {
          'error': {'code': 'ERR-013', 'message': 'Data tidak ditemukan.'},
        });

        await expectLater(
          repo.submitReport(_draft(), draftKey: 'k', latitude: 1, longitude: 1),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'pesan',
              contains('Muat ulang daftar tugas'),
            ),
          ),
        );
      },
    );

    test(
      'galat validasi dan foto dari server ditampilkan apa adanya',
      () async {
        final repo = build();
        adapter.reply(201, {'data': _report()});
        adapter.reply(200, {'data': _report(version: 2)});
        adapter.reply(422, {
          'error': {
            'code': 'ERR-012',
            'message':
                'Foto diubah setelah diberi geotag, jadi tidak diterima.',
          },
        });

        await expectLater(
          repo.submitReport(
            _draft(photos: [_photo('p1')]),
            draftKey: 'k',
            latitude: 1,
            longitude: 1,
          ),
          throwsA(isA<ApiException>().having((e) => e.code, 'kode', 'ERR-012')),
        );

        final repo2 = build();
        adapter.reply(201, {'data': _report()});
        adapter.reply(200, {'data': _report(version: 2)});
        adapter.reply(422, {
          'error': {
            'code': 'ERR-010',
            'message': 'Isian tidak valid.',
            'fields': {
              'rtl': ['Wajib minimal 1 poin untuk hasil evaluasi ini.'],
            },
          },
        });
        await expectLater(
          repo2.submitReport(
            _draft(),
            draftKey: 'k',
            latitude: 1,
            longitude: 1,
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'pesan',
              contains('Wajib minimal 1 poin'),
            ),
          ),
        );
      },
    );
  });
}
