import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/widgets/app_button.dart';
import 'package:satu_rumah/core/widgets/app_housing_loader.dart';
import 'package:satu_rumah/core/widgets/app_loading_spinner.dart';
import 'package:satu_rumah/core/widgets/data_state_view.dart';

void main() {
  group('Dual Loading System - AppLoadingSpinner Tests', () {
    testWidgets(
      '1. Circular Spinner renders correctly with primaryRed default',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: AppLoadingSpinner.small())),
          ),
        );

        final indicatorFinder = find.byType(CircularProgressIndicator);
        expect(indicatorFinder, findsOneWidget);

        final indicator = tester.widget<CircularProgressIndicator>(
          indicatorFinder,
        );
        expect(indicator.strokeCap, StrokeCap.round);
        expect(indicator.strokeWidth, 2.0);

        final colorAnim = indicator.valueColor as AlwaysStoppedAnimation<Color>;
        expect(colorAnim.value, AppColors.primaryRed);

        // Box dimensions 18dp
        final sizedBoxFinder = find.byType(SizedBox).first;
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, 18.0);
        expect(sizedBox.height, 18.0);
      },
    );

    testWidgets(
      '2. Circular Spinner renders supported sizes (small, medium, large, custom)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppLoadingSpinner.small(),
                  AppLoadingSpinner.medium(),
                  AppLoadingSpinner.large(),
                  AppLoadingSpinner(customDimension: 26, strokeWidth: 2.2),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNWidgets(4));

        // Sizing checks
        final indicators = tester
            .widgetList<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .toList();

        expect(indicators[0].strokeWidth, 2.0); // small
        expect(indicators[1].strokeWidth, 2.5); // medium
        expect(indicators[2].strokeWidth, 3.0); // large
        expect(indicators[3].strokeWidth, 2.2); // custom
      },
    );

    testWidgets('3. Circular Spinner renders white variant for red buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLoadingSpinner.buttonWhite(customDimension: 22),
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final colorAnim = indicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(colorAnim.value, Colors.white);
    });

    testWidgets(
      '4. AppButton displays spinner and prevents duplicate submission while loading',
      (tester) async {
        int pressCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return AppButton.primary(
                    text: 'Simpan',
                    isLoading: true,
                    onPressed: () => pressCount++,
                  );
                },
              ),
            ),
          ),
        );

        // When loading, spinner is present and text is hidden
        expect(find.byType(AppLoadingSpinner), findsOneWidget);
        expect(find.text('Simpan'), findsNothing);

        // Tapping disabled button does not increment pressCount
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(pressCount, 0);
      },
    );

    testWidgets('5. AppButton displays regular text when loading completes', (
      tester,
    ) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton.secondary(
              text: 'Simpan Sementara',
              isLoading: false,
              onPressed: () => pressCount++,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingSpinner), findsNothing);
      expect(find.text('Simpan Sementara'), findsOneWidget);

      await tester.tap(find.text('Simpan Sementara'));
      await tester.pump();
      expect(pressCount, 1);
    });
  });

  group('Dual Loading System - AppHousingLoader Tests', () {
    testWidgets(
      '6. Housing Loader renders at supported sizes (small, medium, large, custom)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AppHousingLoader.small(),
                    AppHousingLoader.medium(),
                    AppHousingLoader.large(),
                    AppHousingLoader(customDimension: 80),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AppHousingLoader), findsNWidgets(4));

        final loaders = tester
            .widgetList<AppHousingLoader>(find.byType(AppHousingLoader))
            .toList();

        expect(loaders[0].size, AppHousingLoaderSize.small);
        expect(loaders[1].size, AppHousingLoaderSize.medium);
        expect(loaders[2].size, AppHousingLoaderSize.large);
        expect(loaders[3].customDimension, 80.0);

        // Verify rotation runs without exception
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1500));
      },
    );

    testWidgets('7. Housing ring rotates while houses remain stationary', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AppHousingLoader.medium())),
        ),
      );

      // Initial assembly phase (0ms -> 350ms -> 700ms)
      await tester.pump(const Duration(milliseconds: 350));
      final ringFinder = find.descendant(
        of: find.byType(AppHousingLoader),
        matching: find.byType(RotationTransition),
      );
      expect(ringFinder, findsOneWidget);

      final rotationTransition = tester.widget<RotationTransition>(ringFinder);

      // Ring turns animation value progresses
      final initialTurn = rotationTransition.turns.value;
      await tester.pump(const Duration(milliseconds: 750));
      final nextTurn = rotationTransition.turns.value;
      expect(nextTurn, isNot(equals(initialTurn)));

      // Stationary housing cluster AnimatedBuilder exists inside AppHousingLoader
      expect(
        find.descendant(
          of: find.byType(AppHousingLoader),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('8. Housing Loader respects reduced-motion preference', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(body: Center(child: AppHousingLoader.medium())),
          ),
        ),
      );

      // When animations are disabled, widget mounts with full assembly
      await tester.pump();
      final ringFinder = find.descendant(
        of: find.byType(AppHousingLoader),
        matching: find.byType(RotationTransition),
      );
      final rotationTransition = tester.widget<RotationTransition>(ringFinder);
      // Rotation controller is not repeated when reduced motion is requested
      expect(rotationTransition.turns.value, 0.0);
    });

    testWidgets('9. Housing Loader disposes animation controllers cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AppHousingLoader.medium())),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Remove from tree to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AppHousingLoader), findsNothing);
    });

    testWidgets(
      '10. DataStateView.loading renders AppHousingLoader and supports error/empty states',
      (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const DataStateView.loading(),
                  const DataStateView.empty(
                    title: 'Data Kosong',
                    message: 'Tidak ada data pengajuan.',
                  ),
                  DataStateView.error(onAction: () => retried = true),
                ],
              ),
            ),
          ),
        );

        // Loading state uses AppHousingLoader
        expect(find.byType(AppHousingLoader), findsOneWidget);

        // Empty state uses inbox icon
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Data Kosong'), findsOneWidget);

        // Error state uses error icon and retry button
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        expect(retried, isTrue);
      },
    );

    testWidgets(
      '11. Responsiveness across 360dp, 390dp, 412dp and Web screen widths',
      (tester) async {
        const screenWidths = [360.0, 390.0, 412.0, 1024.0];

        for (final width in screenWidths) {
          tester.view.physicalSize = Size(width * 2.0, 800.0 * 2.0);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.backgroundCanvas,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppHousingLoader.large(
                        message: 'Memuat data perumahan...',
                      ),
                      SizedBox(height: 16),
                      AppLoadingSpinner.medium(),
                    ],
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.text('Memuat data perumahan...'), findsOneWidget);
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
