import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/bantuan/presentation/screens/pusat_bantuan_screen.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';

void main() {
  Widget createTestWidget({
    double width = 390,
    double height = 844,
    GoRouter? router,
  }) {
    if (router != null) {
      return MaterialApp.router(
        routerConfig: router,
      );
    }

    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: const PusatBantuanScreen(),
      ),
    );
  }

  group('PusatBantuanScreen Widget Tests', () {
    testWidgets(
      'renders Header with title, subtitle, SATU RUMAH brand, and back button',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('Pusat Bantuan'), findsOneWidget);
        expect(
          find.text('Panduan dan kontak layanan Disperwaskim'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Bagian 1 Kontak Layanan with 4 rows and "Belum tersedia" chips when null',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 4 Kontak rows
        expect(find.text('Telepon'), findsOneWidget);
        expect(find.text('Hubungi petugas layanan'), findsOneWidget);

        expect(find.text('WhatsApp'), findsOneWidget);
        expect(find.text('Tanya jawab singkat'), findsOneWidget);

        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Kirim pertanyaan tertulis'), findsOneWidget);

        expect(find.text('Jam layanan'), findsOneWidget);
        expect(find.text('Hari dan jam kerja'), findsOneWidget);

        // 4 chips 'Belum tersedia'
        expect(find.text('Belum tersedia'), findsNWidgets(4));

        // Tapping rows when null does not throw
        await tester.tap(find.text('Telepon'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders Bagian 2 Panduan: tapping "Panduan pengajuan" opens dialog',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Panduan'), findsOneWidget);
        expect(find.text('Panduan pengajuan'), findsOneWidget);
        expect(find.text('Template berkas'), findsOneWidget);
        expect(find.text('Alur dan status pengajuan'), findsOneWidget);

        // Tap 'Panduan pengajuan'
        await tester.tap(find.text('Panduan pengajuan'));
        await tester.pumpAndSettle();

        // Dialog opens
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('Pengajuan diisi dalam 5 langkah. Berikut isi tiap langkah.'),
          findsOneWidget,
        );
        for (final langkah in ['Data PT', 'Berkas PT', 'Berkas perumahan', 'Teknis']) {
          expect(find.text(langkah), findsOneWidget);
        }
        expect(
          find.textContaining('Unggah minimal satu site plan berformat DWG atau PDF'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Review'),
          100,
          scrollable: find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Review'), findsOneWidget);

        // Tap 'Mengerti' to close
        await tester.tap(find.text('Mengerti'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping "Template berkas" navigates to /template-berkas',
      (tester) async {
        String? navigatedPath;
        final testRouter = GoRouter(
          initialLocation: '/bantuan',
          routes: [
            GoRoute(
              path: '/bantuan',
              builder: (_, __) => const PusatBantuanScreen(),
            ),
            GoRoute(
              path: '/template-berkas',
              builder: (_, __) {
                navigatedPath = '/template-berkas';
                return const Scaffold(
                  body: Text('Template Berkas Target Page'),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget(router: testRouter));
        await tester.pumpAndSettle();

        final templateRow = find.text('Template berkas');
        await tester.ensureVisible(templateRow);
        await tester.pumpAndSettle();
        await tester.tap(templateRow);
        await tester.pumpAndSettle();

        expect(navigatedPath, '/template-berkas');
        expect(find.text('Template Berkas Target Page'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Alur dan status pengajuan" opens bottom sheet with stages and no percentage',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final alurRow = find.text('Alur dan status pengajuan');
        await tester.ensureVisible(alurRow);
        await tester.pumpAndSettle();
        await tester.tap(alurRow);
        await tester.pumpAndSettle();

        expect(find.text('Alur & Status Pengajuan'), findsOneWidget);
        // Verify stages from StatusTahapPengajuan enum
        for (final tahap in StatusTahapPengajuan.values) {
          // Daftar tahap dibangun malas: gulir sampai tahap terakhir (Ditolak) terbuat.
          await tester.scrollUntilVisible(
            find.text(tahap.label),
            80,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text(tahap.label), findsWidgets);
        }

        // Verify NO percentage sign or indicator is rendered
        expect(find.textContaining('%'), findsNothing);

        // Dismiss bottom sheet via close button
        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();
        expect(find.text('Alur & Status Pengajuan'), findsNothing);
      },
    );

    testWidgets(
      'renders Bagian 3 Pertanyaan umum: displays 3 questions and answers when expanded',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Pertanyaan umum'), findsOneWidget);

        final q1 = find.text('Dokumen apa saja yang wajib diunggah?');
        final q2 = find.text(
          'Apa yang harus dilakukan jika berkas diminta diperbaiki?',
        );
        final q3 = find.text('Bagaimana jadwal survei lapangan ditentukan?');

        expect(q1, findsOneWidget);
        expect(q2, findsOneWidget);
        expect(q3, findsOneWidget);

        // Expand first accordion
        await tester.ensureVisible(q1);
        await tester.pumpAndSettle();
        await tester.tap(q1);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('5 berkas perusahaan, 10 berkas perumahan wajib'),
          findsOneWidget,
        );

        // Footer disclaimer note
        expect(
          find.text(
            'Kontak layanan akan diisi setelah divalidasi Disperwaskim. '
            'Selama belum ada, ditampilkan "Belum tersedia".',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('menjawab dua pertanyaan umum lainnya', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final q2 = find.text(
        'Apa yang harus dilakukan jika berkas diminta diperbaiki?',
      );
      await tester.ensureVisible(q2);
      await tester.tap(q2);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('lalu tekan Perbaiki Berkas'),
        findsOneWidget,
      );

      final q3 = find.text('Bagaimana jadwal survei lapangan ditentukan?');
      await tester.ensureVisible(q3);
      await tester.tap(q3);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Jadwalnya tampil di menu Jadwal Survey'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders responsively across 360dp, 390dp, and 412dp without overflow',
      (tester) async {
        for (final width in [360.0, 390.0, 412.0]) {
          await tester.pumpWidget(createTestWidget(width: width));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
