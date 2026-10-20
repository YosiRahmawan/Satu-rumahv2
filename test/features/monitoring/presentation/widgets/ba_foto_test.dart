import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/berita_acara_document_card.dart';
import 'package:satu_rumah/features/monitoring/utils/ba_pdf_generator.dart';

import '../../../../support/camera_fakes.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id', null));
  setUp(PhotoBytesCache.clear);

  MonitoringModel report(List<ReportPhoto> photos) => MonitoringModel(
    id: 'ba-foto',
    tanggalMonitoring: DateTime(2026, 10, 20),
    namaPerumahan: 'Perumahan Uji',
    temuanLapangan: const ['Temuan'],
    photos: photos,
  );

  ReportPhoto photo(String note, {bool bytes = true}) {
    final p = ReportPhoto.create(
      source: PhotoSource.camera,
      stamp: GeoStamp(
        latitude: -7.3274,
        longitude: 108.2207,
        accuracyMeters: 8,
        capturedAt: DateTime(2026, 10, 20, 9, 30, 15),
        address: 'Jl. Contoh No. 1, Tasikmalaya',
        note: note,
      ),
    );
    if (bytes) PhotoBytesCache.put(p.id, plainJpeg());
    return p;
  }

  testWidgets('kartu BA memuat bagian dokumentasi dengan keterangan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BeritaAcaraDocumentCard(
              monitoring: report([photo('Drainase'), photo('Gerbang')]),
            ),
          ),
        ),
      ),
    );
    expect(find.text('V. Dokumentasi Lapangan'), findsOneWidget);
    expect(find.text('Foto 1 · Drainase'), findsOneWidget);
    expect(find.text('Foto 2 · Gerbang'), findsOneWidget);
    expect(find.textContaining('-7.327400, 108.220700'), findsNWidgets(2));
    expect(find.textContaining('Jl. Contoh No. 1'), findsNWidgets(2));
  });

  testWidgets('tanpa foto, bagian dokumentasi tidak muncul', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BeritaAcaraDocumentCard(monitoring: report(const [])),
          ),
        ),
      ),
    );
    expect(find.text('V. Dokumentasi Lapangan'), findsNothing);
  });

  test(
    'PDF BA dengan foto tersusun dan lebih besar daripada tanpa foto',
    () async {
      final plain = await BaPdfGenerator.buildDocument(report(const [])).save();
      final withPhotos = await BaPdfGenerator.buildDocument(
        report([photo('A'), photo('B'), photo('C', bytes: false)]),
      ).save();
      expect(withPhotos.length, greaterThan(plain.length));
    },
  );
}
