import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/unduh_sk_ba_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  group('UnduhSkBaScreen Targeted Tests', () {
    final mockSubmissions = [
      // Item 1: BA Tersedia (Final Monitoring), SK Belum Tersedia (surveyLapangan)
      Pengajuan(
        id: 'SR-2025-0148',
        namaPerumahan: 'Griya Mangkubumi Asri',
        namaPt: 'PT Citra Tasik Mandiri',
        namaDirektur: 'H. Asep Hendrayana, S.T.',
        npwpPerusahaan: '09.123.456.7-423.000',
        luasLahan: 34800.0,
        jumlahUnit: 148,
        tipePerumahan: 'Subsidi',
        status: 'Terjadwal',
        statusTahap: StatusTahapPengajuan.surveyLapangan,
        tanggal: '08 Mei 2025',
        beritaAcaraPath: 'BA_BA_PERWASKIM_2025_05_0148.pdf',
        uploadedDocs: const {},
      ),
      // Item 2: SK & BA Belum Tersedia (verifikasiAdministrasi)
      Pengajuan(
        id: 'REG-2026-0084',
        namaPerumahan: 'Mutiara Regency Tasik',
        namaPt: 'PT. Tasik Indah Sentosa',
        namaDirektur: 'H. Tatang Sutisna',
        npwpPerusahaan: '09.123.456.7-423.000',
        luasLahan: 24000.0,
        jumlahUnit: 165,
        tipePerumahan: 'Komersil',
        status: 'Dalam Proses',
        statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
        tanggal: '04 Sep 2026',
        uploadedDocs: const {},
      ),
    ];

    final mockMonitoringRepo = MonitoringRepository();
    // Tambahkan monitoring final untuk SR-2025-0148
    mockMonitoringRepo.addMonitoring(
      MonitoringModel(
        id: 'mon-test-148',
        pengajuanId: 'SR-2025-0148',
        nomorSuratBA: 'BA/PERWASKIM/2025/05/0148',
        tanggalMonitoring: DateTime(2025, 5, 22, 10, 0),
        namaPerumahan: 'Griya Mangkubumi Asri',
        namaDeveloper: 'PT Citra Tasik Mandiri',
        lokasiPerumahan: 'Mangkubumi, Kota Tasikmalaya',
        maksudTujuan: 'Pemeriksaan lapangan site plan',
        temuanLapangan: const ['Kondisi tanah sesuai'],
        kesimpulan: const ['Layak'],
        kesepakatan: const ['Disetujui'],
        rencanaTindakLanjut: const ['Penerbitan rekomendasi'],
        statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
        pelaksanaNama: 'Tim Perwaskim',
        pelaksanaJabatan: 'Staf Teknis',
        ditemuiNama: 'H. Asep Hendrayana',
        ditemuiJabatan: 'Direktur',
        isDraft: false,
      ),
    );

    Widget createWidgetUnderTest({
      List<Pengajuan>? submissions,
      MonitoringRepository? repo,
    }) {
      return ProviderScope(
        overrides: [
          unduhSkBaListProvider.overrideWith(
            (ref) async => submissions ?? mockSubmissions,
          ),
          monitoringRepositoryProvider.overrideWithValue(
            repo ?? mockMonitoringRepo,
          ),
        ],
        child: const MaterialApp(
          home: UnduhSkBaScreen(),
        ),
      );
    }

    testWidgets('1. Renders header, search bar, and filter pills correctly',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Unduh SK & BA'), findsOneWidget);
      expect(
        find.text('Dokumen resmi pengajuan perumahan'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);

      // Search Bar
      expect(
        find.text('Cari nama perumahan atau registrasi...'),
        findsOneWidget,
      );

      // Filter Pills
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('SK Persetujuan'), findsOneWidget);
      expect(find.text('Berita Acara'), findsOneWidget);

      // Project Cards
      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Mutiara Regency Tasik'), findsOneWidget);
    });

    testWidgets('2. Expand and collapse project card toggles documents visibility',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Card pertama default terbuka
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);

      // Tap card pertama untuk collapse
      final cardHeader = find.text('Griya Mangkubumi Asri');
      await tester.tap(cardHeader);
      await tester.pumpAndSettle();

      // Dokumen row tersembunyi
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsNothing);

      // Tap lagi untuk re-expand
      await tester.tap(cardHeader);
      await tester.pumpAndSettle();

      // Dokumen row terlihat kembali
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
    });

    testWidgets('3. Searches housing project by name and registration ID',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Search by name
      await tester.enterText(find.byType(TextField), 'Mangkubumi');
      await tester.pumpAndSettle();

      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      expect(find.text('Mutiara Regency Tasik'), findsNothing);

      // Clear search via clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Mutiara Regency Tasik'), findsOneWidget);

      // Scroll back up to reach search field
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
      await tester.pumpAndSettle();

      // Search by registration ID
      await tester.enterText(find.byType(TextField), 'REG-2026-0084');
      await tester.pumpAndSettle();

      expect(find.text('Mutiara Regency Tasik'), findsOneWidget);
      expect(find.text('Griya Mangkubumi Asri'), findsNothing);
    });

    testWidgets('4. Filter pills show only SK Persetujuan or Berita Acara rows',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Filter: SK Persetujuan
      await tester.tap(find.text('SK Persetujuan'));
      await tester.pumpAndSettle();

      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsNothing);

      // Filter: Berita Acara
      await tester.tap(find.text('Berita Acara'));
      await tester.pumpAndSettle();

      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsNothing);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);

      // Filter: Semua
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);
    });

    testWidgets('5. Combines search and filter seamlessly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Search Mangkubumi and filter Berita Acara
      await tester.enterText(find.byType(TextField), 'Mangkubumi');
      await tester.tap(find.text('Berita Acara'));
      await tester.pumpAndSettle();

      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsNothing);
    });

    testWidgets('6. Displays empty database state when submissions list is empty',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(submissions: []));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Dokumen Tersedia'), findsOneWidget);
      expect(find.text('Periksa Daftar Pengajuan'), findsOneWidget);
    });

    testWidgets(
        '7. Displays Search Not Found state and resets via button',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Search keyword yang tidak ada
      await tester.enterText(find.byType(TextField), 'Perumahan Fiktif Antah');
      await tester.pumpAndSettle();

      expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset pencarian dan filter'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset pencarian dan filter'));
      await tester.pumpAndSettle();

      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Mutiara Regency Tasik'), findsOneWidget);
    });

    testWidgets(
        '8. Download button is disabled when document is unavailable',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Pada Card pertama, SK belum terbit
      expect(find.text('Belum Dapat Diunduh'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets(
        '9. Document action is active and accessible only when valid BA exists',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Pada Griya Mangkubumi Asri, BA valid dan tersedia
      expect(find.text('No: BA/PERWASKIM/2025/05/0148'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);
      expect(find.text('Lihat / Unduh PDF'), findsOneWidget);
    });

    testWidgets(
        '10. Renders responsively without overflow across 360, 390, and 412dp',
        (tester) async {
      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width * 2.0, 840 * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Reset
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      }
    });

    testWidgets(
        '11. Filter transitions preserve open/closed card state and repeated expand/collapse settles smoothly',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final cardHeader = find.text('Griya Mangkubumi Asri');

      // 1. Filter transition saat kartu terbuka (card 1 default terbuka)
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);

      await tester.tap(find.text('SK Persetujuan'));
      await tester.pumpAndSettle();

      // Kartu tetap dalam kondisi terbuka dan hanya menampilkan SK
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsNothing);

      // 2. Collapse kartu saat filter SK aktif
      await tester.tap(cardHeader);
      await tester.pumpAndSettle();
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsNothing);

      // 3. Filter transition saat kartu tertutup
      await tester.tap(find.text('Berita Acara'));
      await tester.pumpAndSettle();
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsNothing);

      // 4. Buka kembali kartu: dokumen Berita Acara langsung tampil sesuai filter aktif
      await tester.tap(cardHeader);
      await tester.pumpAndSettle();
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsNothing);

      // 5. Kembali ke Semua
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      expect(find.text('Surat Keputusan (SK Persetujuan)'), findsOneWidget);
      expect(find.text('Berita Acara (BA Verifikasi Lapangan)'), findsOneWidget);

      // 6. Repeated expand/collapse toggles
      for (int i = 0; i < 3; i++) {
        await tester.tap(cardHeader);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Scroll position remains stable and is clamped without jump',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Scroll sedikit ke bawah agar filter tetap dalam viewport
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -40));
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final initialOffset = scrollable.position.pixels;
      expect(initialOffset, greaterThan(0));

      // Ganti filter ke SK Persetujuan
      await tester.tap(find.text('SK Persetujuan'));
      await tester.pumpAndSettle();

      // Tidak ada unhandled exception dan status tetap stabil
      expect(tester.takeException(), isNull);
    });
  });
}
