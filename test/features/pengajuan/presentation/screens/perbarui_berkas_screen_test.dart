import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/perbarui_berkas_screen.dart';

void main() {
  Widget buildTestWidget({
    String id = 'REG-2026-0142',
    double textScale = 1.0,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: PerbaruiBerkasScreen(id: id),
      ),
    );
  }

  group('PerbaruiBerkasScreen Tests', () {
    testWidgets('renders header and project pill correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Perbarui Berkas'), findsWidgets);
      expect(find.textContaining('REG-2026-0142'), findsOneWidget);
      expect(find.textContaining('Perumahan Green Tasik'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders progress card with 1/3 Berkas initial progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Berkas yang sudah diperbarui'), findsOneWidget);
      expect(find.text('1/3 Berkas'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.text('Perbarui semua berkas yang ditandai sebelum mengirim'),
        findsOneWidget,
      );
    });

    testWidgets('renders CATATAN DARI ADMIN VERIFIKATOR warning box', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CATATAN DARI ADMIN VERIFIKATOR'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      expect(
        find.textContaining('Mohon lakukan revisi pada KTP Penanggung Jawab'),
        findsOneWidget,
      );
      expect(find.textContaining('Hendra Wijaya, S.T.'), findsOneWidget);
      expect(find.text('Selengkapnya'), findsOneWidget);

      // Tap Selengkapnya dialog
      await tester.tap(find.text('Selengkapnya'));
      await tester.pumpAndSettle();
      expect(find.text('Catatan Verifikator'), findsOneWidget);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders all 3 document revision cards with correct statuses', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Perlu Diperbaiki (3)'), findsOneWidget);
      expect(find.text('Tindakan Wajib'), findsOneWidget);

      // Card 1: KTP (Sudah Diperbarui)
      expect(find.text('1. KTP Direktur / Penanggung Jawab'), findsOneWidget);
      expect(find.text('Sudah Diperbarui'), findsWidgets);
      expect(
        find.text('Catatan: Pindaian buram, tanda tangan terpotong'),
        findsOneWidget,
      );
      expect(find.text('Ubah Berkas'), findsOneWidget);

      // Card 2: SHGB / SHM (Perlu Perbaikan)
      expect(
        find.text('2. Sertifikat Hak Atas Tanah (SHGB / SHM)'),
        findsOneWidget,
      );
      expect(find.text('Perlu Perbaikan'), findsWidgets);
      expect(
        find.text(
          'Catatan: Masa berlaku SK hak perlu diverifikasi ulang lampiran BPN',
        ),
        findsOneWidget,
      );
      expect(find.text('Perlu diganti dokumen baru'), findsOneWidget);
      expect(find.text('Perbarui Berkas'), findsWidgets);

      // Card 3: Site Plan (Multiple files)
      expect(
        find.text('3. Dokumen Perencanaan & Perancangan Site Plan'),
        findsOneWidget,
      );
      expect(find.text('PDF, banyak file'), findsOneWidget);
      expect(find.text('3 file'), findsOneWidget);
      expect(
        find.text('Catatan: Lampirkan file DWG AutoCAD dan PDF skala 1:1000'),
        findsOneWidget,
      );
      expect(find.text('Perbarui Berkas (3 File)'), findsOneWidget);
    });

    testWidgets('renders Terverifikasi dan Terkunci (17) collapsible section', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Terverifikasi dan Terkunci (17)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Terverifikasi dan Terkunci (17)'), findsOneWidget);
      expect(find.text('17 Berkas Sudah Terverifikasi'), findsOneWidget);
      expect(find.text('Tidak dapat diubah atau dihapus'), findsOneWidget);
      expect(find.text('NPWP Perusahaan'), findsOneWidget);
      expect(find.text('Akta Pendirian Perusahaan'), findsOneWidget);

      // Toggle accordion collapse
      await tester.tap(find.text('17 Berkas Sudah Terverifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('NPWP Perusahaan'), findsNothing);

      // Toggle accordion expand
      await tester.tap(find.text('17 Berkas Sudah Terverifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('NPWP Perusahaan'), findsOneWidget);
    });

    testWidgets(
      'renders sticky bottom action bar and handles Simpan Sementara',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Simpan Sementara'), findsOneWidget);
        expect(find.textContaining('Tersimpan otomatis'), findsOneWidget);
        expect(find.text('Tinjau Perbaikan'), findsOneWidget);
        expect(
          find.text('Perbarui 2 berkas lagi untuk melanjutkan'),
          findsOneWidget,
        );

        // Tap Simpan Sementara
        await tester.tap(find.text('Simpan Sementara'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Draft perbaikan berkas berhasil disimpan'),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping Pratinjau opens document preview modal', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pratinjau'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Pratinjau').first,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pratinjau').first);
      await tester.pumpAndSettle();

      expect(find.text('Pratinjau Dokumen'), findsOneWidget);
      expect(find.text('Pratinjau Digital Dokumen Sah'), findsOneWidget);
      expect(find.text('Tutup Pratinjau'), findsOneWidget);

      await tester.tap(find.text('Tutup Pratinjau'));
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau Dokumen'), findsNothing);
    });

    testWidgets('updating a document updates status, progress and counter', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1/3 Berkas'), findsOneWidget);
      expect(find.text('Perbarui Berkas'), findsWidgets);

      // Tap Perbarui Berkas on card 2 (navigates to DetailPerbaruiDokumenScreen Fase 3)
      await tester.scrollUntilVisible(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Perbarui Berkas'));
      await tester.pumpAndSettle();

      // On DetailPerbaruiDokumenScreen, confirm with Kirim Perbaikan
      expect(find.text('Kirim Perbaikan'), findsOneWidget);
      await tester.tap(find.text('Kirim Perbaikan'));
      await tester.pumpAndSettle();

      // Returns to PerbaruiBerkasScreen: Progress advances to 2/3 Berkas
      expect(find.text('2/3 Berkas'), findsOneWidget);
      expect(
        find.text('Perbarui 1 berkas lagi untuk melanjutkan'),
        findsOneWidget,
      );
    });

    testWidgets('responsive at 360dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tinjau Perbaikan'), findsOneWidget);
    });

    testWidgets('responsive at 412dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tinjau Perbaikan'), findsOneWidget);
    });

    testWidgets('supports 200% text scale without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tinjau Perbaikan'), findsOneWidget);
    });
  });
}
