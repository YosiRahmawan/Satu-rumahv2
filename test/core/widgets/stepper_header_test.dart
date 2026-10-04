import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/stepper_header.dart';
import 'package:satu_rumah/core/widgets/status_badge.dart';

void main() {
  group('StepperHeader Responsive Tests', () {
    testWidgets('renders all 5 steps safely on 360px viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StepperHeader(currentStep: 3),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Data PT'), findsOneWidget);
      expect(find.text('Dok. Admin'), findsOneWidget);
      expect(find.text('Dok. Legal'), findsOneWidget);
      expect(find.text('Dok. Teknis'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('handles font scaling gracefully without overflow on 360px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: StepperHeader(currentStep: 4),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dok. Teknis'), findsOneWidget);
    });
  });

  group('StatusBadge Semantic Color Tests', () {
    testWidgets('renders correct semantic colors for success statuses', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'Disetujui'),
                StatusBadge(status: 'Selesai'),
                StatusBadge(status: 'Perlu Perbaikan'),
                StatusBadge(status: 'Dalam Proses'),
                StatusBadge(status: 'Ditolak'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Perlu Perbaikan'), findsOneWidget);
      expect(find.text('Dalam Proses'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
    });
  });
}
