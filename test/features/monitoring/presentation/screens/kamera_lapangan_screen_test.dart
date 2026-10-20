import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/camera_providers.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/kamera_lapangan_screen.dart';
import 'package:satu_rumah/features/monitoring/services/camera_gateway.dart';
import 'package:satu_rumah/features/monitoring/services/location_service.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

import '../../../../support/camera_fakes.dart';

void main() {
  late FakeCameraGateway camera;
  late FakeLocationService location;
  late MonitoringRepository repo;
  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester, {
    FakeCameraGateway? gateway,
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
      ],
    );
    addTearDown(container.dispose);
    container
        .read(monitoringFormProvider.notifier)
        .updateNamaPerumahan('Perumahan Uji');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KameraLapanganScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    PhotoBytesCache.clear();
    location = FakeLocationService();
  });

  testWidgets('memotret -> tinjau -> pakai foto menyimpan ke draf', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.textContaining('GPS siap'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Saluran drainase');
    await tester.tap(find.bySemanticsLabel('Ambil foto bergeotag'));
    await tester.pumpAndSettle();
    expect(find.text('Pakai foto ini'), findsOneWidget);
    expect(camera.session.captures, 1);

    await tester.tap(find.text('Pakai foto ini'));
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
    expect(find.text('1/$kMaxReportPhotos foto'), findsOneWidget);
  });

  testWidgets('Ulangi membuang hasil tanpa menyimpan', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.bySemanticsLabel('Ambil foto bergeotag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ulangi'));
    await tester.pumpAndSettle();
    expect(container.read(monitoringFormProvider).photos, isEmpty);
    expect(find.text('Pakai foto ini'), findsNothing);
  });

  testWidgets('tanpa GPS foto tidak diambil', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.timeout),
    );
    await pumpScreen(tester);
    expect(find.textContaining('belum terkunci'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Ambil foto bergeotag'));
    await tester.pumpAndSettle();
    expect(camera.session.captures, 0);
    expect(find.text('Pakai foto ini'), findsNothing);
  });

  testWidgets('lokasi palsu ditolak', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.mocked),
    );
    await pumpScreen(tester);
    expect(find.textContaining('Lokasi palsu'), findsWidgets);
    expect(camera.session.captures, 0);
  });

  testWidgets('izin lokasi diblokir menawarkan pengaturan', (tester) async {
    location = FakeLocationService(
      const LocationResult.failure(LocationFailure.deniedForever),
    );
    await pumpScreen(tester);
    await tester.tap(find.text('Buka pengaturan'));
    expect(location.settingsOpened, 1);
  });

  testWidgets('izin kamera ditolak menampilkan penjelasan', (tester) async {
    await pumpScreen(
      tester,
      gateway: FakeCameraGateway(failure: CameraFailure.denied),
    );
    expect(find.textContaining('Izin kamera ditolak'), findsOneWidget);
    expect(find.text('Coba lagi'), findsWidgets);
  });

  testWidgets('batas jumlah foto ditegakkan', (tester) async {
    await pumpScreen(tester);
    final notifier = container.read(monitoringFormProvider.notifier);
    final stamp = location.result.fix!;
    for (var i = 0; i < kMaxReportPhotos; i++) {
      notifier.addPhoto(
        ReportPhoto.create(
          source: PhotoSource.camera,
          stamp: GeoStampStub.at(stamp.latitude, stamp.longitude, i),
        ),
        plainJpeg(),
      );
    }
    await tester.tap(find.bySemanticsLabel('Ambil foto bergeotag'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Maksimal'), findsOneWidget);
    expect(camera.session.captures, 0);
  });
}
