import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/project_reference_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/berita_acara_document_card.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/monitoring_photo_gallery.dart';
import 'package:satu_rumah/features/monitoring/utils/ba_pdf_generator.dart';

/// PNG 1x1 yang valid.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

OfficerLocation _loc(double lat, {String? note}) => OfficerLocation(
  latitude: lat,
  longitude: 108.2207,
  method: LocationMethod.manualPin,
  selectedAt: DateTime(2026, 10, 20),
  clarificationNote: note,
);

MonitoringModel _model(List<EvidencePhotoItem> photos) => MonitoringModel(
  id: 'm-foto',
  pengajuanId: 'SR-2025-0148',
  tanggalMonitoring: DateTime(2026, 10, 20),
  namaPerumahan: 'Perumahan Uji',
  temuanLapangan: const ['Temuan'],
  photos: photos,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ProjectReference? reference,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (reference != null)
          projectReferenceProvider.overrideWith((ref, id) => reference),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(PhotoBytesCache.clear);

  testWidgets('menampilkan lokasi, sumber, jarak, dan GPS foto per foto', (
    tester,
  ) async {
    PhotoBytesCache.put('a.png', _png);
    final model = _model([
      EvidencePhotoItem.fromPath('a.png').copyWith(
        location: _loc(-7.32745),
        exif: const ExifGeo(latitude: -7.3, longitude: 108.2),
      ),
      EvidencePhotoItem.fromPath('b.png'),
    ]);
    await _pump(tester, MonitoringPhotoGallery(monitoring: model));

    expect(find.text('Foto 1'), findsOneWidget);
    expect(find.text('Lokasi: -7.327450, 108.220700'), findsOneWidget);
    expect(find.text('Sumber: Penunjukan manual'), findsOneWidget);
    expect(
      find.text(
        'Jarak ke proyek: tidak dihitung (titik proyek belum tersedia)',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'GPS tertanam di foto: -7.300000, 108.200000 (tidak diverifikasi)',
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);

    expect(find.text('Foto 2'), findsOneWidget);
    expect(find.text('Lokasi: belum ditentukan'), findsOneWidget);
    expect(find.text('Tidak tersedia'), findsOneWidget);
  });

  testWidgets('di luar batas awal: jarak dan alasan petugas terlihat', (
    tester,
  ) async {
    final model = _model([
      EvidencePhotoItem.fromPath(
        'a.png',
      ).copyWith(location: _loc(-7.3350, note: 'Dari gerbang utama')),
    ]);
    await _pump(
      tester,
      MonitoringPhotoGallery(monitoring: model),
      reference: const ProjectReference(latitude: -7.3274, longitude: 108.2207),
    );

    expect(find.textContaining('di luar batas awal 50 m'), findsOneWidget);
    expect(find.text('Alasan petugas: Dari gerbang utama'), findsOneWidget);
  });

  testWidgets('foto yang perlu dipilih ulang tampil sebagai tidak tersimpan', (
    tester,
  ) async {
    final model = _model([
      EvidencePhotoItem.fromPath(
        'a.png',
      ).copyWith(location: _loc(-7.3274), needsReselect: true),
    ]);
    await _pump(tester, MonitoringPhotoGallery(monitoring: model));

    expect(find.text('Tidak tersimpan'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('kartu Berita Acara memuat galeri berlokasi', (tester) async {
    PhotoBytesCache.put('a.png', _png);
    final model = _model([
      EvidencePhotoItem.fromPath('a.png').copyWith(location: _loc(-7.3274)),
    ]);
    await _pump(tester, BeritaAcaraDocumentCard(monitoring: model));

    expect(find.text('Dokumentasi Foto Lapangan'), findsOneWidget);
    expect(find.text('Lokasi: -7.327400, 108.220700'), findsOneWidget);
  });

  testWidgets('kartu Berita Acara tanpa foto tidak menampilkan bagian foto', (
    tester,
  ) async {
    await _pump(tester, BeritaAcaraDocumentCard(monitoring: _model(const [])));
    expect(find.text('Dokumentasi Foto Lapangan'), findsNothing);
  });

  group('PDF BA', () {
    test(
      'menyisipkan foto JPEG/PNG dan tetap jujur untuk yang tidak bisa',
      () async {
        PhotoBytesCache.put('a.png', _png);
        PhotoBytesCache.put(
          'w.webp',
          Uint8List.fromList([
            0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, //
            0, 0, 0, 0,
          ]),
        );
        final model = _model([
          EvidencePhotoItem.fromPath('a.png').copyWith(location: _loc(-7.3274)),
          EvidencePhotoItem.fromPath('w.webp'),
          EvidencePhotoItem.fromPath('hilang.jpg'),
        ]);

        final bytes = await BaPdfGenerator.buildDocument(model).save();

        expect(bytes.length, greaterThan(1000));
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      },
    );

    test('tanpa foto, dokumen tetap dibuat', () async {
      final bytes = await BaPdfGenerator.buildDocument(_model(const [])).save();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
