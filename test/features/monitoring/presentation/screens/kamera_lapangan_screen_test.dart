import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/kamera_context.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/camera_providers.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/kamera_lapangan_screen.dart';
import 'package:satu_rumah/features/monitoring/services/camera_gateway.dart';
import 'package:satu_rumah/features/monitoring/services/location_service.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

import '../../../../support/camera_fakes.dart';

Pengajuan _task(String id, String nama) => Pengajuan(
  id: id,
  namaPerumahan: nama,
  namaPt: 'PT Uji',
  namaDirektur: 'Direktur',
  npwpPerusahaan: '01.234.567.8',
  luasLahan: 1000,
  jumlahUnit: 20,
  tipePerumahan: 'Subsidi',
  status: 'Survey Dijadwalkan',
  tanggal: '2026-05-10',
  uploadedDocs: const {},
  tanggalSurvey: DateTime(2026, 5, 20),
);

void main() {
  late FakeCameraGateway camera;
  late FakeLocationService location;
  late MonitoringRepository repo;
  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester, {
    FakeCameraGateway? gateway,
    KameraContext? context,
    List<Pengajuan> tasks = const [],
    bool prefillForm = true,
  }) async {
    camera = gateway ?? FakeCameraGateway();
    repo = MonitoringRepository();
    container = ProviderContainer(
      overrides: [
        cameraGatewayProvider.overrideWithValue(camera),
        locationServiceProvider.overrideWithValue(location),
        geocodingServiceProvider.overrideWithValue(FakeGeocoding()),
        mapThumbnailProvider.overrideWithValue(FakeMapThumbnail()),
        stampRenderFnProvider.overrideWithValue(fakeRender),
        monitoringRepositoryProvider.overrideWithValue(repo),
        surveyAktifProvider.overrideWithValue(tasks),
        roleSessionProvider.overrideWith(
          (ref) => RoleSessionNotifier()
            ..signIn(AppRole.perwaskim, username: 'tim_monitoring_perwaskim'),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (prefillForm) {
      container
          .read(monitoringFormProvider.notifier)
          .updateNamaPerumahan('Perumahan Uji');
    }
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: KameraLapanganScreen(
            contextData:
                context ?? const KameraContext.formAktif(taskTitle: 'Uji'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shoot(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Ambil foto bergeotag'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    PhotoBytesCache.clear();
    location = FakeLocationService();
  });

  testWidgets('shutter aktif: potret, tinjau, simpan ke draf form aktif', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.textContaining('GPS ±8 m'), findsOneWidget);
    // Overlay watermark langsung di viewfinder.
    expect(find.textContaining('-7.327400, 108.220700'), findsOneWidget);
    expect(find.textContaining('Jl. Contoh No. 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Saluran drainase');
    await shoot(tester);
    expect(find.text('Pratinjau Bukti Lapangan'), findsOneWidget);
    expect(camera.session.captures, 1);

    await tester.tap(find.text('Simpan ke Draf BA'));
    await tester.pumpAndSettle();

    final photos = container.read(monitoringFormProvider).photos;
    expect(photos, hasLength(1));
    expect(photos.single.source, PhotoSource.camera);
    expect(photos.single.stamp.note, 'Saluran drainase');
    expect(photos.single.stamp.address, contains('Jl. Contoh'));
    final bytes = PhotoBytesCache.get(photos.single.id)!;
    expect(GeoStampSigner.verify(bytes).stamp, photos.single.stamp);

    final drafts = repo.getAllMonitoring().where(
      (m) => m.isDraft && m.namaPerumahan == 'Perumahan Uji',
    );
    expect(drafts.single.photos, hasLength(1));
    expect(find.text('1 foto tersimpan dari sesi ini'), findsOneWidget);
  });

  testWidgets('mode tugas menyiapkan draf tugas lalu menyimpan foto', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefillForm: false,
      tasks: [_task('task-1', 'Perumahan Indah')],
      context: const KameraContext.tugas(
        taskId: 'task-1',
        taskTitle: 'Perumahan Indah',
      ),
    );
    await shoot(tester);
    await tester.tap(find.text('Simpan ke Draf BA'));
    await tester.pumpAndSettle();

    final form = container.read(monitoringFormProvider);
    expect(form.pengajuanId, 'task-1');
    expect(form.namaPerumahan, 'Perumahan Indah');
    expect(form.photos, hasLength(1));
    expect(
      repo
          .getAllMonitoring()
          .where((m) => m.isDraft && m.pengajuanId == 'task-1')
          .single
          .photos,
      hasLength(1),
    );
  });

  testWidgets('mode mandiri meminta memilih tugas saat menyimpan', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefillForm: false,
      tasks: [_task('task-1', 'Perumahan Satu'), _task('task-2', 'Perumahan Dua')],
      context: const KameraContext.mandiri(),
    );
    await shoot(tester);
    await tester.tap(find.text('Pilih tugas & simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan foto ke tugas mana?'), findsOneWidget);

    await tester.tap(find.text('Perumahan Dua'));
    await tester.pumpAndSettle();
    final form = container.read(monitoringFormProvider);
    expect(form.pengajuanId, 'task-2');
    expect(form.photos, hasLength(1));
  });

  testWidgets('mode mandiri tanpa tugas aktif: foto tidak disimpan', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      prefillForm: false,
      context: const KameraContext.mandiri(),
    );
    await shoot(tester);
    await tester.tap(find.text('Pilih tugas & simpan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada tugas survei aktif'), findsOneWidget);
    expect(container.read(monitoringFormProvider).photos, isEmpty);
    expect(find.text('Pratinjau Bukti Lapangan'), findsOneWidget);
  });

  testWidgets('Foto Ulang membuang hasil tanpa menyimpan', (tester) async {
    await pumpScreen(tester);
    await shoot(tester);
    await tester.tap(find.text('Foto Ulang'));
    await tester.pumpAndSettle();
    expect(container.read(monitoringFormProvider).photos, isEmpty);
    expect(find.text('Pratinjau Bukti Lapangan'), findsNothing);
  });

  testWidgets('flash dikirim ke kamera', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Flash'));
    await tester.pumpAndSettle();
    expect(camera.session.flashOn, isTrue);
  });

  testWidgets('tanpa GPS foto tidak diambil', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.timeout),
    );
    await pumpScreen(tester);
    expect(find.text('GPS belum siap'), findsOneWidget);
    await shoot(tester);
    expect(camera.session.captures, 0);
    expect(find.text('Pratinjau Bukti Lapangan'), findsNothing);
  });

  testWidgets('lokasi palsu ditolak', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.mocked),
    );
    await pumpScreen(tester);
    await shoot(tester);
    expect(find.textContaining('Lokasi palsu'), findsWidgets);
    expect(camera.session.captures, 0);
  });

  testWidgets('izin lokasi diblokir menawarkan pengaturan', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.deniedForever),
    );
    await pumpScreen(tester);
    await tester.tap(find.text('Pengaturan'));
    expect(location.settingsOpened, 1);
  });

  testWidgets('izin kamera ditolak menampilkan penjelasan dan Coba lagi', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      gateway: FakeCameraGateway(failure: CameraFailure.denied),
    );
    expect(find.textContaining('Izin kamera ditolak'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('batas jumlah foto ditegakkan saat menyimpan', (tester) async {
    await pumpScreen(tester);
    final notifier = container.read(monitoringFormProvider.notifier);
    for (var i = 0; i < kMaxReportPhotos; i++) {
      notifier.addPhoto(
        ReportPhoto.create(
          source: PhotoSource.camera,
          stamp: GeoStampStub.at(-7.3, 108.2, i),
        ),
        plainJpeg(),
      );
    }
    await shoot(tester);
    await tester.tap(find.text('Simpan ke Draf BA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Maksimal'), findsOneWidget);
    expect(
      container.read(monitoringFormProvider).photos,
      hasLength(kMaxReportPhotos),
    );
  });
}
