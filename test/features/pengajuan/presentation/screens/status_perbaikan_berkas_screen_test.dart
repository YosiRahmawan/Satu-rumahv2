import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/status_perbaikan_berkas_screen.dart';

void main() {
  Widget buildTestWidget({
    String pengajuanId = 'REG-2026-0142',
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
        home: StatusPerbaikanBerkasScreen(pengajuanId: pengajuanId),
      ),
    );
  }

  group('Fase 5 - Status Perbaikan Berkas Screen Tests', () {
    testWidgets('renders AppBar with title, back button, and help button', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Status Pengajuan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);

      // Tap help button
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('Bantuan Verifikasi'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Bantuan Verifikasi'), findsNothing);
    });

    testWidgets('renders success header and status explanation', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Perbaikan Berhasil Dikirim'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('Dalam Proses'), findsWidgets);
      expect(
        find.textContaining(
          'Tim Verifikator Disperwaskim akan memeriksa kembali kelengkapan berkas',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders ringkasan pengajuan card with all badges and metadata', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REG-2026-0142'), findsOneWidget);
      expect(find.text('Perbaikan ke-2'), findsOneWidget);
      expect(find.text('Perumahan Green Tasik'), findsOneWidget);
      expect(find.text('Kec. Tawang, Kota Tasikmalaya'), findsOneWidget);
      expect(find.textContaining('18 Maret 2026, 10:45 WIB'), findsOneWidget);
      expect(find.textContaining('3 berkas'), findsOneWidget);
      expect(find.textContaining('17 terverifikasi'), findsOneWidget);
    });

    testWidgets('renders action buttons Lihat Detail and Kembali ke Beranda', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lihat Detail Pengajuan'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets('renders Riwayat Versi Berkas timeline and supports Pratinjau', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Versi Berkas'), findsOneWidget);
      expect(find.text('KTP Penanggung Jawab'), findsOneWidget);
      expect(find.text('Slot No. 04'), findsOneWidget);

      // Versi 2
      expect(find.text('Versi 2 (Terkirim)'), findsOneWidget);
      expect(find.text('KTP_Direktur_Revisi_2026.pdf'), findsOneWidget);
      expect(
        find.textContaining('oleh PT Tasik Indah Sentosa'),
        findsOneWidget,
      );

      // Versi 1
      expect(find.text('Versi 1 (Ditolak)'), findsOneWidget);
      expect(find.text('KTP_Direktur_Lama.pdf'), findsOneWidget);
      expect(find.textContaining('Catatan Verifikator:'), findsOneWidget);
      expect(
        find.textContaining('Scan buram, NIK tidak terbaca dengan jelas.'),
        findsOneWidget,
      );

      // Tap Pratinjau on Versi 2
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
      expect(find.text('Pratinjau Digital Dokumen Sah'), findsNothing);
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
