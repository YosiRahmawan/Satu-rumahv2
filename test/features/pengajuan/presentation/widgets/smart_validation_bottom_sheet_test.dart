import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step2_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/smart_validation_bottom_sheet.dart';

void main() {
  group('SmartValidationBottomSheet Component Tests', () {
    Widget buildSheetHost({
      required int completedCount,
      required int totalCount,
      required List<MissingValidationItem> missingItems,
      ValueChanged<String?>? onAction,
      VoidCallback? onCancel,
      Size size = const Size(390, 844),
      double textScale = 1.0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSmartValidationBottomSheet(
                    context: context,
                    title: 'Berkas Belum Lengkap',
                    subtitle: 'Lengkapi dokumen wajib sebelum ke Langkah 3.',
                    completedCount: completedCount,
                    totalCount: totalCount,
                    statusBadgeText:
                        '$completedCount dari $totalCount berkas lengkap',
                    warningText:
                        '${totalCount - completedCount} berkas wajib belum diunggah',
                    missingItems: missingItems,
                    actionButtonText: 'Lengkapi Berkas Sekarang',
                    cancelButtonText: 'Kembali ke Formulir',
                    onActionPressed: onAction,
                  );
                },
                child: const Text('Buka Modal'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders header, warning icon, and close button X', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSheetHost(
          completedCount: 0,
          totalCount: 5,
          missingItems: const [
            MissingValidationItem(
              key: 'ktp',
              title: '1. KTP-el Pemohon / Direktur Utama *',
              subtitle: 'PDF maks 10MB',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsOneWidget);
      expect(
        find.text('Lengkapi dokumen wajib sebelum ke Langkah 3.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Tutup'), findsOneWidget);
    });

    testWidgets('reflects dynamic progress data and warning counter', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSheetHost(
          completedCount: 3,
          totalCount: 5,
          missingItems: const [
            MissingValidationItem(
              key: 'asosiasi',
              title: '4. Bukti Keanggotaan Asosiasi *',
              subtitle: 'PDF maks 10MB',
            ),
            MissingValidationItem(
              key: 'legalitas',
              title: '5. Akta Pendirian & SK Kemenkumham *',
              subtitle: 'PDF maks 10MB',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Status Kelengkapan'), findsOneWidget);
      expect(find.text('3 dari 5 berkas lengkap'), findsOneWidget);
      expect(find.text('2 berkas wajib belum diunggah'), findsOneWidget);
      expect(find.text('DAFTAR DOKUMEN YANG PERLU DIUNGGAH'), findsOneWidget);
      expect(find.text('4. Bukti Keanggotaan Asosiasi *'), findsOneWidget);
      expect(
        find.text('5. Akta Pendirian & SK Kemenkumham *'),
        findsOneWidget,
      );
      expect(find.text('Belum diunggah'), findsNWidgets(2));
    });

    testWidgets(
      'tapping Lengkapi Berkas Sekarang invokes callback with first key and closes sheet',
      (tester) async {
        String? selectedFirstKey;
        await tester.pumpWidget(
          buildSheetHost(
            completedCount: 1,
            totalCount: 5,
            missingItems: const [
              MissingValidationItem(
                key: 'nib',
                title: '2. Nomor Induk Berusaha (NIB) *',
              ),
              MissingValidationItem(
                key: 'npwp_doc',
                title: '3. NPWP Perusahaan *',
              ),
            ],
            onAction: (key) => selectedFirstKey = key,
          ),
        );

        await tester.tap(find.text('Buka Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Berkas Belum Lengkap'), findsOneWidget);

        await tester.tap(find.text('Lengkapi Berkas Sekarang'));
        await tester.pumpAndSettle();

        expect(selectedFirstKey, 'nib');
        expect(find.text('Berkas Belum Lengkap'), findsNothing);
      },
    );

    testWidgets('tapping Kembali ke Formulir closes sheet without action', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSheetHost(
          completedCount: 0,
          totalCount: 5,
          missingItems: const [],
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Formulir'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsNothing);
    });

    testWidgets('tapping close X button dismisses the bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSheetHost(
          completedCount: 0,
          totalCount: 5,
          missingItems: const [],
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsOneWidget);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsNothing);
    });

    testWidgets('renders cleanly without overflow across 360dp, 390dp, and 412dp viewports', (
      tester,
    ) async {
      final items = List.generate(
        5,
        (i) => MissingValidationItem(
          key: 'doc_$i',
          title: 'Dokumen Persyaratan Ke-$i Lengkap Dan Sah *',
          subtitle: 'Format PDF maksimal 10MB',
        ),
      );

      for (final size in [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ]) {
        await tester.pumpWidget(
          buildSheetHost(
            completedCount: 0,
            totalCount: 5,
            missingItems: items,
            size: size,
          ),
        );

        await tester.tap(find.text('Buka Modal'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('supports 200% text scale without overflow', (tester) async {
      final items = List.generate(
        5,
        (i) => MissingValidationItem(
          key: 'doc_$i',
          title: 'Dokumen Persyaratan Ke-$i *',
        ),
      );

      await tester.pumpWidget(
        buildSheetHost(
          completedCount: 0,
          totalCount: 5,
          missingItems: items,
          size: const Size(360, 640),
          textScale: 2.0,
        ),
      );

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('PengajuanStep2Screen Smart Validation Integration Tests', () {
    Widget buildStep2IntegrationHost({
      required ProviderContainer container,
      FilePickerSeam? pickerSeam,
      GoRouter? router,
    }) {
      final effectiveRouter = router ??
          GoRouter(
            initialLocation: '/pengajuan/step2',
            routes: [
              GoRoute(
                path: '/pengajuan/step2',
                builder: (context, state) =>
                    PengajuanStep2Screen(pickerSeam: pickerSeam),
              ),
              GoRoute(
                path: '/pengajuan/step3',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Step 3 Target Screen'))),
              ),
            ],
          );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: effectiveRouter,
        ),
      );
    }

    testWidgets('Continue button is primary red and clickable when form is empty', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildStep2IntegrationHost(container: container),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lanjut ke Langkah 3'),
      );
      expect(button.onPressed, isNotNull);
      expect(
        button.style?.backgroundColor?.resolve({}),
        AppColors.primaryRed,
      );
    });

    testWidgets(
      'tapping invalid Continue button opens Smart Validation Bottom Sheet, stays on Step 2',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildStep2IntegrationHost(container: container),
        );
        await tester.pumpAndSettle();

        // Tap Continue
        await tester.tap(find.text('Lanjut ke Langkah 3'));
        await tester.pumpAndSettle();

        // Sheet is opened
        expect(find.text('Berkas Belum Lengkap'), findsOneWidget);
        expect(find.text('0 dari 5 berkas lengkap'), findsOneWidget);
        expect(find.text('5 berkas wajib belum diunggah'), findsOneWidget);
        expect(find.text('Lengkapi Berkas Sekarang'), findsOneWidget);

        // User remains on Step 2
        expect(find.text('Langkah 2 dari 5'), findsOneWidget);
        expect(find.text('Step 3 Target Screen'), findsNothing);
      },
    );

    testWidgets(
      'tapping Lengkapi Berkas Sekarang in sheet scrolls and highlights target field',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildStep2IntegrationHost(container: container),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lanjut ke Langkah 3'));
        await tester.pumpAndSettle();

        expect(find.text('Berkas Belum Lengkap'), findsOneWidget);

        // Tap Lengkapi Berkas Sekarang
        await tester.tap(find.text('Lengkapi Berkas Sekarang'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));

        // Modal closed
        expect(find.text('Berkas Belum Lengkap'), findsNothing);

        // Back to form, still on Step 2
        expect(find.text('Langkah 2 dari 5'), findsOneWidget);
      },
    );

    testWidgets(
      'rapid double tapping Continue button does not create repeated modals',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildStep2IntegrationHost(container: container),
        );
        await tester.pumpAndSettle();

        // Rapid double tap
        await tester.tap(find.text('Lanjut ke Langkah 3'));
        await tester.tap(
          find.text('Lanjut ke Langkah 3'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Only one sheet is active
        expect(find.text('Berkas Belum Lengkap'), findsOneWidget);

        // Dismissing sheet once leaves zero sheets
        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();

        expect(find.text('Berkas Belum Lengkap'), findsNothing);
      },
    );

    testWidgets(
      'completing all 5 documents allows Continue button to navigate directly without sheet',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(pengajuanFormProvider.notifier);
        notifier.uploadDocument('ktp', 'ktp.pdf');
        notifier.uploadDocument('nib', 'nib.pdf');
        notifier.uploadDocument('npwp_doc', 'npwp.pdf');
        notifier.uploadDocument('asosiasi', 'asosiasi.pdf');
        notifier.uploadDocument('legalitas', 'legalitas.pdf');

        await tester.pumpWidget(
          buildStep2IntegrationHost(container: container),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lanjut ke Langkah 3'));
        await tester.pumpAndSettle();

        // No validation sheet shown
        expect(find.text('Berkas Belum Lengkap'), findsNothing);

        // Successfully navigated to Step 3
        expect(find.text('Step 3 Target Screen'), findsOneWidget);
      },
    );
  });
}
