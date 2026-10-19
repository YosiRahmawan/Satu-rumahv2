import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/tambah_monitoring_stepper_screen.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  Widget harness({GoRouter? router, TextScaler? textScaler}) {
    final appRouter = router ?? _router();
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        builder: (context, child) {
          if (textScaler == null) return child!;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
      ),
    );
  }

  Future<void> pumpStep1(
    WidgetTester tester, {
    Size size = const Size(412, 900),
    TextScaler? textScaler,
    GoRouter? router,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(harness(router: router, textScaler: textScaler));
    await tester.pumpAndSettle();
  }

  testWidgets('renders Langkah 1 and binds all canonical provider fields', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    final date = DateTime(2026, 1, 2);
    notifier.updateTanggal(date);
    notifier.updateNamaPerumahan('Perumahan Uji');
    notifier.updateLokasi('Jl. Uji No. 1');
    notifier.updateTemuan(['Temuan tersimpan']);
    notifier.updateKesimpulan(['Kesimpulan tersimpan']);

    await pumpStep1(tester);

    expect(find.text('Formulir Pengawasan'), findsOneWidget);
    expect(find.text('Langkah 1 dari 3: Info Umum'), findsOneWidget);
    expect(find.textContaining('2 Januari 2026'), findsOneWidget);
    expect(find.text('Perumahan Uji'), findsOneWidget);
    expect(find.text('Jl. Uji No. 1'), findsOneWidget);
    expect(
      find.text(container.read(monitoringFormProvider).maksudTujuan),
      findsOneWidget,
    );
    expect(find.text('Temuan tersimpan'), findsOneWidget);
    expect(find.text('Kesimpulan tersimpan'), findsOneWidget);
    expect(find.text('Simpan Draft'), findsOneWidget);
    expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsNothing);
    expect(find.text('Tersimpan di sesi formulir ini'), findsNothing);
    expect(find.text('Wajib'), findsNWidgets(2));
    expect(find.text('Opsional'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits fields and preserves add/remove point state in provider', (
    tester,
  ) async {
    await pumpStep1(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Perumahan Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lokasi Baru');
    final addPoint = find.text('+ Tambah Poin').first;
    await tester.ensureVisible(addPoint);
    await tester.tap(addPoint);
    await tester.pump();

    var state = container.read(monitoringFormProvider);
    expect(state.namaPerumahan, 'Perumahan Baru');
    expect(state.lokasiPerumahan, 'Lokasi Baru');
    expect(state.temuanLapangan, hasLength(2));

    final deletePoint = find.byTooltip('Hapus poin').first;
    await tester.ensureVisible(deletePoint);
    await tester.tap(deletePoint);
    await tester.pump();

    state = container.read(monitoringFormProvider);
    expect(state.temuanLapangan, hasLength(1));
    expect(state.kesimpulan, ['']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requires nama perumahan, then navigates and retains state', (
    tester,
  ) async {
    final router = _router();
    await pumpStep1(tester, router: router);

    await tester.tap(find.text('Lanjut ke Langkah 2'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 0);
    expect(find.text('Nama Perumahan wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Perumahan Persisten',
    );
    await tester.tap(find.text('Lanjut ke Langkah 2'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 1);
    expect(find.text('Langkah 2 dari 3: Info Lanjutan'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 0);
    expect(find.text('Perumahan Persisten'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/monitoring/tambah',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Step 2 sections and retains dynamic state', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Persisten');
    notifier.setStep(1);

    await pumpStep1(tester);

    expect(
      find.textContaining(
        "Jika tidak diisi, bagian opsional akan dicetak dengan tanda '-'",
      ),
      findsOneWidget,
    );
    expect(find.text('Kesepakatan'), findsOneWidget);
    expect(find.text('Rencana Tindak Lanjut'), findsOneWidget);
    expect(find.text('Tim Pelaksana Disperwaskim'), findsOneWidget);
    expect(find.text('Pihak Ditemui'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut ke Langkah 3'), findsOneWidget);

    await tester.tap(find.text('+ Tambah Poin').first);
    final addMember = find.text('Tambah Anggota Tim');
    await tester.ensureVisible(addMember);
    await tester.tap(addMember);
    final addVisitedParty = find.text('Tambah Pihak Ditemui');
    await tester.ensureVisible(addVisitedParty);
    await tester.tap(addVisitedParty);
    await tester.pump();

    final state = container.read(monitoringFormProvider);
    expect(state.kesepakatan, hasLength(2));
    expect(find.byTooltip('Hapus Anggota 1'), findsOneWidget);
    expect(find.byTooltip('Hapus Perwakilan Pengembang 1'), findsOneWidget);
    expect(find.text('Anggota 2'), findsOneWidget);
    expect(find.text('Perwakilan Pengembang 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step 2 footer returns to Step 1 without resetting fields', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Persisten');
    notifier.updateKesepakatan(['Kesepakatan tersimpan']);
    notifier.setStep(1);

    await pumpStep1(tester);
    await tester.tap(find.text('Kembali'));
    await tester.pump();

    expect(container.read(monitoringFormProvider).currentStep, 0);
    expect(container.read(monitoringFormProvider).kesepakatan, [
      'Kesepakatan tersimpan',
    ]);
    expect(find.text('Perumahan Persisten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting first team member preserves the second row values', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.setStep(1);
    notifier.addPelaksana();
    notifier.updatePelaksanaPerson(
      0,
      nama: 'Pelaksana Satu',
      jabatan: 'Jabatan Satu',
    );
    notifier.updatePelaksanaPerson(
      1,
      nama: 'Pelaksana Dua',
      jabatan: 'Jabatan Dua',
    );

    await pumpStep1(tester);
    final firstDelete = find.byTooltip('Hapus Anggota 1');
    await tester.ensureVisible(firstDelete);
    await tester.tap(firstDelete);
    await tester.pump();

    final state = container.read(monitoringFormProvider);
    expect(state.pelaksana.single.nama, 'Pelaksana Dua');
    expect(state.pelaksana.single.jabatan, 'Jabatan Dua');
    expect(find.text('Pelaksana Dua'), findsOneWidget);
    expect(find.byTooltip('Hapus Anggota 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting first visited party preserves the second row values', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.setStep(1);
    notifier.addDitemui();
    notifier.updateDitemuiPerson(
      0,
      nama: 'Ditemui Satu',
      jabatan: 'Jabatan Satu',
    );
    notifier.updateDitemuiPerson(
      1,
      nama: 'Ditemui Dua',
      jabatan: 'Jabatan Dua',
    );

    await pumpStep1(tester);
    final firstDelete = find.byTooltip('Hapus Perwakilan Pengembang 1');
    await tester.ensureVisible(firstDelete);
    await tester.tap(firstDelete);
    await tester.pump();

    final state = container.read(monitoringFormProvider);
    expect(state.ditemui.single.nama, 'Ditemui Dua');
    expect(state.ditemui.single.jabatan, 'Jabatan Dua');
    expect(find.text('Ditemui Dua'), findsOneWidget);
    expect(find.byTooltip('Hapus Perwakilan Pengembang 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step 2 to Step 3 and back retains repeatable people state', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.setStep(1);
    notifier.updatePelaksanaPerson(
      0,
      nama: 'Petugas Tetap',
      jabatan: 'Koordinator',
    );
    notifier.updateDitemuiPerson(
      0,
      nama: 'Pihak Tetap',
      jabatan: 'Site Manager',
    );

    await pumpStep1(tester);
    await tester.tap(find.text('Lanjut ke Langkah 3'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 2);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 1);
    expect(find.text('Petugas Tetap'), findsOneWidget);
    expect(find.text('Pihak Tetap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step 2 footer only exposes prototype actions', (tester) async {
    container.read(monitoringFormProvider.notifier).setStep(1);
    await pumpStep1(tester);

    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut ke Langkah 3'), findsOneWidget);
    expect(find.text('Simpan Draft'), findsOneWidget);
    expect(find.text('Status Hasil Evaluasi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Step 3 with active step and dynamic photo progress', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Dokumentasi');
    notifier.updatePhotos(['first.jpg', '', 'second.jpg']);
    notifier.setStep(2);

    await pumpStep1(tester);

    expect(find.text('Dokumentasi Lapangan'), findsOneWidget);
    expect(find.text('Langkah 3 dari 3: Dokumentasi Lapangan'), findsOneWidget);
    expect(find.text('2 foto · 0 sudah berlokasi'), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('Ringkasan validasi'), findsOneWidget);
    expect(find.text('Lokasi setiap foto (0 dari 2)'), findsOneWidget);
    expect(find.text('Perlu lokasi'), findsNWidgets(2));
    expect(find.text('Titik proyek dari Pengembang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Step 3 deletion requires confirmation and retains remaining state',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Dokumentasi');
      notifier.updatePhotos(['first.jpg', 'second.jpg']);
      notifier.setStep(2);

      await pumpStep1(tester);
      await tester.tap(find.byTooltip('Hapus foto 1'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus foto?'), findsOneWidget);
      expect(container.read(monitoringFormProvider).photoPaths, [
        'first.jpg',
        'second.jpg',
      ]);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      expect(container.read(monitoringFormProvider).photoPaths, ['second.jpg']);
      expect(find.text('1 foto · 0 sudah berlokasi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Step 3 opens BA preview without implying final submission', (
    tester,
  ) async {
    final router = _router();
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Preview');
    notifier.setStep(2);

    await pumpStep1(tester, router: router);

    expect(find.text('Submit & Buat Berita Acara'), findsOneWidget);

    final previewAction = find.text('Submit & Buat Berita Acara');
    final previewButton = find.ancestor(
      of: previewAction,
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(container.read(monitoringFormProvider).errorMessage, isNull);
    expect(find.text('Preview Berita Acara'), findsOneWidget);
    expect(container.read(monitoringFormProvider).isSubmitting, isFalse);
  });

  testWidgets('Step 3 menentukan lokasi foto lewat lembar lokasi', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Lokasi');
    notifier.updatePhotos(['first.jpg', 'second.jpg']);
    notifier.setStep(2);
    await pumpStep1(tester);

    await tester.ensureVisible(find.text('Perlu lokasi').first);
    await tester.tap(find.text('Perlu lokasi').first);
    await tester.pumpAndSettle();
    expect(find.text('Lokasi Foto 1'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-7.3274');
    await tester.enterText(fields.at(1), '108.2207');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan lokasi'));
    await tester.tap(find.text('Simpan lokasi'));
    await tester.pumpAndSettle();

    final photos = container.read(monitoringFormProvider).photos;
    expect(photos[0].location!.latitude, closeTo(-7.3274, 1e-9));
    expect(photos[1].location, isNull);
    expect(find.text('Lokasi Foto 1 disimpan.'), findsOneWidget);
    expect(find.text('2 foto · 1 sudah berlokasi'), findsOneWidget);
    expect(find.text('Lokasi setiap foto (1 dari 2)'), findsOneWidget);
    expect(find.text('Lokasi ditentukan manual'), findsOneWidget);
    expect(find.text('Perlu lokasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step 3 menahan lanjut ke preview bila ada foto tanpa lokasi', (
    tester,
  ) async {
    final router = _router();
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Blokir');
    notifier.updatePhotos(['first.jpg']);
    notifier.setStep(2);
    await pumpStep1(tester, router: router);

    final previewButton = find.ancestor(
      of: find.text('Submit & Buat Berita Acara'),
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(find.text('Preview Berita Acara'), findsNothing);
    expect(find.textContaining('1 foto belum memiliki lokasi'), findsOneWidget);
  });

  testWidgets('Simpan Draft tetap boleh walau foto belum berlokasi', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Draf Foto');
    notifier.updatePhotos(['first.jpg']);
    notifier.setStep(2);
    await pumpStep1(tester);

    await tester.ensureVisible(find.text('Simpan Draft'));
    await tester.tap(find.text('Simpan Draft'));
    await tester.pumpAndSettle();

    expect(container.read(monitoringFormProvider).errorMessage, isNull);
    expect(
      container
          .read(monitoringRepositoryProvider)
          .getAllMonitoring()
          .where((m) => m.isDraft && m.namaPerumahan == 'Perumahan Draf Foto'),
      hasLength(1),
    );
  });

  testWidgets('Step 3 remains usable at 360dp and 412dp with 200% text', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Responsif');
    notifier.setStep(2);

    for (final size in [const Size(360, 900), const Size(412, 900)]) {
      await pumpStep1(
        tester,
        size: size,
        textScaler: const TextScaler.linear(2),
      );
      expect(find.text('Dokumentasi Lapangan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('stepper remains stable at 360dp and 412dp with 200% text', (
    tester,
  ) async {
    for (final size in [const Size(360, 900), const Size(412, 900)]) {
      await pumpStep1(
        tester,
        size: size,
        textScaler: const TextScaler.linear(2),
      );
      expect(find.text('Formulir Pengawasan'), findsOneWidget);
      expect(find.text('Lanjut ke Langkah 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Step 1 footer remains visible at supported widths', (
    tester,
  ) async {
    for (final size in [const Size(360, 900), const Size(412, 900)]) {
      final flutterErrors = <FlutterErrorDetails>[];
      final previousFlutterError = FlutterError.onError;
      FlutterError.onError = flutterErrors.add;
      try {
        await pumpStep1(
          tester,
          size: size,
          textScaler: const TextScaler.linear(2),
        );

        final cancel = find.text('Batal');
        final saveDraft = find.text('Simpan Draft');
        final next = find.text('Lanjut ke Langkah 2');
        expect(cancel, findsOneWidget);
        expect(saveDraft, findsOneWidget);
        expect(next, findsOneWidget);

        for (final finder in [cancel, saveDraft, next]) {
          await tester.ensureVisible(finder);
          expect(tester.getRect(finder).bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);
      } finally {
        FlutterError.onError = previousFlutterError;
      }

      final layoutErrors = flutterErrors.where(
        (details) =>
            details.exceptionAsString().contains('RenderFlex') ||
            details.exceptionAsString().contains('overflow'),
      );
      expect(
        layoutErrors,
        isEmpty,
        reason: flutterErrors
            .map((details) => details.exceptionAsString())
            .join('\n'),
      );
      expect(flutterErrors, isEmpty);
    }
  });

  group('Stepper 3 Visual States & Bottom Action Bar Refinement', () {
    testWidgets(
      'Langkah 1 active: [1 MERAH] - [2 ABU] - [3 ABU] and correct footer actions',
      (tester) async {
        container.read(monitoringFormProvider.notifier).setStep(0);
        await pumpStep1(tester, size: const Size(390, 844));

        // Stepper circles
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);

        // Footer actions for Langkah 1
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Simpan Draft'), findsOneWidget);
        expect(find.text('Lanjut ke Langkah 2'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
        expect(find.text('Kembali'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Langkah 2 active: [✓ HIJAU] - [2 MERAH] - [3 ABU] and correct footer actions',
      (tester) async {
        container.read(monitoringFormProvider.notifier).setStep(1);
        await pumpStep1(tester, size: const Size(390, 844));

        // Step 1 completed (check icon), Step 2 active (number 2), Step 3 upcoming (number 3)
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        // Number 1 should not be displayed because it has check icon
        expect(find.text('1'), findsNothing);

        // Footer actions for Langkah 2
        expect(find.text('Kembali'), findsOneWidget);
        expect(find.text('Lanjut ke Langkah 3'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
        expect(find.text('Batal'), findsNothing);
        expect(find.text('Simpan Draft'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Langkah 3 active: [✓ HIJAU] - [✓ HIJAU] - [3 MERAH] and correct footer actions',
      (tester) async {
        container.read(monitoringFormProvider.notifier).setStep(2);
        await pumpStep1(tester, size: const Size(390, 844));

        // Step 1 & 2 completed (2 check icons), Step 3 active (number 3)
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(find.text('3'), findsOneWidget);
        expect(find.text('1'), findsNothing);
        expect(find.text('2'), findsNothing);

        // Footer actions for Langkah 3
        expect(find.text('Kembali'), findsOneWidget);
        expect(find.text('Submit & Buat Berita Acara'), findsOneWidget);
        expect(find.byIcon(Icons.check_box_outlined), findsNothing);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets(
        'stepper and bottom action bar render without overflow on ${width}dp',
        (tester) async {
          for (var step = 0; step < 3; step++) {
            container.read(monitoringFormProvider.notifier).setStep(step);
            await pumpStep1(tester, size: Size(width, 844));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });
  testWidgets('Simpan Draft menyimpan draf ke riwayat tanpa duplikat', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Griya Uji Draf');
    await pumpStep1(tester);
    final before = container.read(monitoringListProvider).length;

    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(find.text('Draf berhasil disimpan.'), findsOneWidget);
    var drafts = container
        .read(monitoringListProvider)
        .where((e) => e.namaPerumahan == 'Griya Uji Draf')
        .toList();
    expect(container.read(monitoringListProvider).length, before + 1);
    expect(drafts.single.isDraft, isTrue);

    notifier.updateNamaPerumahan('Griya Uji Draf Revisi');
    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(container.read(monitoringListProvider).length, before + 1);
    drafts = container
        .read(monitoringListProvider)
        .where((e) => e.namaPerumahan == 'Griya Uji Draf Revisi')
        .toList();
    expect(drafts.single.isDraft, isTrue);
  });

  test(
    'menyimpan draf yang dilanjutkan mempertahankan nomor BA dan tidak menggandakan',
    () {
      final repo = container.read(monitoringRepositoryProvider);
      final draft = repo.getAllMonitoring().firstWhere((e) => e.isDraft);
      final before = repo.getAllMonitoring().length;
      final notifier = container.read(monitoringFormProvider.notifier);

      notifier.loadDraft(draft);
      notifier.updateNamaPerumahan('${draft.namaPerumahan} Revisi');
      final saved = notifier.saveDraft();

      expect(saved, isNotNull);
      expect(saved!.id, draft.id);
      expect(saved.nomorSuratBA, draft.nomorSuratBA);
      expect(repo.getAllMonitoring().length, before);
      expect(
        repo.getMonitoringById(draft.id)!.namaPerumahan,
        '${draft.namaPerumahan} Revisi',
      );
    },
  );

  testWidgets('Batal tanpa perubahan langsung keluar tanpa dialog', (
    tester,
  ) async {
    await pumpStep1(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan draf sebelum keluar?'), findsNothing);
    expect(find.text('Monitoring'), findsOneWidget);
  });

  testWidgets('Batal dengan isian belum tersimpan menanyakan dulu', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    await pumpStep1(tester);
    notifier.updateNamaPerumahan('Griya Belum Disimpan');
    await tester.pump();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan draf sebelum keluar?'), findsOneWidget);

    await tester.tap(find.text('Lanjut mengisi'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan draf sebelum keluar?'), findsNothing);
    expect(find.text('Formulir Pengawasan'), findsOneWidget);
  });

  testWidgets('dialog keluar tersusun rapi di 360dp dengan teks 200%', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    await pumpStep1(
      tester,
      size: const Size(360, 640),
      textScaler: const TextScaler.linear(2),
    );
    notifier.updateNamaPerumahan('Griya Dialog');
    await tester.pump();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(ElevatedButton, 'Simpan draf');
    final discard = find.widgetWithText(OutlinedButton, 'Buang');
    final stay = find.widgetWithText(TextButton, 'Lanjut mengisi');
    expect(save, findsOneWidget);
    expect(discard, findsOneWidget);
    expect(stay, findsOneWidget);
    // Aksi utama paling atas, lalu Buang, lalu Lanjut mengisi; sama lebar.
    expect(tester.getTopLeft(save).dy, lessThan(tester.getTopLeft(discard).dy));
    expect(tester.getTopLeft(discard).dy, lessThan(tester.getTopLeft(stay).dy));
    expect(tester.getSize(save).width, tester.getSize(discard).width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Buang keluar tanpa menyimpan draf', (tester) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    await pumpStep1(tester);
    final before = container.read(monitoringListProvider).length;
    notifier.updateNamaPerumahan('Griya Dibuang');
    await tester.pump();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();

    expect(find.text('Monitoring'), findsOneWidget);
    expect(container.read(monitoringListProvider).length, before);
  });

  testWidgets(
    'Simpan draf dari dialog menyimpan lalu keluar dan memberi tahu',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      await pumpStep1(tester);
      final before = container.read(monitoringListProvider).length;
      notifier.updateNamaPerumahan('Griya Disimpan Lewat Dialog');
      await tester.pump();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan draf'));
      await tester.pumpAndSettle();

      expect(find.text('Monitoring'), findsOneWidget);
      expect(find.text('Draf berhasil disimpan.'), findsOneWidget);
      final list = container.read(monitoringListProvider);
      expect(list.length, before + 1);
      expect(
        list
            .firstWhere((e) => e.namaPerumahan == 'Griya Disimpan Lewat Dialog')
            .isDraft,
        isTrue,
      );
    },
  );

  testWidgets('Simpan draf dari dialog tanpa nama tetap di form dengan pesan', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    await pumpStep1(tester);
    notifier.updateNamaPerumahan('Sementara');
    await tester.pump();
    notifier.updateNamaPerumahan('');
    notifier.updateLokasi('Jl. Berubah');
    await tester.pump();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan draf'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Perumahan wajib diisi.'), findsOneWidget);
    expect(find.text('Formulir Pengawasan'), findsOneWidget);
  });

  test('draf yang dikirim final tidak tersisa sebagai draf', () {
    final repo = container.read(monitoringRepositoryProvider);
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updatePengajuanId('SR-20260720-612');
    notifier.updateNamaPerumahan('Green Tasik');
    notifier.updateStatusHasilEvaluasi(StatusHasilEvaluasi.sesuaiSiteplan);
    final draft = notifier.saveDraft()!;
    expect(repo.getMonitoringById(draft.id)!.isDraft, isTrue);

    final result = notifier.submitFinal(draft);

    expect(result.status, MonitoringSubmitStatus.success);
    final all = repo.getAllMonitoring().where((e) => e.id == draft.id).toList();
    expect(all.length, 1);
    expect(all.single.isDraft, isFalse);
  });

  testWidgets('Simpan Draft menolak form tanpa Nama Perumahan', (tester) async {
    await pumpStep1(tester);
    final before = container.read(monitoringListProvider).length;

    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(find.text('Nama Perumahan wajib diisi.'), findsOneWidget);
    expect(container.read(monitoringListProvider).length, before);
  });
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/monitoring/tambah',
    routes: [
      GoRoute(
        path: '/monitoring/tambah',
        builder: (_, __) => TambahMonitoringStepperScreen(
          locationMapBuilder: (_) => const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('Monitoring')),
      ),
      GoRoute(
        path: '/monitoring/preview',
        builder: (_, __) => const Scaffold(body: Text('Preview Berita Acara')),
      ),
    ],
  );
}
