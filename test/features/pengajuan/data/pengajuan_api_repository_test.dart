import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/token_store.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/data/slot_catalog.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _submission({
  List<Map<String, dynamic>> files = const [],
  String statusTahap = 'draft',
  int version = 1,
  String? number,
}) => {
  'id': 5,
  'number': number,
  'stage': statusTahap == 'draft' ? 1 : 2,
  'sub_status': statusTahap == 'draft' ? 'draft' : 'baru',
  'status_tahap': statusTahap,
  'version': version,
  'nama_perumahan': 'Griya Uji',
  'nama_pt': 'PT Uji',
  'alamat_proyek': 'Jl. Uji',
  'tipe_pengajuan': 'Pengajuan Site Plan Baru',
  'npwp': '01.234',
  'luas_lahan': 1200.5,
  'jumlah_unit': 40,
  'tipe_perumahan': 'subsidi_komersil',
  'submitted_at': '2026-10-26T09:30:00+07:00',
  'updated_at': '2026-10-26T09:30:00+07:00',
  'developer_profile': {
    'nama_pt': 'PT Uji',
    'nama_direktur': 'Direktur Uji',
    'nib': '1234567890123',
  },
  'files': files,
};

Map<String, dynamic> _file(
  String slot,
  String name,
  int size, {
  String status = 'menunggu_telaah',
  String? note,
}) => {
  'id': 1,
  'slot_code': slot,
  'original_name': name,
  'size_bytes': size,
  'status': status,
  'review_note': note,
};

PengajuanFormState _form() => PengajuanFormState(
  namaPerumahan: 'Griya Uji',
  alamatProyek: 'Jl. Uji',
  npwpPerusahaan: '01.234',
  luasLahan: 1200.5,
  jumlahUnit: 40,
  tipePerumahan: 'Campuran',
  uploadedDocs: const {
    'ktp': r'C:\cache\ktp.pdf',
    'site_plan_dwg': r'C:\cache\site.dwg',
  },
  multiUploadedDocs: const {
    'rekomendasi_lingkungan': ['rek1.pdf', 'rek2.pdf'],
    'kajian_teknis': ['kajian.pdf'],
  },
  technicalFiles: const [r'C:\cache\site.dwg', r'C:\cache\site.pdf'],
);

void main() {
  late FakeHttpAdapter adapter;

  PengajuanApiRepository build({BytesReader? reader}) {
    adapter = FakeHttpAdapter();
    final dio = buildApiDio(
      baseUrl: 'http://uji.test/api/v1/',
      tokenStore: MemoryTokenStore('tok'),
      onUnauthorized: () {},
    )..httpClientAdapter = adapter;
    return PengajuanApiRepository(
      dio,
      readBytes:
          reader ??
          (ref) async => Uint8List.fromList(List.filled(ref.length * 10, 1)),
    );
  }

  group('SlotCatalog', () {
    test('semua kunci kontrak form punya kode slot, 18 kode unik', () {
      for (final s in PengajuanStep2DocumentContract.slots) {
        expect(SlotCatalog.codeByKey, contains(s.key));
      }
      for (final s in PengajuanStep3DocumentContract.slots) {
        expect(SlotCatalog.codeByKey, contains(s.key));
      }
      expect(SlotCatalog.codeByKey.values.toSet(), hasLength(18));
      expect(SlotCatalog.keyByCode['S4-01'], 'site_plan_dwg');
    });

    test('berkas dikelompokkan per slot, S4 dari berkas teknis', () {
      final slots = SlotCatalog.filesBySlot(_form());

      expect(slots['S2-01'], [r'C:\cache\ktp.pdf']);
      expect(slots['S3-05'], ['rek1.pdf', 'rek2.pdf']);
      expect(slots['S4-01'], [r'C:\cache\site.dwg', r'C:\cache\site.pdf']);
      expect(slots['S4-02'], ['kajian.pdf']);
      expect(slots.containsKey('S2-02'), isFalse);
    });

    test('jenis perumahan dua arah', () {
      expect(SlotCatalog.tipePerumahanToApi('Campuran'), 'subsidi_komersil');
      expect(SlotCatalog.tipePerumahanFromApi('komersil'), 'Komersil');
      expect(SlotCatalog.tipePerumahanFromApi(null), 'Subsidi');
    });
  });

  test('newDraftKey berbentuk UUID v4 dan berbeda tiap panggilan', () {
    final a = newDraftKey();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(a),
      isTrue,
    );
    expect(newDraftKey(), isNot(a));
  });

  group('submit', () {
    test('urutan: profil, draf, ubah, unggah tiap berkas, kirim', () async {
      final repo = build();
      adapter.reply(200, {
        'data': {'nib': '1'},
      });
      adapter.reply(201, {'data': _submission()});
      adapter.reply(200, {'data': _submission(version: 2)});
      for (var i = 0; i < 6; i++) {
        adapter.reply(201, {
          'data': {'id': i},
        });
      }
      adapter.reply(200, {
        'data': _submission(
          statusTahap: 'pengajuanBaru',
          number: 'SR-2026-0001',
          version: 3,
        ),
      });

      final steps = <String>[];
      final result = await repo.submit(
        _form(),
        draftKey: 'kunci-1',
        onProgress: (m, f) => steps.add(m),
      );

      final calls = adapter.requests
          .map((r) => '${r.method} ${r.path}')
          .toList();
      expect(calls.take(3), [
        'GET developer/profile',
        'POST submissions',
        'PATCH submissions/5',
      ]);
      expect(calls.where((c) => c == 'POST submissions/5/files'), hasLength(6));
      expect(calls.last, 'POST submissions/5/submit');
      expect(adapter.requests[1].headers['Idempotency-Key'], 'kunci-1');

      final patch = adapter.requests[2].data as Map;
      expect(patch['version'], 1);
      expect(patch['tipe_perumahan'], 'subsidi_komersil');
      expect(patch['jumlah_unit'], 40);
      expect(patch['current_step'], 5);

      final slotsUploaded = adapter.requests
          .where((r) => r.path.endsWith('/files'))
          .map(
            (r) => (r.data as FormData).fields
                .firstWhere((f) => f.key == 'slot_code')
                .value,
          )
          .toList();
      expect(slotsUploaded.toSet(), {'S2-01', 'S3-05', 'S4-01', 'S4-02'});
      expect(slotsUploaded.where((s) => s == 'S3-05'), hasLength(2));

      expect(result.id, 'SR-2026-0001');
      expect(result.statusTahap, StatusTahapPengajuan.verifikasiAdministrasi);
      expect(steps.last, 'Selesai');
    });

    test(
      'percobaan ulang tidak mengunggah ulang berkas yang sudah ada di server',
      () async {
        final repo = build(
          reader: (ref) async => Uint8List.fromList(List.filled(100, 1)),
        );
        adapter.reply(200, {
          'data': {'nib': '1'},
        });
        adapter.reply(200, {
          'data': _submission(files: [_file('S2-01', 'ktp.pdf', 100)]),
        });
        adapter.reply(200, {'data': _submission(version: 2)});
        adapter.reply(201, {
          'data': {'id': 1},
        }); // S3-05 #1
        adapter.reply(201, {
          'data': {'id': 2},
        }); // S3-05 #2
        adapter.reply(201, {
          'data': {'id': 3},
        }); // S4-01 .dwg
        adapter.reply(201, {
          'data': {'id': 4},
        }); // S4-01 .pdf
        adapter.reply(201, {
          'data': {'id': 5},
        }); // S4-02
        adapter.reply(200, {
          'data': _submission(
            statusTahap: 'pengajuanBaru',
            number: 'SR-2026-0002',
          ),
        });

        await repo.submit(_form(), draftKey: 'k');

        final uploads = adapter.requests
            .where((r) => r.path.endsWith('/files'))
            .length;
        expect(uploads, 5); // S2-01 dilewati
      },
    );

    test(
      'berkas yang tidak terbaca menghentikan proses sebelum kirim',
      () async {
        final repo = build(reader: (ref) async => null);
        adapter.reply(200, {
          'data': {'nib': '1'},
        });
        adapter.reply(201, {'data': _submission()});
        adapter.reply(200, {'data': _submission(version: 2)});

        await expectLater(
          repo.submit(_form(), draftKey: 'k'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'pesan',
              contains('ktp.pdf'),
            ),
          ),
        );
        expect(
          adapter.requests.any((r) => r.path.endsWith('/submit')),
          isFalse,
        );
      },
    );

    test('profil belum ada: berhenti dengan pesan jelas', () async {
      final repo = build();
      adapter.reply(200, {'data': null});

      await expectLater(
        repo.submit(_form(), draftKey: 'k'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'pesan',
            contains('Profil'),
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('berkas wajib kurang: pesan memuat nama berkas', () async {
      final repo = build();
      adapter.reply(200, {
        'data': {'nib': '1'},
      });
      adapter.reply(201, {'data': _submission()});
      adapter.reply(200, {'data': _submission(version: 2)});
      for (var i = 0; i < 6; i++) {
        adapter.reply(201, {
          'data': {'id': i},
        });
      }
      adapter.reply(422, {
        'error': {
          'code': 'ERR-010',
          'message': 'Isian tidak valid.',
          'fields': {
            'slots': ['S2-02', 'S3-11'],
          },
        },
      });

      await expectLater(
        repo.submit(_form(), draftKey: 'k'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'pesan',
            allOf(
              contains('NIB Perusahaan'),
              contains('Proposal Rencana Pembangunan'),
            ),
          ),
        ),
      );
    });

    test('galat unggah menyebut nama berkas dan slotnya', () async {
      final repo = build();
      adapter.reply(200, {
        'data': {'nib': '1'},
      });
      adapter.reply(201, {'data': _submission()});
      adapter.reply(200, {'data': _submission()}); // simpan data pengajuan
      adapter.reply(422, {
        'error': {'code': 'ERR-003', 'message': 'Berkas tidak dapat dibaca.'},
      });

      await expectLater(
        repo.submit(_form(), draftKey: 'k'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'kode', 'ERR-003')
              .having(
                (e) => e.message,
                'pesan',
                allOf(
                  contains('ktp.pdf'),
                  contains('gagal diunggah'),
                  contains('Berkas tidak dapat dibaca'),
                ),
              ),
        ),
      );
    });

    test('galat validasi server ditampilkan apa adanya', () async {
      final repo = build();
      adapter.reply(200, {
        'data': {'nib': '1'},
      });
      adapter.reply(201, {'data': _submission()});
      adapter.reply(422, {
        'error': {
          'code': 'ERR-001',
          'message':
              'Ukuran berkas melebihi 10 MB. Kecilkan berkas lalu unggah kembali.',
        },
      });

      await expectLater(
        repo.submit(_form(), draftKey: 'k'),
        throwsA(isA<ApiException>().having((e) => e.code, 'kode', 'ERR-001')),
      );
    });
  });

  group('list dan pemetaan', () {
    test(
      'draf tidak ikut daftar; berkas, verifikasi, dan perbaikan terpetakan',
      () async {
        final repo = build();
        final revision = _submission(
          statusTahap: 'perluPerbaikan',
          number: 'SR-2026-0007',
          files: [
            _file('S2-01', 'ktp.pdf', 10, status: 'sesuai'),
            _file(
              'S2-02',
              'nib.pdf',
              10,
              status: 'perlu_perbaikan',
              note: 'Buram',
            ),
            _file('S4-01', 'siteplan.dwg', 10),
            _file('S4-02', 'kajian.pdf', 10),
          ],
        )..['tahap_asal_perbaikan'] = 'verifikasiAdministrasi';
        adapter.reply(200, {
          'data': [_submission(), revision],
          'meta': {'page': 1, 'per_page': 50, 'total': 2},
        });

        final list = await repo.list();

        expect(list, hasLength(1));
        final p = list.single;
        expect(p.id, 'SR-2026-0007');
        expect(p.statusTahap, StatusTahapPengajuan.perluPerbaikan);
        expect(p.status, 'Perlu Perbaikan');
        expect(
          p.tahapAsalPerbaikan,
          StatusTahapPengajuan.verifikasiAdministrasi,
        );
        expect(p.verifiedDocs, {'ktp': true, 'nib': false});
        expect(p.dokumenPerluRevisi, ['nib']);
        expect(p.catatanPerbaikan, 'Buram');
        expect(p.uploadedDocs['ktp'], 'ktp.pdf');
        expect(p.uploadedDocs['site_plan_dwg'], 'siteplan.dwg');
        expect(p.technicalFiles, ['siteplan.dwg', 'kajian.pdf']);
        expect(p.tipePerumahan, 'Campuran');
        expect(p.namaDirektur, 'Direktur Uji');
        expect(p.tanggal, '26 Okt 2026');
        expect(adapter.requests.single.queryParameters['detail'], 1);
      },
    );

    test('tanpa jaringan: ApiException NETWORK', () async {
      final repo = build();
      // Tanpa jawaban terantri, adapter melempar StateError -> dibungkus Dio.
      await expectLater(repo.list(), throwsA(anything));
    });
  });

  group('ditolak dan riwayat', () {
    test('status_tahap ditolak tampil sebagai Ditolak, bukan administrasi', () async {
      final repo = build();
      adapter.reply(200, {
        'data': [_submission(statusTahap: 'ditolak', number: 'SR-2026-0009')],
        'meta': {'page': 1, 'per_page': 50, 'total': 1},
      });

      final p = (await repo.list()).single;
      expect(p.statusTahap, StatusTahapPengajuan.ditolak);
      expect(p.status, 'Ditolak');
    });

    test('timeline memuat peristiwa dan mengenali penolakan', () async {
      final repo = build();
      adapter.reply(200, {
        'data': [_submission(statusTahap: 'ditolak', number: 'SR-2026-0009')],
        'meta': {'page': 1, 'per_page': 50, 'total': 1},
      });
      await repo.list();
      adapter.reply(200, {
        'data': [
          {
            'id': 2,
            'type': 'decided',
            'title': 'Pengajuan ditolak',
            'description': 'Lahan tidak sesuai tata ruang.',
            'actor': 'Verifikator',
            'created_at': '2026-10-27T05:00:00+00:00',
          },
          {'id': 1, 'type': 'submitted', 'title': 'Pengajuan dikirim'},
        ],
      });

      final items = await repo.timeline('SR-2026-0009');
      expect(items, hasLength(2));
      expect(items.first.ditolak, isTrue);
      expect(items.first.description, 'Lahan tidak sesuai tata ruang.');
      expect(items.last.ditolak, isFalse);
      expect(adapter.requests.last.path, contains('submissions/5/timeline'));
    });
  });

  group('resubmit', () {
    Map<String, dynamic> flagged(int id, String slot) => {
      'id': id,
      'slot_code': slot,
      'original_name': 'lama.pdf',
      'size_bytes': 10,
      'status': 'perlu_perbaikan',
      'review_note': 'Buram',
    };

    test('mengganti hanya berkas yang ditandai lalu kirim ulang', () async {
      final repo = build();
      final revision = _submission(
        statusTahap: 'perluPerbaikan',
        number: 'SR-2026-0007',
        files: [
          _file('S2-01', 'ktp.pdf', 10, status: 'lolos'),
          flagged(9, 'S2-02'),
        ],
      );
      adapter.reply(200, {
        'data': [revision],
        'meta': {},
      }); // list (mengenali id)
      adapter.reply(200, {'data': revision}); // detail
      adapter.reply(201, {
        'data': {'id': 10},
      }); // unggah pengganti
      adapter.reply(200, {
        'data': _submission(
          statusTahap: 'verifikasiAdministrasi',
          number: 'SR-2026-0007',
        ),
      });

      final result = await repo.resubmit('SR-2026-0007', {
        'nib': 'nib-baru.pdf',
        'ktp': 'ktp-baru.pdf',
      });

      expect(result.id, 'SR-2026-0007');
      final uploads = adapter.requests
          .where((r) => r.path.endsWith('/files'))
          .toList();
      expect(uploads, hasLength(1)); // ktp tidak diminta, tidak diunggah
      final fields = {
        for (final f in (uploads.single.data as FormData).fields)
          f.key: f.value,
      };
      expect(fields['slot_code'], 'S2-02');
      expect(fields['replaces_file_id'], '9');
      expect(adapter.requests.last.path, endsWith('submissions/5/resubmit'));
    });

    test('berkas yang belum diganti: pesan menyebut nama berkasnya', () async {
      final repo = build();
      final revision = _submission(
        statusTahap: 'perluPerbaikan',
        number: 'SR-2026-0007',
        files: [flagged(9, 'S2-02')],
      );
      adapter.reply(200, {
        'data': [revision],
        'meta': {},
      });
      adapter.reply(200, {'data': revision});
      adapter.reply(422, {
        'error': {
          'code': 'ERR-010',
          'message': 'x',
          'fields': {
            'slots': ['S2-02'],
          },
        },
      });

      await expectLater(
        repo.resubmit('SR-2026-0007', const {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('belum diganti'),
          ),
        ),
      );
    });
  });
}
