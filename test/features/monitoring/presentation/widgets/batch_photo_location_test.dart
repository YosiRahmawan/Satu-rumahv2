import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/photo_location_sheet.dart';

const _projectRef = ProjectReference(latitude: -7.3274, longitude: 108.2207);

void main() {
  PhotoLocationResult? result;

  Future<void> openBatchSheet(
    WidgetTester tester, {
    required List<EvidencePhotoItem> photos,
    ProjectReference? reference,
    DeviceLocationResolver? deviceLocationResolver,
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showBatchPhotoLocationSheet(
                    context,
                    photos: photos,
                    reference: reference,
                    deviceLocationResolver: deviceLocationResolver,
                  );
                },
                child: const Text('Buka Batch Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka Batch Sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Sumber 1: GPS perangkat saat ini diterapkan dengan dialog konfirmasi',
    (tester) async {
      final photos = [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
        EvidencePhotoItem.fromPath('p3.jpg'),
      ];

      await openBatchSheet(
        tester,
        photos: photos,
        reference: _projectRef,
        deviceLocationResolver: () async => DeviceFix(
          latitude: -7.3275,
          longitude: 108.2208,
          accuracyMeters: 8.0,
          recordedAt: DateTime(2026, 10, 20),
        ),
      );

      expect(find.text('Atur Lokasi Sekaligus'), findsOneWidget);
      expect(find.textContaining('3 foto terpilih'), findsWidgets);
      expect(find.text('GPS Perangkat'), findsOneWidget);

      // Tekan tombol terapkan
      final applyButton = find.text('Terapkan ke 3 foto terpilih');
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.text('Konfirmasi Lokasi Sekaligus'), findsOneWidget);
      expect(
        find.textContaining('Lokasi ini akan diterapkan ke 3 foto terpilih.'),
        findsOneWidget,
      );

      // Tekan Terapkan pada dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Terapkan'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.cleared, isFalse);
      expect(result!.location!.latitude, closeTo(-7.3275, 1e-6));
      expect(result!.location!.longitude, closeTo(108.2208, 1e-6));
      expect(result!.location!.method, LocationMethod.deviceAtEntry);
      expect(result!.location!.accuracyMeters, 8.0);
    },
  );

  testWidgets('Batal pada dialog konfirmasi tidak menerapkan koordinat', (
    tester,
  ) async {
    final photos = [
      EvidencePhotoItem.fromPath('p1.jpg'),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await openBatchSheet(tester, photos: photos, reference: _projectRef);

    final applyButton = find.text('Terapkan ke 2 foto terpilih');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Lokasi Sekaligus'), findsOneWidget);

    // Tekan Batal
    await tester.tap(find.widgetWithText(TextButton, 'Batal').last);
    await tester.pumpAndSettle();

    // Dialog tertutup tapi sheet tetap terbuka, result belum ada
    expect(find.text('Konfirmasi Lokasi Sekaligus'), findsNothing);
    expect(result, isNull);
  });

  testWidgets('Sumber 2: Titik manual diubah lewat kolom lintang/bujur', (
    tester,
  ) async {
    final photos = [
      EvidencePhotoItem.fromPath('p1.jpg'),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await openBatchSheet(tester, photos: photos, reference: _projectRef);

    // Pilih tab Peta / Manual
    await tester.tap(find.text('Peta / Manual'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-7,3274');
    await tester.enterText(fields.at(1), '108,2207');
    await tester.pumpAndSettle();

    final applyButton = find.text('Terapkan ke 2 foto terpilih');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Terapkan'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.location!.latitude, closeTo(-7.3274, 1e-6));
    expect(result!.location!.longitude, closeTo(108.2207, 1e-6));
    expect(result!.location!.method, LocationMethod.manualPin);
    expect(result!.location!.accuracyMeters, isNull);
  });

  testWidgets('Sumber 3: Metadata GPS foto dipilih jika tersedia', (
    tester,
  ) async {
    final photos = [
      EvidencePhotoItem.fromPath(
        'p1.jpg',
      ).copyWith(exif: const ExifGeo(latitude: -7.3275, longitude: 108.2208)),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await openBatchSheet(tester, photos: photos, reference: _projectRef);

    // Pilih tab Metadata Foto
    await tester.tap(find.text('Metadata Foto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Foto 1'), findsOneWidget);

    final applyButton = find.text('Terapkan ke 2 foto terpilih');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Terapkan'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.location!.latitude, closeTo(-7.3275, 1e-6));
    expect(result!.location!.longitude, closeTo(108.2208, 1e-6));
    expect(result!.location!.method, LocationMethod.exifConfirmed);
  });

  testWidgets('Sumber 3 nonaktif bila foto terpilih tanpa metadata GPS', (
    tester,
  ) async {
    final photos = [
      EvidencePhotoItem.fromPath('p1.jpg'),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await openBatchSheet(tester, photos: photos, reference: _projectRef);

    expect(find.text('Tidak ada EXIF'), findsOneWidget);
  });

  testWidgets(
    'Titik proyek belum tersedia: status validasi jarak belum tersedia',
    (tester) async {
      final photos = [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ];

      await openBatchSheet(
        tester,
        photos: photos,
        reference: null, // Proyek belum tersedia
      );

      expect(find.text('Validasi jarak belum tersedia'), findsOneWidget);
      expect(find.text('Belum tersedia dari Pengembang'), findsOneWidget);
    },
  );

  testWidgets('Di luar toleransi 50m wajib mengisi alasan petugas', (
    tester,
  ) async {
    final photos = [
      EvidencePhotoItem.fromPath('p1.jpg'),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await openBatchSheet(tester, photos: photos, reference: _projectRef);

    // Masukkan koordinat jauh (> 50m)
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '-7.3350');
    await tester.enterText(fields.at(1), '108.2207');
    await tester.pumpAndSettle();

    expect(find.text('Alasan petugas (wajib)'), findsOneWidget);

    // Tombol terapkan harus nonaktif sebelum alasan diisi
    final applyButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Terapkan ke 2 foto terpilih',
    );
    final applyBtn = tester.widget<ElevatedButton>(applyButtonFinder);
    expect(applyBtn.onPressed, isNull);

    // Isi alasan
    final noteField = find.byType(TextField).last;
    await tester.enterText(noteField, 'Foto diambil dari gerbang utama.');
    await tester.pumpAndSettle();

    final applyBtnEnabled = tester.widget<ElevatedButton>(applyButtonFinder);
    expect(applyBtnEnabled.onPressed, isNotNull);

    await tester.ensureVisible(applyButtonFinder);
    await tester.tap(applyButtonFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Terapkan'));
    await tester.pumpAndSettle();

    expect(
      result!.location!.clarificationNote,
      'Foto diambil dari gerbang utama.',
    );
  });

  testWidgets('Batch sheet tersusun tanpa overflow di 320dp dengan teks 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final photos = [
      EvidencePhotoItem.fromPath(
        'p1.jpg',
      ).copyWith(exif: const ExifGeo(latitude: -7.3274, longitude: 108.2207)),
      EvidencePhotoItem.fromPath('p2.jpg'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showBatchPhotoLocationSheet(
                      context,
                      photos: photos,
                      reference: _projectRef,
                    );
                  },
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(find.text('Atur Lokasi Sekaligus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
