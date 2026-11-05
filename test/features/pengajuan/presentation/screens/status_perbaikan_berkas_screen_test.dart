import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/core/widgets/app_illustration.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/status_perbaikan_berkas_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Widget buildTestWidget({
    String pengajuanId = 'REG-2026-0142',
    double textScale = 1.0,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: StatusPerbaikanBerkasScreen(pengajuanId: pengajuanId),
      ),
    );
  }

  group('Layar Status Perbaikan Berkas', () {
    testWidgets('menampilkan ilustrasi, judul, dan penjelasan tanpa data contoh', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Status Pengajuan'), findsOneWidget);
      expect(find.text('Perbaikan Berhasil Dikirim'), findsOneWidget);
      expect(find.byType(AppIllustration), findsOneWidget);
      expect(find.byKey(const Key('perbaikan-penjelasan')), findsOneWidget);

      // Data karangan dari prototipe lama tidak boleh muncul lagi.
      expect(find.textContaining('Tawang'), findsNothing);
      expect(find.textContaining('18 Maret 2026'), findsNothing);
      expect(find.textContaining('17 terverifikasi'), findsNothing);
      expect(find.text('Riwayat Versi Berkas'), findsNothing);
    });

    testWidgets('ringkasan memuat nomor pengajuan, waktu kirim, dan status', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REG-2026-0142'), findsOneWidget);
      expect(find.text('Dikirim'), findsOneWidget);
      expect(find.textContaining('WIB'), findsOneWidget);
      expect(find.text('Dalam proses pemeriksaan'), findsOneWidget);
    });

    testWidgets('tombol Lihat Detail dan Kembali ke Beranda tersedia', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lihat Detail Pengajuan'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    for (final ukuran in [const Size(360, 800), const Size(412, 915)]) {
      testWidgets('tanpa overflow di lebar ${ukuran.width.toInt()}dp', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(ukuran);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('skala teks 200% tanpa overflow', (tester) async {
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
