import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/tambah_monitoring_stepper_screen.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/photo_location_sheet.dart';

OfficerLocation _manual(double lat, double lng) => OfficerLocation(
  latitude: lat,
  longitude: lng,
  method: LocationMethod.manualPin,
  selectedAt: DateTime(2026, 1, 1),
);

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

  Widget harness({TextScaler? textScaler}) {
    final appRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => TambahMonitoringStepperScreen(
            locationMapBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/monitoring/preview',
          builder: (context, state) =>
              const Scaffold(body: Text('Preview Berita Acara')),
        ),
      ],
    );

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

  Future<void> pumpStepper(
    WidgetTester tester, {
    Size size = const Size(412, 900),
    TextScaler? textScaler,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(harness(textScaler: textScaler));
    await tester.pumpAndSettle();
  }

  Future<void> tapChecklist(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }

  Future<void> tapBatchApply(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('terapkan_lokasi_batch_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Langkah 3: satu aksi "Atur sekaligus" yang berubah menjadi bilah pemilihan',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Griya Indah');
      notifier.updatePhotos(['p1.jpg', 'p2.jpg', 'p3.jpg']);
      notifier.setStep(2);

      await pumpStepper(tester);

      // Mode biasa: tanpa lingkaran pilih, tanpa bilah pemilihan.
      expect(find.text('Atur sekaligus'), findsOneWidget);
      expect(find.text('Ketuk foto untuk mengatur lokasinya.'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Submit & Buat Berita Acara'), findsOneWidget);

      // Masuk mode pilih: foto yang belum berlokasi terpilih otomatis.
      await tapText(tester, 'Atur sekaligus');
      expect(find.text('3 dipilih'), findsOneWidget);
      expect(find.text('Atur sekaligus'), findsNothing);
      expect(
        find.byKey(const ValueKey('terapkan_lokasi_batch_button')),
        findsOne,
      );

      // Kosongkan lalu pilih semua lagi lewat kotak centang.
      await tapChecklist(tester);
      expect(find.text('Pilih foto'), findsOneWidget);
      final apply = tester.widget<FilledButton>(
        find.byKey(const ValueKey('terapkan_lokasi_batch_button')),
      );
      expect(apply.onPressed, isNull);

      await tapChecklist(tester);
      expect(find.text('3 dipilih'), findsOneWidget);

      // Batal kembali ke mode biasa.
      await tapText(tester, 'Batal');
      expect(find.text('Atur sekaligus'), findsOneWidget);
      expect(find.text('3 dipilih'), findsNothing);
    },
  );

  testWidgets('Lokasi batch hanya diterapkan ke foto terpilih', (tester) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Tasik Asri');
    notifier.updatePhotos(['f1.jpg', 'f2.jpg', 'f3.jpg']);
    notifier.setStep(2);

    await pumpStepper(tester);

    await tapText(tester, 'Atur sekaligus');
    // Kosongkan seleksi, lalu pilih foto 1 dan 2.
    await tapChecklist(tester);
    await tester.tap(find.text('Dokumentasi 1'));
    await tester.tap(find.text('Dokumentasi 2'));
    await tester.pumpAndSettle();
    expect(find.text('2 dipilih'), findsOneWidget);

    await tapBatchApply(tester);
    expect(find.text('Atur lokasi 2 foto'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-7.3274');
    await tester.enterText(fields.at(1), '108.2207');
    await tester.pumpAndSettle();
    final apply = find.text('Terapkan ke 2 foto');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    final photos = container.read(monitoringFormProvider).photos;
    expect(photos[0].location!.latitude, closeTo(-7.3274, 1e-6));
    expect(photos[0].location!.method, LocationMethod.manualPin);
    expect(photos[1].location!.longitude, closeTo(108.2207, 1e-6));
    expect(photos[2].location, isNull);

    // Mode pilih ditutup dan ringkasan ikut diperbarui.
    expect(find.text('Atur sekaligus'), findsOneWidget);
    expect(find.text('3 foto · 2 sudah berlokasi'), findsOneWidget);
    expect(find.text('Perlu lokasi'), findsOneWidget);
    expect(find.text('Lokasi ditentukan manual'), findsNWidgets(2));
  });

  testWidgets(
    'Mengatur ulang satu foto setelah batch tidak mengubah yang lain',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Tasik Asri');
      notifier.updatePhotos(['f1.jpg', 'f2.jpg']);
      final ids = container
          .read(monitoringFormProvider)
          .photos
          .map((p) => p.id);
      notifier.setBatchPhotoLocations(ids, _manual(-7.3274, 108.2207));
      notifier.setStep(2);

      await pumpStepper(tester);
      expect(find.text('2 foto · 2 sudah berlokasi'), findsOneWidget);

      final status = find.text('Lokasi ditentukan manual');
      expect(status, findsNWidgets(2));
      await tester.ensureVisible(status.at(1));
      await tester.tap(status.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Lokasi Foto 2'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '-7.3276');
      await tester.pumpAndSettle();
      await tapText(tester, 'Simpan lokasi');

      final photos = container.read(monitoringFormProvider).photos;
      expect(photos[0].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(photos[1].location!.latitude, closeTo(-7.3276, 1e-6));
    },
  );

  testWidgets('Simpan draf mempertahankan lokasi saat dibuka kembali', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Griya Sukaratu');
    notifier.updatePhotos(['a.jpg', 'b.jpg']);
    final ids = container.read(monitoringFormProvider).photos.map((p) => p.id);
    notifier.setBatchPhotoLocations(ids, _manual(-7.3274, 108.2207));
    notifier.setStep(2);

    await pumpStepper(tester);
    await tapText(tester, 'Simpan Draft');
    expect(find.text('Draf berhasil disimpan.'), findsOneWidget);

    final savedPhotos = container.read(monitoringFormProvider).photos;
    notifier.resetForm();
    expect(container.read(monitoringFormProvider).photos, isEmpty);

    notifier.loadDraft(
      MonitoringModel(
        id: 'draft-test-1',
        namaPerumahan: 'Griya Sukaratu',
        tanggalMonitoring: DateTime(2026, 1, 1),
        photos: savedPhotos,
        isDraft: true,
      ),
    );
    notifier.setStep(2);
    await tester.pumpAndSettle();

    final restored = container.read(monitoringFormProvider).photos;
    expect(restored.length, 2);
    expect(restored[0].location!.latitude, closeTo(-7.3274, 1e-6));
    expect(restored[1].location!.latitude, closeTo(-7.3274, 1e-6));
    expect(find.text('2 foto · 2 sudah berlokasi'), findsOneWidget);
  });

  testWidgets('Lanjut ke preview ditahan sampai semua foto berlokasi', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Validasi');
    notifier.updatePhotos(['x.jpg', 'y.jpg']);
    notifier.setStep(2);

    await pumpStepper(tester);

    await tapText(tester, 'Submit & Buat Berita Acara');
    expect(find.textContaining('belum memiliki lokasi'), findsOneWidget);

    final ids = container.read(monitoringFormProvider).photos.map((p) => p.id);
    notifier.setBatchPhotoLocations(ids, _manual(-7.3274, 108.2207));
    await tester.pumpAndSettle();

    await tapText(tester, 'Submit & Buat Berita Acara');
    expect(find.text('Preview Berita Acara'), findsOneWidget);
  });

  testWidgets('Foto yang perlu dipilih ulang tampil jelas dan menahan submit', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Pulih');
    notifier.updatePhotoItems([
      EvidencePhotoItem.fromPath(
        'hilang.jpg',
      ).copyWith(location: _manual(-7.3274, 108.2207), needsReselect: true),
      EvidencePhotoItem.fromPath(
        'ada.jpg',
      ).copyWith(location: _manual(-7.3274, 108.2207)),
    ]);
    notifier.setStep(2);

    await pumpStepper(tester);

    expect(find.text('Foto perlu dipilih ulang'), findsOneWidget);
    expect(find.text('Perlu dipilih ulang'), findsOneWidget);
    expect(
      find.textContaining(
        '1 foto perlu dipilih ulang (berkas tidak tersimpan)',
      ),
      findsOneWidget,
    );

    // Mengetuk foto yang hilang tidak membuka lembar lokasi.
    await tester.ensureVisible(find.text('Perlu dipilih ulang'));
    await tester.tap(find.text('Perlu dipilih ulang'));
    await tester.pumpAndSettle();
    expect(find.text('Lokasi Foto 1'), findsNothing);
    expect(
      find.textContaining('Berkas foto ini tidak tersimpan'),
      findsOneWidget,
    );

    // Submit ditahan dengan alasan yang jelas.
    await tapText(tester, 'Submit & Buat Berita Acara');
    expect(find.text('Preview Berita Acara'), findsNothing);
    expect(
      find.textContaining('1 foto perlu dipilih ulang. Hapus lalu tambahkan'),
      findsOneWidget,
    );
  });

  testWidgets('Titik proyek tidak tersedia: jarak dinyatakan belum tersedia', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Proyek Tanpa Koordinat');
    notifier.updatePhotos(['foto1.jpg']);
    final ids = container.read(monitoringFormProvider).photos.map((p) => p.id);
    notifier.setBatchPhotoLocations(ids, _manual(-7.3274, 108.2207));
    notifier.setStep(2);

    await pumpStepper(tester);

    expect(find.text('Validasi jarak belum tersedia'), findsOneWidget);
    expect(find.text('Lokasi ditentukan manual'), findsOneWidget);
    expect(
      find.textContaining(
        'Belum tersedia. Jarak ke proyek tidak dapat dihitung',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Layar 360dp dengan teks 200% bebas overflow di Langkah 3', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Perumahan Responsif');
    notifier.updatePhotos(['r1.jpg', 'r2.jpg']);
    notifier.setStep(2);

    await pumpStepper(
      tester,
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(2.0),
    );

    expect(find.text('Dokumentasi Lapangan'), findsOneWidget);
    await tapText(tester, 'Atur sekaligus');
    await tester.ensureVisible(
      find.byKey(const ValueKey('terapkan_lokasi_batch_button')),
    );
    await tapBatchApply(tester);
    expect(find.byType(BatchPhotoLocationSheet), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
