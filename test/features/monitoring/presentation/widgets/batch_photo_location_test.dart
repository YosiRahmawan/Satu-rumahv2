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

  Future<void> fill(WidgetTester tester, String lat, String lng) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), lat);
    await tester.enterText(fields.at(1), lng);
    await tester.pumpAndSettle();
  }

  Future<void> tapApply(WidgetTester tester, int count) async {
    final button = find.text('Terapkan ke $count foto');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan judul, tanpa pilihan GPS perangkat', (tester) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
        EvidencePhotoItem.fromPath('p3.jpg'),
      ],
      reference: _projectRef,
    );

    expect(find.text('Atur lokasi 3 foto'), findsOneWidget);
    expect(find.textContaining('GPS Perangkat'), findsNothing);
    expect(find.textContaining('GPS perangkat'), findsNothing);
    // Tidak ada koordinat yang terisi sendiri.
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Terapkan ke 3 foto'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('titik manual diterapkan tanpa dialog bila belum ada lokasi', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ],
      reference: _projectRef,
    );

    await fill(tester, '-7,3274', '108,2207');
    await tapApply(tester, 2);

    expect(result, isNotNull);
    expect(result!.cleared, isFalse);
    expect(result!.location!.latitude, closeTo(-7.3274, 1e-6));
    expect(result!.location!.longitude, closeTo(108.2207, 1e-6));
    expect(result!.location!.method, LocationMethod.manualPin);
    expect(result!.location!.accuracyMeters, isNull);
  });

  testWidgets('mengganti lokasi yang sudah ada meminta konfirmasi', (
    tester,
  ) async {
    final located = EvidencePhotoItem.fromPath('p1.jpg').copyWith(
      location: OfficerLocation(
        latitude: -7.33,
        longitude: 108.22,
        method: LocationMethod.manualPin,
        selectedAt: DateTime(2026, 10, 20),
      ),
    );
    await openBatchSheet(
      tester,
      photos: [located, EvidencePhotoItem.fromPath('p2.jpg')],
      reference: _projectRef,
    );

    await fill(tester, '-7.3274', '108.2207');
    await tapApply(tester, 2);

    expect(find.text('Ganti lokasi yang sudah ada?'), findsOneWidget);
    expect(find.textContaining('1 dari 2 foto sudah punya lokasi'), findsOne);

    // Batal: sheet tetap terbuka, belum ada hasil.
    await tester.tap(find.widgetWithText(TextButton, 'Batal').last);
    await tester.pumpAndSettle();
    expect(find.text('Ganti lokasi yang sudah ada?'), findsNothing);
    expect(result, isNull);

    await tapApply(tester, 2);
    await tester.tap(find.widgetWithText(FilledButton, 'Ganti'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.location!.latitude, closeTo(-7.3274, 1e-6));
  });

  testWidgets('GPS foto dipilih lewat sumber "Dari foto" dan dikonfirmasi', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath(
          'p1.jpg',
        ).copyWith(exif: const ExifGeo(latitude: -7.3275, longitude: 108.2208)),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ],
      reference: _projectRef,
    );

    await tester.tap(find.text('Dari foto'));
    await tester.pumpAndSettle();
    expect(
      find.text('GPS tertanam di foto (belum diverifikasi)'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Gunakan koordinat foto'));
    await tester.tap(find.text('Gunakan koordinat foto'));
    await tester.pumpAndSettle();
    await tapApply(tester, 2);

    expect(result, isNotNull);
    expect(result!.location!.latitude, closeTo(-7.3275, 1e-6));
    expect(result!.location!.longitude, closeTo(108.2208, 1e-6));
    expect(result!.location!.method, LocationMethod.exifConfirmed);
  });

  testWidgets('beberapa foto ber-GPS: petugas memilih foto sumber', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath(
          'p1.jpg',
        ).copyWith(exif: const ExifGeo(latitude: -7.30, longitude: 108.20)),
        EvidencePhotoItem.fromPath(
          'p2.jpg',
        ).copyWith(exif: const ExifGeo(latitude: -7.31, longitude: 108.21)),
      ],
      reference: null,
    );

    await tester.tap(find.text('Dari foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto 2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gunakan koordinat foto'));
    await tester.tap(find.text('Gunakan koordinat foto'));
    await tester.pumpAndSettle();
    await tapApply(tester, 2);

    expect(result!.location!.latitude, closeTo(-7.31, 1e-6));
  });

  testWidgets('tanpa metadata GPS pada foto terpilih: sumber foto tidak ada', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ],
      reference: _projectRef,
    );

    expect(find.text('Dari foto'), findsNothing);
  });

  testWidgets('titik proyek belum tersedia: jarak dinyatakan tidak dihitung', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ],
      reference: null,
    );

    expect(
      find.text('Tidak dihitung: titik proyek belum tersedia'),
      findsOneWidget,
    );
  });

  testWidgets('di luar toleransi 50 m wajib mengisi alasan petugas', (
    tester,
  ) async {
    await openBatchSheet(
      tester,
      photos: [
        EvidencePhotoItem.fromPath('p1.jpg'),
        EvidencePhotoItem.fromPath('p2.jpg'),
      ],
      reference: _projectRef,
    );

    await fill(tester, '-7.3350', '108.2207');
    expect(find.text('Alasan petugas (wajib)'), findsOneWidget);

    final applyFinder = find.widgetWithText(
      ElevatedButton,
      'Terapkan ke 2 foto',
    );
    expect(tester.widget<ElevatedButton>(applyFinder).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField).last,
      'Foto diambil dari gerbang utama.',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(applyFinder).onPressed, isNotNull);

    await tapApply(tester, 2);
    expect(
      result!.location!.clarificationNote,
      'Foto diambil dari gerbang utama.',
    );
  });

  testWidgets('tersusun tanpa overflow di 320dp dengan teks 200%', (
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

    expect(find.text('Atur lokasi 2 foto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
