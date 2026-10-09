import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/pengajuan_step_header.dart';

void main() {
  Widget buildHeader({
    String title = 'Pengajuan Baru',
    String subtitle = 'Langkah 1 dari 5',
    String badgeText = 'DISPERWASKIM KOTA TASIKMALAYA',
    VoidCallback? onBackPressed,
    VoidCallback? onHelpPressed,
    double textScale = 1.0,
    Size size = const Size(390, 844),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 44),
        ),
        child: Scaffold(
          body: PengajuanStepHeader(
            title: title,
            subtitle: subtitle,
            badgeText: badgeText,
            onBackPressed: onBackPressed,
            onHelpPressed: onHelpPressed,
          ),
        ),
      ),
    );
  }

  group('PengajuanStepHeader Visual & Interaction Tests', () {
    testWidgets('renders title, subtitle, and agency badge pill correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildHeader());
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Baru'), findsOneWidget);
      expect(find.text('Langkah 1 dari 5'), findsOneWidget);
      expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('triggers onBackPressed and onHelpPressed callbacks', (
      tester,
    ) async {
      var backTapped = false;
      var helpTapped = false;

      await tester.pumpWidget(
        buildHeader(
          onBackPressed: () => backTapped = true,
          onHelpPressed: () => helpTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Kembali'));
      expect(backTapped, isTrue);

      await tester.tap(find.byTooltip('Bantuan'));
      expect(helpTapped, isTrue);
    });

    testWidgets('renders safely on 360dp width and 412dp width', (
      tester,
    ) async {
      await tester.pumpWidget(buildHeader(size: const Size(360, 640)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(buildHeader(size: const Size(412, 900)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely under 200% text scaling (2.0x)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHeader(
          size: const Size(360, 640),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
