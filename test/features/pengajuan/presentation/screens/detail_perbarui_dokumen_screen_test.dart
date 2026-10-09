import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/detail_perbarui_dokumen_screen.dart';

void main() {
  Widget buildTestWidget({
    String pengajuanId = 'REG-2026-0142',
    String docKey = 'ktp',
    Map<String, dynamic>? docData,
    double textScale = 1.0,
    DetailFilePickerSeam? pickerSeam,
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
        home: DetailPerbaruiDokumenScreen(
          pengajuanId: pengajuanId,
          docKey: docKey,
          docData: docData,
          pickerSeam: pickerSeam,
        ),
      ),
    );
  }

  group('DetailPerbaruiDokumenScreen Tests (Fase 3 - Perbaikan Berkas)', () {
    testWidgets('renders AppBar with document title and pengajuan ID', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('KTP Penanggung Jawab'), findsOneWidget);
      expect(find.text('Perbarui Berkas • REG-2026-0142'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets(
      'renders Card 1: Alasan Perbaikan dari Admin with badge and date',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Alasan Perbaikan dari Admin'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsWidgets);
        expect(
          find.textContaining('Scan buram, nomor NIK dan tanda tangan'),
          findsOneWidget,
        );
        expect(find.text('Oleh Tim Verifikator Disperwaskim'), findsOneWidget);
        expect(find.text('14 Mar 2026'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Card 2: Berkas Saat Ini (Ditolak) and handles Pratinjau',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('BERKAS SAAT INI (DITOLAK)'), findsOneWidget);
        expect(find.text('Versi 1'), findsOneWidget);
        expect(find.text('KTP_Direktur_Lama.pdf'), findsOneWidget);
        expect(find.textContaining('1.2 MB'), findsOneWidget);

        // Tap Pratinjau on old file
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Pratinjau').first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Pratinjau Dokumen'), findsOneWidget);
        expect(find.text('Pratinjau Digital Dokumen Sah'), findsOneWidget);
        expect(find.text('Tutup Pratinjau'), findsOneWidget);

        await tester.tap(find.text('Tutup Pratinjau'));
        await tester.pumpAndSettle();
        expect(find.text('Pratinjau Digital Dokumen Sah'), findsNothing);
      },
    );

    testWidgets('renders Card 3: Unggah Berkas Pengganti and selected file', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('UNGGAH BERKAS PENGGANTI'), findsOneWidget);
      expect(find.text('Wajib Diisi'), findsOneWidget);
      expect(find.text('Ketuk untuk memilih berkas PDF'), findsOneWidget);
      expect(find.text('Maks. 10 MB, format PDF (BR-002)'), findsOneWidget);
      expect(find.text('Pilih Berkas'), findsOneWidget);

      // Selected file section
      expect(find.text('Berkas yang Dipilih:'), findsOneWidget);
      expect(find.text('KTP_Direktur_Revisi_2026.pdf'), findsOneWidget);
      expect(find.text('Siap Diunggah'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Info notice
      expect(
        find.textContaining('Ketentuan File: PDF max 10 MB'),
        findsOneWidget,
      );
    });

    testWidgets('clearing file with Hapus disables Kirim Perbaikan button', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Hapus'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hapus'), findsOneWidget);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      // Selected file is removed
      expect(find.text('Berkas yang Dipilih:'), findsNothing);

      // Button Kirim Perbaikan is disabled
      final kirimBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Kirim Perbaikan'),
      );
      expect(kirimBtn.onPressed, isNull);
    });

    testWidgets(
      'accepts a valid PDF replacement and updates the selected file',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            pickerSeam: ({allowedExtensions}) async => PlatformFile(
              name: 'KTP_Direktur_Baru.pdf',
              size: 2 * 1024 * 1024,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Pilih Berkas'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Pilih Berkas'));
        await tester.pumpAndSettle();

        expect(find.text('KTP_Direktur_Baru.pdf'), findsOneWidget);
        expect(find.text('2.0 MB'), findsOneWidget);
        expect(find.text('KTP_Direktur_Revisi_2026.pdf'), findsNothing);
      },
    );

    testWidgets(
      'rejects an oversized valid-PDF replacement and keeps the old file',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            pickerSeam: ({allowedExtensions}) async => PlatformFile(
              name: 'KTP_Direktur_Terlalu_Besar.pdf',
              size: 10 * 1024 * 1024 + 1,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Pilih Berkas'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Pilih Berkas'));
        await tester.pumpAndSettle();

        expect(find.text('KTP_Direktur_Revisi_2026.pdf'), findsOneWidget);
        expect(find.text('KTP_Direktur_Terlalu_Besar.pdf'), findsNothing);
        expect(
          find.textContaining(
            'File melebihi batas maksimal 10 MB. Berkas lama tetap tersimpan.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders Card 4: Catatan untuk Admin with counter', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Catatan untuk Admin (Opsional)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Catatan untuk Admin (Opsional)'), findsOneWidget);
      expect(
        find.text('Catatan pengembang terkait dokumen ini:'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('/250 karakter'), findsOneWidget);

      // Enter new text
      await tester.enterText(
        find.byType(TextField),
        'Perbaikan baru telah ditandatangani basah.',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Perbaikan baru telah ditandatangani basah.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Lihat Riwayat Versi opens version history modal', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lihat Riwayat Versi Dokumen (2 Versi)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lihat Riwayat Versi Dokumen (2 Versi)'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Versi Dokumen (2 Versi)'), findsWidgets);
      expect(find.text('Versi 2 (Revisi Siap Kirim)'), findsOneWidget);
      expect(find.text('Versi 1 (Ditolak Verifikator)'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('bottom action bar renders Batal and Kirim Perbaikan buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Kirim Perbaikan'), findsOneWidget);

      // Tap Kirim Perbaikan pops the screen
      await tester.tap(find.text('Kirim Perbaikan'));
      await tester.pumpAndSettle();
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
    });

    testWidgets('responsive at 412dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
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
    });
  });
}
