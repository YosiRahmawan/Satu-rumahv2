import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_draft_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/mulai',
      routes: [
        GoRoute(
          path: '/mulai',
          builder: (_, __) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => mulaiPengajuanBaru(context, ref),
                child: const Text('Mulai'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pengajuan/step1',
          builder: (_, __) => const Scaffold(body: Text('Halaman Langkah 1')),
        ),
        GoRoute(
          path: '/pengajuan/step2',
          builder: (_, __) => const Scaffold(body: Text('Halaman Langkah 2')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Menulis ke penyimpanan butuh async sungguhan, bukan jam palsu widget test.
  Future<void> buatDraf(WidgetTester tester) async {
    final n = container.read(pengajuanFormProvider.notifier);
    n
      ..updateNamaPerumahan('Taman Asri')
      ..updateAlamatProyek('Jl. Contoh')
      ..updateNpwp('012345678411000')
      ..setNpwpVerified(true)
      ..updateLuasLahan(100)
      ..updateJumlahUnit(10);
    await tester.runAsync(n.saveDraft);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  testWidgets(
    'tombol Simpan Draft: animasi centang saat berhasil, tenang saat kosong',
    (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: DraftStatusRow())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(PhosphorIconsRegular.bookmarkSimple), findsOneWidget);
      expect(find.text('Disimpan otomatis di perangkat ini'), findsOneWidget);

      // Kosong: snackbar, tanpa animasi centang.
      await tester.tap(find.text('Simpan Draft'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Belum ada isian yang perlu disimpan.'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsNothing);
      await tester.pumpAndSettle();

      // Berisi: ikon berubah jadi centang sebentar lalu kembali, tanpa snackbar.
      await tester.runAsync(SharedPreferences.getInstance);
      container
          .read(pengajuanFormProvider.notifier)
          .updateNamaPerumahan('Taman Asri');
      await tester.pump();
      await tester.tap(find.text('Simpan Draft'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(); // frame pertama: animasi mulai
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsOneWidget);
      expect(find.text('Draf tersimpan di perangkat ini.'), findsNothing);
      expect(find.textContaining('Tersimpan otomatis pukul'), findsOneWidget);
      expect(find.text('Tersimpan'), findsOneWidget);

      // Tetap hijau selama isian tidak berubah.
      await tester.pumpAndSettle();
      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsOneWidget);
      expect(find.text('Tersimpan'), findsOneWidget);

      // Begitu form diubah, tombol kembali ke Simpan Draft.
      container
          .read(pengajuanFormProvider.notifier)
          .updateAlamatProyek('Jl. Baru');
      await tester.pumpAndSettle();
      expect(find.byIcon(PhosphorIconsRegular.bookmarkSimple), findsOneWidget);
      expect(find.text('Simpan Draft'), findsOneWidget);
    },
  );

  group('kartu draf', () {
    Future<void> pumpCard(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: PengajuanDraftCard()),
          ),
          GoRoute(
            path: '/pengajuan/step2',
            builder: (_, __) => const Scaffold(body: Text('Halaman Langkah 2')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tidak tampil bila tidak ada draf', (tester) async {
      await pumpCard(tester);
      expect(find.text('Draf pengajuan belum dikirim'), findsNothing);
    });

    testWidgets('tampil dengan nama dan waktu simpan, lalu Lanjutkan', (
      tester,
    ) async {
      await buatDraf(tester);
      container.invalidate(pengajuanFormProvider);
      await pumpCard(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draf pengajuan belum dikirim'), findsOneWidget);
      expect(
        find.textContaining('Taman Asri · Disimpan pukul'),
        findsOneWidget,
      );

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman Langkah 2'), findsOneWidget);
      expect(container.read(pengajuanFormProvider).namaPerumahan, 'Taman Asri');
    });

    testWidgets('Hapus meminta konfirmasi lalu menghapus draf', (tester) async {
      await buatDraf(tester);
      await pumpCard(tester);
      expect(find.text('Draf pengajuan belum dikirim'), findsOneWidget);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus draf pengajuan?'), findsOneWidget);

      // Batal: draf tetap ada.
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Draf pengajuan belum dikirim'), findsOneWidget);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Draf pengajuan belum dikirim'), findsNothing);

      final masihAda = await tester.runAsync(
        container.read(pengajuanFormProvider.notifier).hasDraft,
      );
      expect(masihAda, isFalse);
    });
  });

  testWidgets('tanpa draf langsung membuka Langkah 1', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    expect(find.text('Lanjutkan draf pengajuan?'), findsNothing);
    expect(find.text('Halaman Langkah 1'), findsOneWidget);
  });

  testWidgets('ada draf: Lanjutkan membuka langkah yang belum lengkap', (
    tester,
  ) async {
    await buatDraf(tester);
    // Simulasi buka aplikasi lagi: form di memori kosong, draf ada di perangkat.
    container.invalidate(pengajuanFormProvider);
    await pumpApp(tester);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Lanjutkan draf pengajuan?'), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Langkah 2'), findsOneWidget);
    expect(container.read(pengajuanFormProvider).namaPerumahan, 'Taman Asri');
  });

  testWidgets('ada draf: Mulai baru menghapus draf dan membuka Langkah 1', (
    tester,
  ) async {
    await buatDraf(tester);
    container.invalidate(pengajuanFormProvider);
    await pumpApp(tester);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai baru'));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Langkah 1'), findsOneWidget);
    expect(container.read(pengajuanFormProvider).hasContent, isFalse);
    final masihAda = await tester.runAsync(
      container.read(pengajuanFormProvider.notifier).hasDraft,
    );
    expect(masihAda, isFalse);
  });

  testWidgets('menutup dialog tanpa memilih tidak mengubah apa pun', (
    tester,
  ) async {
    await buatDraf(tester);
    container.invalidate(pengajuanFormProvider);
    await pumpApp(tester);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // ketuk di luar dialog
    await tester.pumpAndSettle();

    expect(find.text('Lanjutkan draf pengajuan?'), findsNothing);
    expect(find.text('Halaman Langkah 1'), findsNothing);
    final masihAda = await tester.runAsync(
      container.read(pengajuanFormProvider.notifier).hasDraft,
    );
    expect(masihAda, isTrue);
  });
}
