import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/photo_location_sheet.dart';

const _project = ProjectReference(latitude: -7.3274, longitude: 108.2207);

void main() {
  PhotoLocationResult? result;
  var closed = false;

  Future<void> open(
    WidgetTester tester,
    EvidencePhotoItem photo, {
    ProjectReference? reference,
  }) async {
    result = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showPhotoLocationSheet(
                    context,
                    photo: photo,
                    photoNumber: 2,
                    reference: reference,
                  );
                  closed = true;
                },
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String lat, String lng) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), lat);
    await tester.enterText(fields.at(1), lng);
    await tester.pumpAndSettle();
  }

  ElevatedButton saveButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Simpan lokasi'),
      );

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Simpan lokasi'));
    await tester.tap(find.text('Simpan lokasi'));
    await tester.pumpAndSettle();
  }

  OfficerLocation pin(double lat, double lng) => OfficerLocation(
    latitude: lat,
    longitude: lng,
    method: LocationMethod.manualPin,
    selectedAt: DateTime(2026, 10, 20),
  );

  testWidgets('tanpa koordinat tombol simpan nonaktif, koma desimal diterima', (
    tester,
  ) async {
    await open(tester, EvidencePhotoItem.fromPath('a.jpg'));
    expect(find.text('Lokasi Foto 2'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await fill(tester, '-7,3274', '108,2207');
    expect(saveButton(tester).onPressed, isNotNull);
    expect(find.text('Tidak dapat dihitung'), findsOneWidget);
    expect(find.text('Belum tersedia dari Pengembang'), findsOneWidget);

    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(result!.cleared, isFalse);
    expect(result!.location!.latitude, closeTo(-7.3274, 1e-9));
    expect(result!.location!.longitude, closeTo(108.2207, 1e-9));
    expect(result!.location!.method, LocationMethod.manualPin);
    expect(result!.location!.clarificationNote, isNull);
  });

  testWidgets(
    'koordinat di luar rentang menampilkan pesan dan tak bisa simpan',
    (tester) async {
      await open(tester, EvidencePhotoItem.fromPath('a.jpg'));
      await fill(tester, '-95', '108');
      expect(find.text('Antara -90 dan 90'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'di luar toleransi wajib alasan; dalam toleransi alasan tak disimpan',
    (tester) async {
      await open(
        tester,
        EvidencePhotoItem.fromPath('a.jpg'),
        reference: _project,
      );
      await fill(tester, '-7.3290', '108.2207');
      expect(find.text('Alasan petugas (wajib)'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, 'Dari jalan akses');
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNotNull);

      // Kembali ke titik dekat proyek: kolom alasan hilang, catatan dibuang.
      await fill(tester, '-7.32745', '108.2207');
      expect(find.text('Alasan petugas (wajib)'), findsNothing);
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(result!.location!.clarificationNote, isNull);
    },
  );

  testWidgets('di luar toleransi menyimpan alasan petugas', (tester) async {
    await open(
      tester,
      EvidencePhotoItem.fromPath('a.jpg'),
      reference: _project,
    );
    await fill(tester, '-7.3290', '108.2207');
    await tester.enterText(find.byType(TextField).last, 'Dari jalan akses');
    await tester.pumpAndSettle();
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(result!.location!.clarificationNote, 'Dari jalan akses');
  });

  testWidgets('GPS tertanam baru dipakai setelah petugas menekan tombolnya', (
    tester,
  ) async {
    final photo = EvidencePhotoItem.fromPath(
      'a.jpg',
    ).copyWith(exif: const ExifGeo(latitude: -7.33, longitude: 108.22));
    await open(tester, photo);
    expect(
      find.text('GPS tertanam di foto (belum diverifikasi)'),
      findsOneWidget,
    );
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('Gunakan koordinat foto'));
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNotNull);
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(result!.location!.method, LocationMethod.exifConfirmed);
    expect(result!.location!.latitude, closeTo(-7.33, 1e-9));
  });

  testWidgets('mengubah koordinat EXIF menjadikan sumber penunjukan manual', (
    tester,
  ) async {
    final photo = EvidencePhotoItem.fromPath(
      'a.jpg',
    ).copyWith(exif: const ExifGeo(latitude: -7.33, longitude: 108.22));
    await open(tester, photo);
    await tester.tap(find.text('Gunakan koordinat foto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '-7.331');
    await tester.pumpAndSettle();
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(result!.location!.method, LocationMethod.manualPin);
  });

  testWidgets('lokasi yang ada dapat dihapus', (tester) async {
    final photo = EvidencePhotoItem.fromPath(
      'a.jpg',
    ).copyWith(location: pin(-7.3274, 108.2207));
    await open(tester, photo);
    await tester.tap(find.text('Hapus lokasi'));
    await tester.pumpAndSettle();
    expect(result!.cleared, isTrue);
  });

  testWidgets('Batal menutup tanpa hasil', (tester) async {
    await open(tester, EvidencePhotoItem.fromPath('a.jpg'));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('tersusun tanpa overflow di 320dp dengan teks 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final photo = EvidencePhotoItem.fromPath(
      'a.jpg',
    ).copyWith(exif: const ExifGeo(latitude: -7.33, longitude: 108.22));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: PhotoLocationSheet(
            photo: photo,
            photoNumber: 1,
            reference: _project,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
