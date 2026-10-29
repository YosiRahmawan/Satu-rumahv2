import 'dart:typed_data';

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
import 'package:satu_rumah/features/monitoring/presentation/widgets/signature_pad.dart';

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

Widget _app(Widget home, _Remote remote, {bool api = true}) => ProviderScope(
  overrides: [
    apiEnabledProvider.overrideWithValue(api),
    officerRemoteProvider.overrideWithValue(remote),
  ],
  child: MaterialApp(home: home),
);

/// Menggambar goresan di kanvas lalu menunggu ekspor PNG (butuh waktu nyata).
Future<void> _gambar(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('signature-pad')),
    const Offset(120, 40),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
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

/// Layar tinggi supaya tombol di bawah lipatan tetap terjangkau.
void _tw(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('SignaturePad', () {
    _tw('mengekspor PNG transparan hanya bila ada goresan', (tester) async {
      final c = SignaturePadController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SignaturePad(controller: c)),
        ),
      );

      expect(c.hasInk, isFalse);
      expect(await tester.runAsync(c.toPng), isNull);

      await tester.drag(
        find.byKey(const Key('signature-pad')),
        const Offset(100, 30),
      );
      await tester.pump();
      expect(c.hasInk, isTrue);
      final png = await tester.runAsync(c.toPng);
      expect(png, isNotNull);
      expect(png!.sublist(0, 4), [
        0x89,
        0x50,
        0x4E,
        0x47,
      ]); // tanda tangan berkas PNG

      c.clear();
      expect(c.hasInk, isFalse);
    });
  });

  group('TandaTanganBaScreen', () {
    _tw(
      'tombol kirim baru aktif setelah ada tanda tangan dan sandi; Hapus mengosongkan lagi',
      (tester) async {
        final remote = _Remote();
        await tester.pumpWidget(
          _app(
            const TandaTanganBaScreen(
              number: _nomor,
              namaPerumahan: 'Griya Uji',
            ),
            remote,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Belum ada tanda tangan'), findsOneWidget);
        expect(_kirimAktif(tester), isFalse);

        await _gambar(tester);
        expect(find.text('Belum ada tanda tangan'), findsNothing);
        expect(_kirimAktif(tester), isFalse); // sandi belum diisi

        await _isiSandi(tester);
        expect(_kirimAktif(tester), isTrue);

        await tester.tap(find.text('Hapus dan ulangi'));
        await tester.pump();
        expect(find.text('Belum ada tanda tangan'), findsOneWidget);
        expect(_kirimAktif(tester), isFalse);
      },
    );

    _tw(
      'berhasil: PNG dikirim dengan metode draw lalu layar menampilkan sudah menyetujui',
      (tester) async {
        final remote = _Remote();
        await tester.pumpWidget(
          _app(const TandaTanganBaScreen(number: _nomor), remote),
        );
        await tester.pumpAndSettle();
        await _gambar(tester);
        await _isiSandi(tester);
        await _kirim(tester);

        expect(remote.signCalls, 1);
        expect(remote.images.single.method, 'draw');
        expect(remote.images.single.bytes.sublist(0, 4), [
          0x89,
          0x50,
          0x4E,
          0x47,
        ]);
        expect(find.text('Anda sudah menyetujui BA ini'), findsOneWidget);
      },
    );

    _tw(
      'jaringan putus: pesan jelas, gambar tetap ada, percobaan ulang memakai kunci yang sama',
      (tester) async {
        final remote = _Remote()
          ..signOutcomes.add(
            const ApiException(code: 'NETWORK', message: 'putus'),
          );
        await tester.pumpWidget(
          _app(const TandaTanganBaScreen(number: _nomor), remote),
        );
        await tester.pumpAndSettle();
        await _gambar(tester);
        await _isiSandi(tester);
        await _kirim(tester);

        expect(find.textContaining('Koneksi bermasalah'), findsOneWidget);
        expect(find.text('Coba kirim lagi'), findsOneWidget);
        expect(
          find.text('Belum ada tanda tangan'),
          findsNothing,
        ); // gambar tidak hilang
        expect(_kirimAktif(tester), isTrue);

        await _kirim(tester); // retry
        expect(remote.signCalls, 2);
        expect(remote.keys.toSet(), hasLength(1)); // idempoten: kunci sama
        expect(find.text('Anda sudah menyetujui BA ini'), findsOneWidget);
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
      await tester.pumpWidget(
        _app(const TandaTanganBaScreen(number: _nomor), remote),
      );
      await tester.pumpAndSettle();
      await _gambar(tester);
      await _isiSandi(tester, 'salah');
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

    _tw(
      'bukan Ketua yang berwenang (403): pesan server ditampilkan, tidak dianggap berhasil',
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
        await tester.pumpWidget(
          _app(const TandaTanganBaScreen(number: _nomor), remote),
        );
        await tester.pumpAndSettle();
        await _gambar(tester);
        await _isiSandi(tester);
        await _kirim(tester);

        expect(find.textContaining('tidak berwenang'), findsOneWidget);
        expect(find.text('Anda sudah menyetujui BA ini'), findsNothing);
      },
    );

    _tw('sudah menandatangani: formulir tidak ditampilkan lagi', (
      tester,
    ) async {
      final remote = _Remote()
        ..status = const BaSignatureStatus(ketuaSigned: true);
      await tester.pumpWidget(
        _app(const TandaTanganBaScreen(number: _nomor), remote),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anda sudah menyetujui BA ini'), findsOneWidget);
      expect(find.byKey(const Key('ttd-kirim')), findsNothing);
    });

    _tw('mode lokal tanpa server: tidak bisa menandatangani', (tester) async {
      await tester.pumpWidget(
        _app(const TandaTanganBaScreen(number: _nomor), _Remote(), api: false),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('memerlukan koneksi'), findsOneWidget);
    });

    _tw('tombol mata menampilkan dan menyembunyikan sandi', (tester) async {
      await tester.pumpWidget(
        _app(const TandaTanganBaScreen(number: _nomor), _Remote()),
      );
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

    _tw(
      'pindah ke Unggah gambar menampilkan pemilih dan menyembunyikan kanvas',
      (tester) async {
        await tester.pumpWidget(
          _app(const TandaTanganBaScreen(number: _nomor), _Remote()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Unggah gambar'));
        await tester.pump();

        expect(find.byKey(const Key('signature-pad')), findsNothing);
        expect(find.text('Pilih gambar tanda tangan'), findsOneWidget);
        expect(_kirimAktif(tester), isFalse);
      },
    );
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

      expect(find.text('Ketua: belum menyetujui'), findsOneWidget);
      expect(find.text('Admin: belum menyetujui'), findsOneWidget);
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
      expect(find.text('Persetujuan Berita Acara'), findsNothing);
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
      'signReport: multipart dengan versi server, metode, dan Idempotency-Key',
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
          image: SignatureImage(
            bytes: Uint8List.fromList([1, 2, 3]),
            method: 'draw',
          ),
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
        expect(fields['method'], 'draw');
        expect(
          fields['version'],
          '3',
        ); // versi dari server, bukan tebakan klien
        expect(form.files.single.key, 'signature');
      },
    );

    test(
      'signReport: 403 dan 409 menjadi ApiException dengan pesan server',
      () async {
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
            image: SignatureImage(
              bytes: Uint8List.fromList([1]),
              method: 'upload',
            ),
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
      },
    );

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
