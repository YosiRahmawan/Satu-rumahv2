import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/camera_providers.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/foto_dokumentasi_section.dart';
import 'package:satu_rumah/features/monitoring/services/photo_import.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

import '../../../../support/camera_fakes.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id', null));
  setUp(PhotoBytesCache.clear);

  final stamp = GeoStamp(
    latitude: -7.3274,
    longitude: 108.2207,
    capturedAt: DateTime.utc(2026, 10, 20, 2, 30),
    note: 'Jalan lingkungan',
  );

  late ProviderContainer container;
  late FakePhotoPicker picker;
  var cameraOpened = 0;

  Future<void> pump(WidgetTester tester) async {
    cameraOpened = 0;
    picker = FakePhotoPicker();
    container = ProviderContainer(
      overrides: [
        photoPickerProvider.overrideWithValue(picker),
        monitoringRepositoryProvider.overrideWithValue(MonitoringRepository()),
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
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FotoDokumentasiSection(onOpenCamera: () => cameraOpened++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kosong: tombol Kamera membuka kamera', (tester) async {
    await pump(tester);
    expect(find.textContaining('Belum ada foto'), findsOneWidget);
    await tester.tap(find.text('Kamera'));
    expect(cameraOpened, 1);
  });

  testWidgets('galeri menerima foto bergeotag dan menolak yang tidak', (
    tester,
  ) async {
    await pump(tester);
    picker.files = [
      PickedPhotoFile('sah.jpg', GeoStampSigner.embed(plainJpeg(), stamp)),
      PickedPhotoFile('polos.jpg', plainJpeg()),
    ];
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    expect(find.text('1 foto ditolak'), findsOneWidget);
    expect(find.text('polos.jpg'), findsOneWidget);
    expect(find.textContaining('Tidak ada geotag'), findsOneWidget);

    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    final photos = container.read(monitoringFormProvider).photos;
    expect(photos, hasLength(1));
    expect(photos.single.stamp, stamp);
    expect(find.text('1 dari 10 foto'), findsOneWidget);
    expect(find.text('Jalan lingkungan'), findsOneWidget);
  });

  testWidgets('foto yang sama dua kali ditolak sebagai duplikat', (
    tester,
  ) async {
    await pump(tester);
    final bytes = GeoStampSigner.embed(plainJpeg(), stamp);
    picker.files = [PickedPhotoFile('a.jpg', bytes)];
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sudah ada'), findsOneWidget);
    expect(container.read(monitoringFormProvider).photos, hasLength(1));
  });

  testWidgets('hapus foto mengosongkan daftar', (tester) async {
    await pump(tester);
    picker.files = [
      PickedPhotoFile('a.jpg', GeoStampSigner.embed(plainJpeg(), stamp)),
    ];
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Hapus foto 1'));
    await tester.pumpAndSettle();
    expect(container.read(monitoringFormProvider).photos, isEmpty);
    expect(find.textContaining('Belum ada foto'), findsOneWidget);
  });
}
