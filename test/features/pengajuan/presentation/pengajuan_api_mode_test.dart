import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step5_review_screen.dart';

class FakeRemote implements PengajuanRemote {
  List<Pengajuan> items = [];
  ApiException? submitError;
  int lists = 0;
  int submits = 0;
  String? lastKey;
  PengajuanFormState? lastForm;

  @override
  Future<List<Pengajuan>> list() async {
    lists++;
    return items;
  }

  @override
  Future<Pengajuan> submit(
    PengajuanFormState form, {
    required String draftKey,
    void Function(String message, double fraction)? onProgress,
  }) async {
    submits++;
    lastKey = draftKey;
    lastForm = form;
    onProgress?.call('Mengunggah…', 0.5);
    if (submitError != null) throw submitError!;
    return _item('SR-2026-0042');
  }

  @override
  Future<Pengajuan> resubmit(String number, Map<String, String> revisedDocs) async =>
      _item(number);
}

Pengajuan _item(String id) => Pengajuan(
  id: id,
  namaPerumahan: 'Griya $id',
  namaPt: 'PT Uji',
  namaDirektur: 'D',
  npwpPerusahaan: '1',
  luasLahan: 1,
  jumlahUnit: 1,
  tipePerumahan: 'Subsidi',
  status: 'Dalam Proses',
  tanggal: '26 Okt 2026',
  uploadedDocs: const {},
  statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
);

ProviderContainer _container(FakeRemote remote, {bool api = true}) {
  final c = ProviderContainer(
    overrides: [
      if (api) apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
      pengajuanRemoteProvider.overrideWithValue(remote),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('daftar pengajuan', () {
    test('mode API: kosong dulu, lalu diisi dari server untuk pengembang', () async {
      final remote = FakeRemote()..items = [_item('SR-2026-0001')];
      final c = _container(remote);
      c.read(roleSessionProvider.notifier).signIn(AppRole.developer, username: 'pengembang');

      expect(c.read(pengajuanListProvider), isEmpty); // tanpa data contoh
      await Future<void>.delayed(Duration.zero);

      expect(remote.lists, 1);
      expect(c.read(pengajuanListProvider).map((p) => p.id), ['SR-2026-0001']);
    });

    test('mode API: peran lain tidak memanggil server dan tidak ada data contoh', () async {
      final remote = FakeRemote();
      final c = _container(remote);
      c.read(roleSessionProvider.notifier).signIn(AppRole.perwaskim, username: 'lap');

      expect(c.read(pengajuanListProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(remote.lists, 0);
    });

    test('mode API: berganti akun membuat daftar baru', () async {
      final remote = FakeRemote()..items = [_item('SR-A')];
      final c = _container(remote);
      c.listen(pengajuanListProvider, (_, __) {});
      final session = c.read(roleSessionProvider.notifier);
      session.signIn(AppRole.developer, username: 'a');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(pengajuanListProvider), hasLength(1));

      remote.items = [];
      session.signIn(AppRole.developer, username: 'b');
      expect(c.read(pengajuanListProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(remote.lists, 2);
    });

    test('tanpa API: data contoh prototipe tetap ada dan server tidak dipanggil', () async {
      final remote = FakeRemote();
      final c = _container(remote, api: false);
      c.read(roleSessionProvider.notifier).signIn(AppRole.developer, username: 'a');

      expect(c.read(pengajuanListProvider), isNotEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(remote.lists, 0);
    });

    test('refresh mengembalikan galat dan mempertahankan daftar lama', () async {
      final remote = FakeRemote()..items = [_item('SR-1')];
      final c = _container(remote);
      c.read(roleSessionProvider.notifier).signIn(AppRole.developer, username: 'a');
      final notifier = c.read(pengajuanListProvider.notifier);
      await notifier.refresh();
      expect(c.read(pengajuanListProvider), hasLength(1));

      remote.items = [];
      // Gagal: pakai remote yang melempar.
      final failing = PengajuanListNotifier(remote: _Failing());
      expect((await failing.refresh())?.isNetwork, isTrue);
    });
  });

  group('Langkah 5: kirim lewat server', () {
    Future<(ProviderContainer, FakeRemote)> pump(WidgetTester tester, {bool api = true}) async {
      final remote = FakeRemote();
      final c = _container(remote, api: api);
      c.read(roleSessionProvider.notifier).signIn(AppRole.developer, username: 'pengembang');
      c.read(pengajuanFormProvider.notifier).fillDummyData();
      final router = GoRouter(
        initialLocation: '/pengajuan/step5',
        routes: [
          GoRoute(path: '/pengajuan/step5', builder: (_, __) => const PengajuanStep5ReviewScreen()),
          GoRoute(path: '/pengajuan/success', builder: (_, __) => const Scaffold(body: Text('Pengajuan berhasil'))),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      return (c, remote);
    }

    testWidgets('berhasil: dikirim ke server, masuk daftar, form dikosongkan', (tester) async {
      final (c, remote) = await pump(tester);
      final serverRemote = c.read(pengajuanRemoteProvider) as FakeRemote;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Pengajuan'));
      await tester.pumpAndSettle();

      expect(serverRemote.submits, 1);
      expect(serverRemote.lastKey, isNotNull);
      expect(serverRemote.lastForm!.namaPerumahan, isNotEmpty);
      expect(find.text('Pengajuan berhasil'), findsOneWidget);
      expect(c.read(pengajuanListProvider).first.id, 'SR-2026-0042');
      expect(c.read(pengajuanFormProvider).namaPerumahan, isEmpty);
      expect(remote, same(serverRemote));
    });

    testWidgets('gagal: pesan server tampil, tetap di layar, kunci percobaan ulang sama', (tester) async {
      final (c, _) = await pump(tester);
      final remote = c.read(pengajuanRemoteProvider) as FakeRemote
        ..submitError = const ApiException(code: 'ERR-001', message: 'Ukuran berkas melebihi 10 MB.');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Pengajuan'));
      await tester.pumpAndSettle();

      expect(find.text('Ukuran berkas melebihi 10 MB.'), findsOneWidget);
      expect(find.text('Pengajuan berhasil'), findsNothing);
      expect(c.read(pengajuanFormProvider).namaPerumahan, isNotEmpty);
      final firstKey = remote.lastKey;

      remote.submitError = null;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Pengajuan'));
      await tester.pumpAndSettle();

      expect(remote.lastKey, firstKey);
      expect(find.text('Pengajuan berhasil'), findsOneWidget);
    });

    testWidgets('tanpa API: perilaku lokal lama (tidak memanggil server)', (tester) async {
      final (c, _) = await pump(tester, api: false);
      final remote = c.read(pengajuanRemoteProvider) as FakeRemote;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Pengajuan'));
      await tester.pumpAndSettle();

      expect(remote.submits, 0);
      expect(find.text('Pengajuan berhasil'), findsOneWidget);
    });
  });
}

class _Failing implements PengajuanRemote {
  @override
  Future<List<Pengajuan>> list() async =>
      throw const ApiException(code: 'NETWORK', message: 'x');

  @override
  Future<Pengajuan> submit(
    PengajuanFormState form, {
    required String draftKey,
    void Function(String message, double fraction)? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<Pengajuan> resubmit(String number, Map<String, String> revisedDocs) =>
      throw UnimplementedError();
}
