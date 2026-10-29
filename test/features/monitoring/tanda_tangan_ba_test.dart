import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/token_store.dart';
import 'package:satu_rumah/features/monitoring/data/models/ba_signature.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/tanda_tangan_ba_screen.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/ba_signature_entry_card.dart';

import '../../support/fake_http_adapter.dart';

const _nomor = '600.2.5/BA-MON/X/2026/001';

/// Server palsu untuk layar: jawaban bisa diatur, dan kunci idempotensi dicatat.
class _Remote implements OfficerRemote {
  BaSignatureStatus status = const BaSignatureStatus();
  final List<Object> signOutcomes =
      []; // ApiException => dilempar; lainnya => sukses
  final List<String> keys = [];
  final List<SignatureImage> images = [];
  int signCalls = 0;

  @override
  Future<BaSignatureStatus> signatureStatus(String reportNumber) async =>
      status;

  @override
  Future<BaSignatureStatus> signReport({
    required String reportNumber,
    required SignatureImage image,
    required String password,
    required String idempotencyKey,
  }) async {
    signCalls++;
    keys.add(idempotencyKey);
    images.add(image);
    final outcome = signOutcomes.isEmpty ? 'ok' : signOutcomes.removeAt(0);
    if (outcome is ApiException) throw outcome;
    status = BaSignatureStatus(
      ketuaSigned: true,
      ketuaAt: DateTime(2026, 10, 29, 10),
    );
    return status;
  }

  @override
  Future<List<OfficerAssignment>> assignments() async => const [];

  @override
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  }) => throw UnimplementedError();
}

/// PNG sungguhan (butuh waktu nyata) berukuran [w]x[h] dengan kotak biru di dalamnya.
Future<Uint8List> _png(WidgetTester tester, {int w = 300, int h = 100}) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(10, 10, w / 3, h / 2),
      Paint()..color = Colors.blue,
    );
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Widget _layar(_Remote remote, SignaturePicker picker, {bool api = true}) =>
    ProviderScope(
      overrides: [
        apiEnabledProvider.overrideWithValue(api),
        officerRemoteProvider.overrideWithValue(remote),
      ],
      child: MaterialApp(
        home: TandaTanganBaScreen(
          number: _nomor,
          namaPerumahan: 'Griya Uji',
          picker: picker,
        ),
      ),
    );

/// Layar tinggi supaya tombol di bawah lipatan tetap terjangkau.
void _tw(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

Future<void> _pilih(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('ttd-pilih')));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _isiSandi(
  WidgetTester tester, [
  String value = 'Sandi-Uji-2026',
]) async {
  await tester.enterText(find.byKey(const Key('ttd-sandi')), value);
  await tester.pump();
}

bool _kirimAktif(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('ttd-kirim'))).onPressed !=
    null;

Future<void> _kirim(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('ttd-kirim')));
  await tester.tap(find.byKey(const Key('ttd-kirim')));
  await tester.pumpAndSettle();
  // Dialog konfirmasi dengan pratinjau.
  await tester.tap(find.text('Ya, tandatangani'));
  await tester.pumpAndSettle();
}

/// Layar siap kirim: gambar valid dipilih dan sandi terisi.
Future<void> _siapKirim(
  WidgetTester tester,
  _Remote remote, {
  String ext = 'png',
  String sandi = 'Sandi-Uji-2026',
}) async {
  final png = await _png(tester);
  await tester.pumpWidget(_layar(remote, () async => (bytes: png, ext: ext)));
  await tester.pumpAndSettle();
  await _pilih(tester);
  await _isiSandi(tester, sandi);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('TandaTanganBaScreen', () {
    _tw(
      'petunjuk Suresman tampil dan tombol kirim nonaktif sampai ada gambar dan sandi',
      (tester) async {
        final png = await _png(tester);
        await tester.pumpWidget(
          _layar(_Remote(), () async => (bytes: png, ext: 'png')),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('suresman.tasikmalayakota.go.id'),
          findsOneWidget,
        );
        expect(find.text('Belum ada gambar'), findsOneWidget);
        expect(_kirimAktif(tester), isFalse);

        await _pilih(tester);
        expect(find.text('Belum ada gambar'), findsNothing);
        expect(_kirimAktif(tester), isFalse); // sandi belum diisi

        await _isiSandi(tester);
        expect(_kirimAktif(tester), isTrue);

        await tester.tap(find.text('Hapus gambar'));
        await tester.pump();
        expect(find.text('Belum ada gambar'), findsOneWidget);
        expect(_kirimAktif(tester), isFalse);
      },
    );

    _tw(
      'berhasil: gambar dikirim lalu layar menampilkan sudah menandatangani',
      (tester) async {
        final remote = _Remote();
        await _siapKirim(tester, remote);
        await _kirim(tester);

        expect(remote.signCalls, 1);
        expect(remote.images.single.contentType, 'image/png');
        expect(remote.images.single.bytes.sublist(0, 4), [
          0x89,
          0x50,
          0x4E,
          0x47,
        ]);
        expect(find.text('Anda sudah menandatangani BA ini'), findsOneWidget);
      },
    );

    _tw('ekstensi jpg dikirim dengan tipe image/jpeg', (tester) async {
      final remote = _Remote();
      await _siapKirim(tester, remote, ext: 'jpg');
      await _kirim(tester);

      expect(remote.images.single.contentType, 'image/jpeg');
      expect(remote.images.single.filename, 'ttd.jpg');
    });

    _tw(
      'jaringan putus: pesan jelas, gambar tetap ada, retry memakai kunci yang sama',
      (tester) async {
        final remote = _Remote()
          ..signOutcomes.add(
            const ApiException(code: 'NETWORK', message: 'putus'),
          );
        await _siapKirim(tester, remote);
        await _kirim(tester);

        expect(find.textContaining('Koneksi bermasalah'), findsOneWidget);
        expect(find.text('Coba kirim lagi'), findsOneWidget);
        expect(
          find.text('Belum ada gambar'),
          findsNothing,
        ); // gambar tidak hilang
        expect(_kirimAktif(tester), isTrue);

        await _kirim(tester); // retry
        expect(remote.signCalls, 2);
        expect(remote.keys.toSet(), hasLength(1)); // idempoten: kunci sama
        expect(find.text('Anda sudah menandatangani BA ini'), findsOneWidget);
      },
    );

    _tw('sandi salah: pesan server tampil dan kolom sandi dikosongkan', (
      tester,
    ) async {
      final remote = _Remote()
        ..signOutcomes.add(
          const ApiException(
            code: 'ERR-010',
            status: 422,
            message: 'Isian tidak valid.',
            fields: {
              'password': ['Sandi salah.'],
            },
          ),
        );
      await _siapKirim(tester, remote, sandi: 'salah');
      await _kirim(tester);

      expect(find.text('Sandi salah.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ttd-sandi')))
            .controller!
            .text,
        isEmpty,
      );
    });

    _tw('NIP akun belum diisi: pesan dari server ditampilkan apa adanya', (
      tester,
    ) async {
      final remote = _Remote()
        ..signOutcomes.add(
          const ApiException(
            code: 'ERR-010',
            status: 422,
            message: 'Isian tidak valid.',
            fields: {
              'nip': [
                'NIP akun Anda belum diisi. Minta admin melengkapinya di menu Akun.',
              ],
            },
          ),
        );
      await _siapKirim(tester, remote);
      await _kirim(tester);

      expect(find.textContaining('NIP akun Anda belum diisi'), findsOneWidget);
      expect(find.text('Anda sudah menandatangani BA ini'), findsNothing);
    });

    _tw(
      'bukan Ketua yang berwenang (403): pesan server tampil, tidak dianggap berhasil',
      (tester) async {
        final remote = _Remote()
          ..signOutcomes.add(
            const ApiException(
              code: 'ERR-022',
              status: 403,
              message:
                  'Akun ini tidak berwenang menandatangani BA sebagai ketua.',
            ),
          );
        await _siapKirim(tester, remote);
        await _kirim(tester);

        expect(find.textContaining('tidak berwenang'), findsOneWidget);
        expect(find.text('Anda sudah menandatangani BA ini'), findsNothing);
      },
    );

    _tw(
      'berkas ditolak di layar: bukan gambar, terlalu besar, terlalu kecil, ekstensi salah',
      (tester) async {
        final remote = _Remote();
        PickedSignature? next;
        await tester.pumpWidget(_layar(remote, () async => next));
        await tester.pumpAndSettle();

        next = (bytes: Uint8List.fromList([1, 2, 3, 4]), ext: 'png');
        await _pilih(tester);
        expect(find.text('Berkas bukan gambar yang valid.'), findsOneWidget);

        next = (bytes: Uint8List(4 * 1024 * 1024 + 1), ext: 'png');
        await _pilih(tester);
        expect(find.text('Ukuran gambar maksimal 4 MB.'), findsOneWidget);

        final kecil = await _png(tester, w: 30, h: 15);
        next = (bytes: kecil, ext: 'png');
        await _pilih(tester);
        expect(find.textContaining('terlalu kecil'), findsOneWidget);

        final ok = await _png(tester);
        next = (bytes: ok, ext: 'gif');
        await _pilih(tester);
        expect(find.text('Gunakan gambar PNG atau JPEG.'), findsOneWidget);

        expect(
          find.text('Belum ada gambar'),
          findsOneWidget,
        ); // tidak ada yang terpilih
        expect(remote.signCalls, 0);
      },
    );

    _tw('pemilih dibatalkan: tidak ada perubahan', (tester) async {
      await tester.pumpWidget(_layar(_Remote(), () async => null));
      await tester.pumpAndSettle();
      await _pilih(tester);
      expect(find.text('Belum ada gambar'), findsOneWidget);
    });

    _tw('sudah menandatangani: formulir tidak ditampilkan lagi', (
      tester,
    ) async {
      final remote = _Remote()
        ..status = const BaSignatureStatus(ketuaSigned: true);
      await tester.pumpWidget(_layar(remote, () async => null));
      await tester.pumpAndSettle();

      expect(find.text('Anda sudah menandatangani BA ini'), findsOneWidget);
      expect(find.byKey(const Key('ttd-kirim')), findsNothing);
    });

    _tw('mode lokal tanpa server: tidak bisa menandatangani', (tester) async {
      await tester.pumpWidget(_layar(_Remote(), () async => null, api: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('memerlukan koneksi'), findsOneWidget);
    });

    _tw('tombol mata menampilkan dan menyembunyikan sandi', (tester) async {
      await tester.pumpWidget(_layar(_Remote(), () async => null));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ttd-sandi')))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Tampilkan sandi'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ttd-sandi')))
            .obscureText,
        isFalse,
      );
    });
  });

  group('BaSignatureEntryCard', () {
    Widget host(_Remote remote, {bool api = true}) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: BaSignatureEntryCard(
                number: _nomor,
                namaPerumahan: 'Griya Uji',
              ),
            ),
          ),
          GoRoute(
            path: '/monitoring/tanda-tangan',
            builder: (_, _) => const Text('layar tanda tangan'),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          apiEnabledProvider.overrideWithValue(api),
          officerRemoteProvider.overrideWithValue(remote),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    _tw('menampilkan status dan tombol bila Ketua belum menandatangani', (
      tester,
    ) async {
      await tester.pumpWidget(host(_Remote()));
      await tester.pumpAndSettle();

      expect(find.text('Ketua: belum menandatangani'), findsOneWidget);
      expect(find.text('Admin: belum menandatangani'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ba-tandatangani')));
      await tester.pumpAndSettle();
      expect(find.text('layar tanda tangan'), findsOneWidget);
    });

    _tw('tanpa tombol bila sudah menandatangani dan ada label Diterbitkan', (
      tester,
    ) async {
      final remote = _Remote()
        ..status = const BaSignatureStatus(
          ketuaSigned: true,
          adminSigned: true,
          published: true,
        );
      await tester.pumpWidget(host(remote));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ba-tandatangani')), findsNothing);
      expect(find.text('Diterbitkan'), findsOneWidget);
    });

    _tw('tidak tampil di mode lokal', (tester) async {
      await tester.pumpWidget(host(_Remote(), api: false));
      await tester.pumpAndSettle();
      expect(find.text('Tanda Tangan Berita Acara'), findsNothing);
    });
  });

  group('OfficerApiRepository tanda tangan', () {
    late FakeHttpAdapter adapter;

    OfficerApiRepository build() {
      adapter = FakeHttpAdapter();
      final dio = buildApiDio(
        baseUrl: 'http://uji.test/api/v1/',
        tokenStore: MemoryTokenStore('tok'),
        onUnauthorized: () {},
      )..httpClientAdapter = adapter;
      return OfficerApiRepository(dio);
    }

    final daftar = {
      'data': [
        {'id': 7, 'report_number': _nomor, 'version': 3},
      ],
    };

    test(
      'signReport: multipart dengan versi server dan Idempotency-Key',
      () async {
        final repo = build();
        adapter.reply(200, daftar);
        adapter.reply(200, {
          'data': {
            'version': 3,
            'published_at': null,
            'signatures': {
              'ketua': {
                'signed': true,
                'signed_at': '2026-10-29T03:00:00+00:00',
              },
              'admin': {'signed': false},
            },
          },
        });

        final status = await repo.signReport(
          reportNumber: _nomor,
          image: SignatureImage(bytes: Uint8List.fromList([1, 2, 3])),
          password: 'rahasia',
          idempotencyKey: '11111111-1111-4111-8111-111111111111',
        );

        expect(status.ketuaSigned, isTrue);
        expect(status.adminSigned, isFalse);
        final post = adapter.requests.last;
        expect(post.method, 'POST');
        expect(post.path, 'officer/reports/7/sign');
        expect(
          post.headers['Idempotency-Key'],
          '11111111-1111-4111-8111-111111111111',
        );
        final form = post.data as FormData;
        final fields = {for (final f in form.fields) f.key: f.value};
        expect(
          fields['version'],
          '3',
        ); // versi dari server, bukan tebakan klien
        expect(fields.containsKey('method'), isFalse);
        expect(form.files.single.key, 'signature');
      },
    );

    test('signReport: 409 menjadi ApiException dengan pesan server', () async {
      final repo = build();
      adapter.reply(200, daftar);
      adapter.reply(409, {
        'error': {
          'code': 'ERR-011',
          'message': 'Isi BA telah berubah. Muat ulang BA.',
        },
      });

      await expectLater(
        repo.signReport(
          reportNumber: _nomor,
          image: SignatureImage(bytes: Uint8List.fromList([1])),
          password: 'x',
          idempotencyKey: '11111111-1111-4111-8111-111111111111',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'pesan',
            contains('berubah'),
          ),
        ),
      );
    });

    test('nomor BA yang tidak ada di server memberi galat jelas', () async {
      final repo = build();
      adapter.reply(200, {'data': []});

      await expectLater(
        repo.signatureStatus(_nomor),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
    });

    test(
      'signatureStatus: membaca status Ketua, Admin, dan penerbitan',
      () async {
        final repo = build();
        adapter.reply(200, daftar);
        adapter.reply(200, {
          'data': {
            'version': 3,
            'published_at': '2026-10-30T01:00:00+00:00',
            'signatures': {
              'ketua': {'signed': true},
              'admin': {'signed': true},
            },
          },
        });

        final s = await repo.signatureStatus(_nomor);
        expect([s.ketuaSigned, s.adminSigned, s.published], [true, true, true]);
        expect(adapter.requests.last.path, 'officer/reports/7');
      },
    );
  });
}
