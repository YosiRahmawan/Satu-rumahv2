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

  Widget harness({
    GoRouter? router,
    TextScaler? textScaler,
    DeviceLocationResolver? deviceLocationResolver,
  }) {
    final routes = [
      GoRoute(
        path: '/',
        builder: (context, state) => TambahMonitoringStepperScreen(
          deviceLocationResolver:
              deviceLocationResolver ??
              () async => DeviceFix(
                latitude: -7.3274,
                longitude: 108.2207,
                accuracyMeters: 5.0,
                recordedAt: DateTime(2026, 1, 1),
              ),
        ),
      ),
      GoRoute(
        path: '/monitoring/preview',
        builder: (context, state) =>
            const Scaffold(body: Text('Preview Berita Acara')),
      ),
    ];

    final appRouter = router ?? GoRouter(initialLocation: '/', routes: routes);

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
    DeviceLocationResolver? deviceLocationResolver,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      harness(
        textScaler: textScaler,
        deviceLocationResolver: deviceLocationResolver,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Langkah 3 menampilkan aksi sekunder Atur Lokasi Foto dan mode pemilihan batch',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Griya Indah');
      notifier.updatePhotos(['p1.jpg', 'p2.jpg', 'p3.jpg']);
      notifier.setStep(2);

      await pumpStepper(tester);

      // Aksi sekunder Atur Lokasi Foto harus ada di header foto
      final aturLokasiBtn = find.text('Atur Lokasi Foto');
      expect(aturLokasiBtn, findsOneWidget);

      // Pastikan tombol utama Submit tetap ada di bawah
      expect(find.text('Submit & Buat Berita Acara'), findsOneWidget);

      // Ketuk Atur Lokasi Foto -> membuka mode seleksi dengan foto belum berlokasi terpilih otomatis
      await tester.tap(aturLokasiBtn);
      await tester.pumpAndSettle();

      // Terbuka bottom sheet batch lokasi
      expect(find.text('Atur Lokasi Sekaligus'), findsOneWidget);
      expect(find.textContaining('3 foto terpilih'), findsWidgets);

      // Tutup sheet
      Navigator.of(tester.element(find.byType(BatchPhotoLocationSheet))).pop();
      await tester.pumpAndSettle();

      // Toolbar pemilihan foto aktif
      expect(find.text('3 terpilih'), findsOneWidget);
      expect(find.text('Batal Pilih'), findsOneWidget);

      // Batalkan pilihan semua
      await tester.tap(find.text('Batal Pilih'));
      await tester.pumpAndSettle();
      expect(find.text('0 terpilih'), findsOneWidget);
      expect(find.text('Pilih Semua'), findsOneWidget);

      // Pilih Semua kembali
      await tester.tap(find.text('Pilih Semua'));
      await tester.pumpAndSettle();
      expect(find.text('3 terpilih'), findsOneWidget);

      // Selesai mode pemilihan
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('3 terpilih'), findsNothing);
    },
  );

  testWidgets(
    'Batch location menerapkan koordinat HANYA ke foto terpilih dan menyisakan foto lain',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Tasik Asri');
      notifier.updatePhotos(['f1.jpg', 'f2.jpg', 'f3.jpg']);
      notifier.setStep(2);

      await pumpStepper(
        tester,
        deviceLocationResolver: () async => DeviceFix(
          latitude: -7.3274,
          longitude: 108.2207,
          accuracyMeters: 6.0,
          recordedAt: DateTime(2026, 1, 1),
        ),
      );

      // Masuk ke sheet lewat Atur Lokasi Foto
      await tester.tap(find.text('Atur Lokasi Foto'));
      await tester.pumpAndSettle();

      // Tutup sheet dulu untuk memilih hanya foto 1 dan foto 2
      Navigator.of(tester.element(find.byType(BatchPhotoLocationSheet))).pop();
      await tester.pumpAndSettle();

      // Kosongkan seleksi lalu pilih foto 1 dan 2
      await tester.tap(find.text('Batal Pilih'));
      await tester.pumpAndSettle();

      // Pilih foto 1 dan foto 2 via semantiks checkbox foto
      await tester.tap(find.bySemanticsLabel('Pilih foto 1'));
      await tester.tap(find.bySemanticsLabel('Pilih foto 2'));
      await tester.pumpAndSettle();

      expect(find.text('2 terpilih'), findsOneWidget);

      // Buka batch location untuk 2 foto terpilih
      await tester.tap(find.byKey(const ValueKey('atur_lokasi_foto_button')));
      await tester.pumpAndSettle();

      expect(find.text('Atur Lokasi Sekaligus'), findsOneWidget);
      expect(
        find.text('Pilih sumber koordinat untuk 2 foto terpilih.'),
        findsOneWidget,
      );

      // Terapkan GPS perangkat
      final applyBtn = find.text('Terapkan ke 2 foto terpilih');
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.text('Konfirmasi Lokasi Sekaligus'), findsOneWidget);
      expect(
        find.textContaining('Lokasi ini akan diterapkan ke 2 foto terpilih.'),
        findsOneWidget,
      );

      // Konfirmasi Terapkan
      await tester.tap(find.widgetWithText(FilledButton, 'Terapkan'));
      await tester.pumpAndSettle();

      // Verifikasi state provider: foto 1 & 2 terisi koordinat, foto 3 tetap null
      final photos = container.read(monitoringFormProvider).photos;
      expect(photos[0].hasLocation, isTrue);
      expect(photos[0].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(photos[0].location!.longitude, closeTo(108.2207, 1e-6));

      expect(photos[1].hasLocation, isTrue);
      expect(photos[1].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(photos[1].location!.longitude, closeTo(108.2207, 1e-6));

      expect(photos[2].hasLocation, isFalse);
      expect(photos[2].location, isNull);

      // Verifikasi UI stepper: 2 foto sudah berlokasi, 1 perlu lokasi
      expect(find.text('3 foto · 2 sudah berlokasi'), findsOneWidget);
      expect(find.text('Perlu lokasi'), findsOneWidget);
      expect(find.text('GPS perangkat'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Pengaturan lokasi individual setelah batch dapat menimpa koordinat foto tertentu',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Tasik Asri');
      notifier.updatePhotos(['f1.jpg', 'f2.jpg']);
      final photoIds = container
          .read(monitoringFormProvider)
          .photos
          .map((p) => p.id);
      // Awalnya foto 1 dan 2 punya koordinat batch sama
      notifier.setBatchPhotoLocations(
        photoIds,
        OfficerLocation(
          latitude: -7.3274,
          longitude: 108.2207,
          method: LocationMethod.deviceAtEntry,
          selectedAt: DateTime(2026, 1, 1),
        ),
      );
      notifier.setStep(2);

      await pumpStepper(tester);

      expect(find.text('2 foto · 2 sudah berlokasi'), findsOneWidget);

      // Ketuk foto 2 untuk membuka sheet lokasi individual
      final gpsPerangkatWidgets = find.text('GPS perangkat');
      expect(gpsPerangkatWidgets, findsNWidgets(2));
      await tester.ensureVisible(gpsPerangkatWidgets.at(1));
      await tester.tap(gpsPerangkatWidgets.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi Foto 2'), findsOneWidget);

      // Ubah lintang foto 2 menjadi titik manual baru
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '-7.3276');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Simpan lokasi'));
      await tester.tap(find.text('Simpan lokasi'));
      await tester.pumpAndSettle();

      // Foto 2 berubah jadi 'Lokasi ditentukan manual', Foto 1 tetap 'GPS perangkat'
      final photos = container.read(monitoringFormProvider).photos;
      expect(photos[0].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(photos[0].location!.method, LocationMethod.deviceAtEntry);

      expect(photos[1].location!.latitude, closeTo(-7.3276, 1e-6));
      expect(photos[1].location!.method, LocationMethod.manualPin);

      expect(find.text('GPS perangkat'), findsOneWidget);
      expect(find.text('Lokasi ditentukan manual'), findsOneWidget);
    },
  );

  testWidgets(
    'Penyimpanan draft mempertahankan koordinat batch dan individual saat dibuka kembali',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Griya Sukaratu');
      notifier.updatePhotos(['a.jpg', 'b.jpg']);
      final photoIds = container
          .read(monitoringFormProvider)
          .photos
          .map((p) => p.id);
      notifier.setBatchPhotoLocations(
        photoIds,
        OfficerLocation(
          latitude: -7.3274,
          longitude: 108.2207,
          method: LocationMethod.deviceAtEntry,
          selectedAt: DateTime(2026, 1, 1),
        ),
      );
      notifier.setStep(2);

      await pumpStepper(tester);

      // Simpan Draft
      final simpanDraftBtn = find.text('Simpan Draft');
      await tester.tap(simpanDraftBtn);
      await tester.pumpAndSettle();

      expect(find.text('Draf berhasil disimpan.'), findsOneWidget);

      // Reset state form seperti aplikasi baru dibuka / load draft
      final savedPhotos = container.read(monitoringFormProvider).photos;
      notifier.resetForm();
      expect(container.read(monitoringFormProvider).photos, isEmpty);

      // Pulihkan form dari snapshot draft
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

      // Verifikasi koordinat tetap ada setelah pemulihan draft
      final restoredPhotos = container.read(monitoringFormProvider).photos;
      expect(restoredPhotos.length, 2);
      expect(restoredPhotos[0].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(restoredPhotos[1].location!.latitude, closeTo(-7.3274, 1e-6));
      expect(find.text('2 foto · 2 sudah berlokasi'), findsOneWidget);
    },
  );

  testWidgets(
    'Validasi submit menahan submit jika ada foto tanpa lokasi dan lanjut ke preview saat lengkap',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Validasi');
      notifier.updatePhotos(['x.jpg', 'y.jpg']);
      notifier.setStep(2);

      await pumpStepper(tester);

      final submitBtn = find.text('Submit & Buat Berita Acara');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Gagal submit karena foto belum berlokasi
      expect(find.textContaining('belum memiliki lokasi'), findsOneWidget);

      // Atur lokasi untuk semua foto
      final photoIds = container
          .read(monitoringFormProvider)
          .photos
          .map((p) => p.id);
      notifier.setBatchPhotoLocations(
        photoIds,
        OfficerLocation(
          latitude: -7.3274,
          longitude: 108.2207,
          method: LocationMethod.deviceAtEntry,
          selectedAt: DateTime(2026, 1, 1),
        ),
      );
      await tester.pumpAndSettle();

      // Submit lagi
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Sukses navigasi ke preview
      expect(find.text('Preview Berita Acara'), findsOneWidget);
    },
  );

  testWidgets(
    'Titik proyek tidak tersedia menampilkan status validasi jarak belum tersedia',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Proyek Tanpa Koordinat');
      notifier.updatePhotos(['foto1.jpg']);
      final photoIds = container
          .read(monitoringFormProvider)
          .photos
          .map((p) => p.id);
      notifier.setBatchPhotoLocations(
        photoIds,
        OfficerLocation(
          latitude: -7.3274,
          longitude: 108.2207,
          method: LocationMethod.manualPin,
          selectedAt: DateTime(2026, 1, 1),
        ),
      );
      notifier.setStep(2);

      await pumpStepper(tester);

      // Status detail harus menyatakan validasi jarak belum tersedia
      expect(find.text('Validasi jarak belum tersedia'), findsOneWidget);
      expect(find.text('Lokasi ditentukan manual'), findsOneWidget);
      expect(
        find.textContaining(
          'Belum tersedia. Jarak ke proyek tidak dapat dihitung',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Responsivitas layar sempit (360dp) dan text scale 200% pada Langkah 3 bebas overflow',
    (tester) async {
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Perumahan Responsif');
      notifier.updatePhotos(['r1.jpg', 'r2.jpg']);
      notifier.setStep(2);

      await pumpStepper(
        tester,
        size: const Size(360, 800),
        textScaler: const TextScaler.linear(2.0),
      );

      // Header dan aksi sekunder tampil rapi
      final aturBtn = find.text('Atur Lokasi Foto');
      await tester.ensureVisible(aturBtn);
      expect(aturBtn, findsOneWidget);
      expect(find.text('Dokumentasi Lapangan'), findsOneWidget);

      // Aktifkan mode pemilihan
      await tester.tap(aturBtn);
      await tester.pumpAndSettle();

      // Batal sheet
      Navigator.of(tester.element(find.byType(BatchPhotoLocationSheet))).pop();
      await tester.pumpAndSettle();

      // Tidak boleh ada Flutter error / overflow exception
      expect(tester.takeException(), isNull);
    },
  );
}
