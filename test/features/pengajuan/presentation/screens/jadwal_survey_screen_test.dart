import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/app_housing_loader.dart';
import 'package:satu_rumah/features/pengajuan/data/models/hasil_survey_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/jadwal_survey_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/survey_not_found_illustration.dart';

void main() {
  group('JadwalSurveyScreen Targeted Tests', () {
    final mockSubmissions = [
      Pengajuan(
        id: 'SR-2025-0147',
        namaPerumahan: 'Kencana Kawalu Regency',
        namaPt: 'PT Sukapura Mandiri Properti',
        namaDirektur: 'Dedi Setiadi, S.T.',
        npwpPerusahaan: '08.234.567.8-423.000',
        luasLahan: 18500.0,
        jumlahUnit: 85,
        tipePerumahan: 'Subsidi',
        status: 'Terjadwal',
        statusTahap: StatusTahapPengajuan.surveyLapangan,
        tanggal: '12 Mei 2025 · 15.20 WIB',
        tanggalSurvey: DateTime(2025, 5, 20, 9, 0),
        catatanSurvey:
            'Jadwal survey lokasi telah dikonfirmasi untuk tanggal 20 Mei 2025. Titik kumpul Kantor Pemasaran Kawalu.',
        uploadedDocs: const {},
      ),
      Pengajuan(
        id: 'SR-2025-0146',
        namaPerumahan: 'Pesona Cibeureum Pratama',
        namaPt: 'PT Priangan Griya Graha',
        namaDirektur: 'Ir. Tatan Rustandi',
        npwpPerusahaan: '07.345.678.9-423.000',
        luasLahan: 26000.0,
        jumlahUnit: 120,
        tipePerumahan: 'Subsidi',
        status: 'Menunggu verifikasi',
        statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
        tanggal: '12 Mei 2025',
        uploadedDocs: const {},
      ),
      Pengajuan(
        id: 'REG-2026-0038',
        namaPerumahan: 'Grand Tasik Harmoni',
        namaPt: 'PT. Tasik Indah Sentosa',
        namaDirektur: 'H. Rahmat Hidayat, S.T.',
        npwpPerusahaan: '01.345.678.9-425.000',
        luasLahan: 12000.0,
        jumlahUnit: 85,
        tipePengajuan: 'Pengajuan Site Plan Baru',
        tipePerumahan: 'Komersil',
        status: 'Disetujui',
        statusTahap: StatusTahapPengajuan.selesai,
        tanggal: '28 Agu 2026',
        uploadedDocs: const {},
        riwayatSurvey: [
          HasilSurveyItem(
            id: 'srv-01',
            tanggalSurvey: DateTime(2026, 8, 20, 10, 0),
            pelaksanaNama: 'H. Rahmat Hidayat, S.T.',
            pelaksanaJabatan: 'Tim Perwaskim',
            lokasiPerumahan: 'Grand Tasik Harmoni',
            statusHasilEvaluasi: 'perlu_perbaikan',
            temuanLapangan: const ['Drainase perimeter belum dibuat'],
            photoPaths: const ['photo1.jpg'],
            isDraft: false,
          ),
        ],
      ),
    ];

    Widget createWidgetUnderTest(
      WidgetTester tester, {
      double width = 390,
      double height = 844,
      List<Override> overrides = const [],
    }) {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 44, bottom: 34),
            ),
            child: const JadwalSurveyScreen(),
          ),
        ),
      );
    }

    Finder findFilterPill(String label) {
      return find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
    }

    testWidgets('1. Loading -> Data Available transition', (tester) async {
      final completer = Completer<List<Pengajuan>>();
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(AppHousingLoader), findsOneWidget);
      expect(find.text('Memuat jadwal survey...'), findsOneWidget);
      expect(find.text('Mohon tunggu sebentar.'), findsOneWidget);

      completer.complete(mockSubmissions);
      await tester.pumpAndSettle();

      expect(find.byType(AppHousingLoader), findsNothing);
      expect(find.text('Kencana Kawalu Regency'), findsOneWidget);
      expect(find.text('Pesona Cibeureum Pratama'), findsOneWidget);
    });

    testWidgets('2. Loading -> Empty transition', (tester) async {
      final completer = Completer<List<Pengajuan>>();
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(AppHousingLoader), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byType(AppHousingLoader), findsNothing);
      expect(find.text('Belum Ada Jadwal Survey'), findsOneWidget);
      expect(
        find.text(
          'Jadwal survey untuk pengajuan Anda akan ditampilkan di sini setelah tersedia.',
        ),
        findsOneWidget,
      );
      expect(find.text('Periksa Status Pengajuan'), findsOneWidget);
    });

    testWidgets('3. Loading -> Error transition', (tester) async {
      final completer = Completer<List<Pengajuan>>();
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(AppHousingLoader), findsOneWidget);

      completer.completeError(Exception('Network Error'));
      await tester.pumpAndSettle();

      expect(find.byType(AppHousingLoader), findsNothing);
      expect(find.text('Gagal Memuat Jadwal Survey'), findsOneWidget);
      expect(
        find.text(
          'Jadwal survey belum dapat ditampilkan. Silakan coba kembali.',
        ),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('4. Error -> Retry -> Success flow', (tester) async {
      bool returnError = true;
      final container = ProviderContainer(
        overrides: [
          jadwalSurveyListProvider.overrideWith((ref) {
            if (returnError) {
              return Future<List<Pengajuan>>.error(
                Exception('Gagal terhubung'),
              );
            }
            return Future.value(mockSubmissions);
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: JadwalSurveyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Jadwal Survey'), findsOneWidget);

      // Now set returnError = false and tap Coba Lagi
      returnError = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Jadwal Survey'), findsNothing);
      expect(find.text('Kencana Kawalu Regency'), findsOneWidget);
    });

    testWidgets('5. Search dengan hasil kosong (Search Not Found)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value(mockSubmissions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Perumahan Fiktif');
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Tidak Ditemukan'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada jadwal survey yang sesuai dengan filter atau kata kunci pencarian Anda.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);
    });

    testWidgets('6. Reset Filter mengembalikan kondisi default', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value(mockSubmissions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Tidak Ada');
      await tester.pumpAndSettle();
      expect(find.text('Jadwal Tidak Ditemukan'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset Filter'));
      await tester.tap(find.text('Reset Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Kencana Kawalu Regency'), findsOneWidget);
      expect(find.text('Pesona Cibeureum Pratama'), findsOneWidget);
    });

    testWidgets('7. Kombinasi search dan status filter', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          height: 1200,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value(mockSubmissions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap filter "Selesai"
      await tester.ensureVisible(findFilterPill('Selesai'));
      await tester.tap(findFilterPill('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Grand Tasik Harmoni'), findsOneWidget);
      expect(find.text('Kencana Kawalu Regency'), findsNothing);

      // Search keyword matching Grand Tasik
      await tester.enterText(find.byType(TextField), 'Grand');
      await tester.pumpAndSettle();
      expect(find.text('Grand Tasik Harmoni'), findsOneWidget);

      // Search keyword not matching Grand Tasik in 'Selesai'
      await tester.enterText(find.byType(TextField), 'Kencana');
      await tester.pumpAndSettle();
      expect(find.text('Jadwal Tidak Ditemukan'), findsOneWidget);
    });

    testWidgets('8. Housing Loader berhenti setelah proses selesai', (
      tester,
    ) async {
      final completer = Completer<List<Pengajuan>>();
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          overrides: [
            jadwalSurveyListProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(AppHousingLoader), findsOneWidget);

      completer.complete(mockSubmissions);
      await tester.pumpAndSettle();
      expect(find.byType(AppHousingLoader), findsNothing);
    });

    testWidgets('9. Status evaluasi hanya tampil jika didukung data', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          height: 1200,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value(mockSubmissions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Grand Tasik Harmoni has HasilSurveyItem with statusHasilEvaluasi: 'perlu_perbaikan'
      expect(find.text('Hasil Monitoring: Perlu Perbaikan'), findsOneWidget);
      expect(find.text('Drainase perimeter belum dibuat'), findsOneWidget);

      // Kencana & Pesona do not have perlu_perbaikan status
      expect(find.text('Hasil Monitoring: Sesuai'), findsNothing);
    });

    testWidgets('9b. Progres monitoring dan hasil BA tampil untuk Pengembang', (
      tester,
    ) async {
      final selesai = Pengajuan(
        id: 'SR-2026-0001',
        namaPerumahan: 'Griya Uji',
        namaPt: 'PT Uji',
        namaDirektur: 'D',
        npwpPerusahaan: '1',
        luasLahan: 1,
        jumlahUnit: 1,
        tipePerumahan: 'Subsidi',
        status: 'Dalam Proses',
        statusTahap: StatusTahapPengajuan.persetujuan,
        tanggal: '2 Nov 2026',
        tanggalSurvey: DateTime(2026, 11, 2),
        uploadedDocs: const {},
        riwayatSurvey: [
          HasilSurveyItem(
            id: '9',
            tanggalSurvey: DateTime(2026, 11, 2),
            pelaksanaNama: 'Ketua Satu',
            pelaksanaJabatan: 'Ketua Tim',
            lokasiPerumahan: 'Griya Uji',
            statusHasilEvaluasi: 'sesuai',
            kesimpulan: const ['Pelaksanaan sesuai site plan'],
            rencanaTindakLanjut: const ['Rapikan saluran'],
            nomorSuratBA: '600.2.5/BA-MON/XI/2026/001',
          ),
        ],
      );
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          height: 1400,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value([selesai]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dijadwalkan'), findsWidgets);
      expect(find.text('Survei dilaksanakan'), findsOneWidget);
      expect(find.text('Hasil terbit'), findsOneWidget);
      expect(find.text('Hasil Monitoring: Sesuai'), findsOneWidget);
      expect(find.text('BA 600.2.5/BA-MON/XI/2026/001'), findsOneWidget);
      expect(find.text('Pelaksanaan sesuai site plan'), findsOneWidget);
      expect(find.text('• Rapikan saluran'), findsOneWidget);
    });

    testWidgets('10. Navigasi ke Detail Pengajuan', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          tester,
          height: 1200,
          overrides: [
            jadwalSurveyListProvider.overrideWith(
              (ref) => Future.value(mockSubmissions),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final detailAction = find.text('Lihat Detail Pengajuan').first;
      await tester.ensureVisible(detailAction);
      expect(detailAction, findsOneWidget);

      await tester.tap(detailAction);
      await tester.pump();
      // Verifies tap doesn't throw
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. Tidak ada overflow pada 360dp, 390dp, 412dp', (
      tester,
    ) async {
      for (final w in [360.0, 390.0, 412.0]) {
        await tester.pumpWidget(
          createWidgetUnderTest(
            tester,
            width: w,
            height: 800,
            overrides: [
              jadwalSurveyListProvider.overrideWith(
                (ref) => Future.value(mockSubmissions),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Jadwal Survey'), findsOneWidget);
        expect(find.text('Kencana Kawalu Regency'), findsOneWidget);
      }
    });
  });
}
