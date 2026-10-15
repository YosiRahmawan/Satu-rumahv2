import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/template_berkas_screen.dart';

void main() {
  group('TemplateBerkasScreen Targeted Widget Tests', () {
    Widget buildScreen({double width = 390, double height = 844}) {
      return MaterialApp(
        theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: const TemplateBerkasScreen(),
        ),
      );
    }

    testWidgets('renders Header with title, subtitle, and back button', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Template Berkas'), findsOneWidget);
      expect(find.text('Panduan persyaratan pengajuan'), findsOneWidget);
      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
    });

    testWidgets('renders all 16 slots with 5+11 grouping on default filter', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Section header 1
      expect(find.text('BERKAS PERUSAHAAN — FASE 2'), findsOneWidget);
      expect(find.text('5 Dokumen'), findsOneWidget);

      // Verify all 16 items exist in the catalog
      expect(TemplateBerkasCatalog.items.length, 16);
      expect(
        TemplateBerkasCatalog.items
            .where((i) => i.group == TemplateBerkasGroup.perusahaan)
            .length,
        5,
      );
      expect(
        TemplateBerkasCatalog.items
            .where((i) => i.group == TemplateBerkasGroup.perumahan)
            .length,
        11,
      );

      // Check first item of group 1
      expect(find.text('KTP-el Pemohon / Direktur Utama'), findsOneWidget);

      // Scroll down on ListView to reveal Group 2
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final group2Finder = find.text('BERKAS PERUMAHAN — FASE 3');
      expect(group2Finder, findsOneWidget);
      expect(find.text('11 Dokumen'), findsOneWidget);

      // Check first item of group 2
      expect(
        find.text('Surat Permohonan Persetujuan Site Plan'),
        findsOneWidget,
      );
    });

    testWidgets('filtering by Perusahaan shows only 5 slots', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap "Perusahaan (5)" chip
      await tester.tap(find.text('Perusahaan (5)'));
      await tester.pumpAndSettle();

      expect(find.text('BERKAS PERUSAHAAN — FASE 2'), findsOneWidget);
      expect(find.text('BERKAS PERUMAHAN — FASE 3'), findsNothing);

      // All 5 company slots visible
      expect(find.text('KTP-el Pemohon / Direktur Utama'), findsOneWidget);
      expect(find.text('Nomor Induk Berusaha (NIB)'), findsOneWidget);
      expect(find.text('NPWP Perusahaan'), findsOneWidget);
      expect(find.text('Bukti Keanggotaan Asosiasi'), findsOneWidget);
      expect(find.text('Akta Pendirian & SK Kemenkumham'), findsOneWidget);

      // Phase 3 slot not visible
      expect(find.text('Surat Permohonan Persetujuan Site Plan'), findsNothing);
    });

    testWidgets('filtering by Perumahan shows only 11 slots', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap "Perumahan (11)" chip
      await tester.tap(find.text('Perumahan (11)'));
      await tester.pumpAndSettle();

      expect(find.text('BERKAS PERUSAHAAN — FASE 2'), findsNothing);
      expect(find.text('BERKAS PERUMAHAN — FASE 3'), findsOneWidget);

      // Phase 2 slot not visible
      expect(find.text('KTP-el Pemohon / Direktur Utama'), findsNothing);

      // Phase 3 slot visible
      expect(
        find.text('Surat Permohonan Persetujuan Site Plan'),
        findsOneWidget,
      );
    });

    testWidgets('search by document name filters the list', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'ANDALALIN');
      await tester.pumpAndSettle();

      expect(find.text('Persetujuan ANDALALIN / Dishub'), findsOneWidget);
      expect(find.text('KTP-el Pemohon / Direktur Utama'), findsNothing);
    });

    testWidgets('search clear button resets search input', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Listrik');
      await tester.pumpAndSettle();

      expect(find.text('Rekomendasi Listrik PLN'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // All items restored
      expect(find.text('KTP-el Pemohon / Direktur Utama'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('empty search results show empty state with reset button', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Dokumen Yang Tidak Ada XYZ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dokumen Tidak Ditemukan'), findsOneWidget);
      expect(
        find.text('Coba gunakan kata kunci lain atau periksa filter kategori.'),
        findsOneWidget,
      );
      expect(find.text('Reset Pencarian & Filter'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset Pencarian & Filter'));
      await tester.pumpAndSettle();

      // Full list is restored
      expect(find.text('BERKAS PERUSAHAAN — FASE 2'), findsOneWidget);
      expect(find.text('Dokumen Tidak Ditemukan'), findsNothing);
    });

    // ─── CONTEXTUAL AVAILABILITY & FORMAT & TEMPLATE TESTS ───

    testWidgets(
      '1. EXTERNAL_DOCUMENT (KTP, NIB, NPWP) does NOT display Unduh Template button',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Check KTP
        await tester.tap(find.text('KTP-el Pemohon / Direktur Utama'));
        await tester.pumpAndSettle();

        expect(find.text('Dokumen Instansi Terkait'), findsOneWidget);
        expect(
          find.text(
            'Gunakan dokumen resmi yang diterbitkan oleh instansi berwenang sesuai persyaratan pengajuan.',
          ),
          findsOneWidget,
        );

        // MUST NOT have "FORMAT & TEMPLATE" section or "Unduh Template" button
        expect(find.text('FORMAT & TEMPLATE'), findsNothing);
        expect(find.text('Unduh Template'), findsNothing);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();

        // Check NIB
        await tester.tap(find.text('Nomor Induk Berusaha (NIB)'));
        await tester.pumpAndSettle();

        expect(find.text('Dokumen Instansi Terkait'), findsOneWidget);
        expect(find.text('FORMAT & TEMPLATE'), findsNothing);
        expect(find.text('Unduh Template'), findsNothing);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();

        // Check NPWP
        await tester.tap(find.text('NPWP Perusahaan'));
        await tester.pumpAndSettle();

        expect(find.text('Dokumen Instansi Terkait'), findsOneWidget);
        expect(find.text('FORMAT & TEMPLATE'), findsNothing);
        expect(find.text('Unduh Template'), findsNothing);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '2. TEMPLATE_PENDING displays Format & Template section with disabled download button',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Scroll to Surat Permohonan
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Surat Permohonan Persetujuan Site Plan'));
        await tester.pumpAndSettle();

        // Notice Callout
        expect(find.text('Template Belum Tersedia'), findsOneWidget);
        expect(
          find.text(
            'Format unduhan belum disediakan. Silakan mengikuti ketentuan dokumen yang berlaku.',
          ),
          findsOneWidget,
        );

        // Format & Template section
        expect(find.text('FORMAT & TEMPLATE'), findsOneWidget);
        expect(find.text('Belum Tersedia'), findsOneWidget);
        expect(
          find.text('Format dokumen belum disediakan untuk diunduh.'),
          findsOneWidget,
        );

        // Unduh Template button is disabled
        final btnFinder = find.widgetWithText(ElevatedButton, 'Unduh Template');
        expect(btnFinder, findsOneWidget);
        final btnWidget = tester.widget<ElevatedButton>(btnFinder);
        expect(btnWidget.enabled, isFalse);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '3. Pernyataan PSU (TEMPLATE_PENDING) displays Format & Template with disabled button',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Filter Perumahan and search PSU
        await tester.tap(find.text('Perumahan (11)'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'PSU');
        await tester.pumpAndSettle();

        await tester.tap(
          find.text('Surat Pernyataan Kesanggupan Penyerahan PSU'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Template Belum Tersedia'), findsOneWidget);
        expect(find.text('FORMAT & TEMPLATE'), findsOneWidget);
        expect(find.text('Belum Tersedia'), findsOneWidget);

        final btnFinder = find.widgetWithText(ElevatedButton, 'Unduh Template');
        expect(btnFinder, findsOneWidget);
        final btnWidget = tester.widget<ElevatedButton>(btnFinder);
        expect(btnWidget.enabled, isFalse);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '4. GUIDANCE_ONLY displays Format & Template according to metadata with disabled button',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Bukti Keanggotaan Asosiasi is Guidance Only
        await tester.tap(find.text('Bukti Keanggotaan Asosiasi'));
        await tester.pumpAndSettle();

        expect(find.text('Panduan Persyaratan'), findsOneWidget);
        expect(
          find.text(
            'Informasi persyaratan dapat digunakan sebagai acuan. Belum ada file template yang tersedia untuk diunduh.',
          ),
          findsOneWidget,
        );

        // Displays Format & Template section
        expect(find.text('FORMAT & TEMPLATE'), findsOneWidget);
        expect(find.text('Belum Tersedia'), findsOneWidget);
        expect(
          find.text('Format dokumen belum disediakan untuk diunduh.'),
          findsOneWidget,
        );

        final btnFinder = find.widgetWithText(ElevatedButton, 'Unduh Template');
        expect(btnFinder, findsOneWidget);
        final btnWidget = tester.widget<ElevatedButton>(btnFinder);
        expect(btnWidget.enabled, isFalse);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '5. Tapping disabled Unduh Template button does not trigger any action or snackbar',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bukti Keanggotaan Asosiasi'));
        await tester.pumpAndSettle();

        final btnFinder = find.widgetWithText(ElevatedButton, 'Unduh Template');
        expect(btnFinder, findsOneWidget);

        // Attempt tap on disabled button
        await tester.tap(btnFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // No SnackBar or fake success dialog appears
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.text('Tutup Informasi'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '6. All 16 slots have accurate classifications and format section flags',
      (tester) async {
        const items = TemplateBerkasCatalog.items;
        expect(items.length, 16);

        // 10 External Documents -> NO Format & Template section
        final externalKeys = [
          'ktp',
          'nib',
          'npwp_doc',
          'legalitas',
          'info_intensitas_ruang',
          'bukti_kepemilikan_lahan',
          'rekomendasi_lingkungan',
          'andalalin',
          'rekomendasi_air_bersih',
          'rekomendasi_listrik',
        ];
        for (final key in externalKeys) {
          final item = items.firstWhere((it) => it.key == key);
          expect(
            item.availabilityStatus,
            DocumentAvailabilityStatus.externalDocument,
            reason: 'Slot ${item.slotNumber} ($key) should be externalDocument',
          );
          expect(
            item.hasFormatAndTemplateSection,
            isFalse,
            reason:
                'Slot ${item.slotNumber} ($key) must NOT have format section',
          );
        }

        // 2 Template Pending -> HAS Format & Template section
        final pendingKeys = ['surat_permohonan', 'pernyataan_psu'];
        for (final key in pendingKeys) {
          final item = items.firstWhere((it) => it.key == key);
          expect(
            item.availabilityStatus,
            DocumentAvailabilityStatus.templatePending,
            reason: 'Slot ${item.slotNumber} ($key) should be templatePending',
          );
          expect(
            item.hasFormatAndTemplateSection,
            isTrue,
            reason: 'Slot ${item.slotNumber} ($key) must have format section',
          );
        }

        // 4 Guidance Only -> HAS Format & Template section
        final guidanceKeys = [
          'asosiasi',
          'bukti_tpu',
          'penanggung_jawab_teknis',
          'proposal_pembangunan',
        ];
        for (final key in guidanceKeys) {
          final item = items.firstWhere((it) => it.key == key);
          expect(
            item.availabilityStatus,
            DocumentAvailabilityStatus.guidanceOnly,
            reason: 'Slot ${item.slotNumber} ($key) should be guidanceOnly',
          );
          expect(
            item.hasFormatAndTemplateSection,
            isTrue,
            reason: 'Slot ${item.slotNumber} ($key) must have format section',
          );
        }
      },
    );

    testWidgets(
      '7. Bottom sheet scrolls all the way to Format & Template section and starts at top 0',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bukti Keanggotaan Asosiasi'));
        await tester.pumpAndSettle();

        // Top metadata is visible
        expect(find.text('FORMAT BERKAS'), findsOneWidget);
        expect(find.text('MAKSIMAL UKURAN'), findsOneWidget);

        // Verify scroll starts at 0.0
        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        if (scrollableFinder.evaluate().isNotEmpty) {
          final scrollable = tester.state<ScrollableState>(
            scrollableFinder.first,
          );
          expect(scrollable.position.pixels, 0.0);
        }

        // Scroll down inside bottom sheet to reveal Format & Template
        await tester.drag(find.text('FORMAT BERKAS'), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('FORMAT & TEMPLATE'), findsOneWidget);
        expect(find.text('Unduh Template'), findsOneWidget);

        // Close via X button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text('FORMAT & TEMPLATE'), findsNothing);
      },
    );

    testWidgets(
      '8. Footer Tutup Informasi is non-scrolling and closes sheet cleanly',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bukti Keanggotaan Asosiasi'));
        await tester.pumpAndSettle();

        final tutupBtnFinder = find.widgetWithText(
          ElevatedButton,
          'Tutup Informasi',
        );
        expect(tutupBtnFinder, findsOneWidget);

        await tester.tap(tutupBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('TUJUAN DOKUMEN'), findsNothing);
      },
    );

    testWidgets(
      '9. Responsive layout on 360dp, 390dp, and 412dp viewports without overflow',
      (tester) async {
        for (final width in [360.0, 390.0, 412.0]) {
          await tester.pumpWidget(buildScreen(width: width, height: 800));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // Open sheet with Format & Template section
          await tester.tap(find.text('Bukti Keanggotaan Asosiasi'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('FORMAT BERKAS'), findsOneWidget);
          expect(find.text('FORMAT & TEMPLATE'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
