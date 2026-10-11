import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/widgets/app_bottom_navigation.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_main_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  Widget buildSubject({int initialIndex = 0}) {
    return ProviderScope(
      overrides: [
        roleSessionProvider.overrideWith(
          (ref) => RoleSessionNotifier()
            ..signIn(
              AppRole.perwaskim,
              username: 'tim_monitoring_perwaskim',
            ),
        ),
      ],
      child: MaterialApp(
        home: MonitoringMainScreen(initialIndex: initialIndex),
      ),
    );
  }

  group('MonitoringMainScreen Bottom Navigation & Icon Synchronization', () {
    Finder navIcon(IconData icon) {
      return find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.byIcon(icon),
      );
    }

    testWidgets(
      'renders exactly 3 menus: Beranda, Riwayat, and Profil with correct initial icon states',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(buildSubject(initialIndex: 0));
        await tester.pumpAndSettle();

        // Exactly 3 tabs
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Riwayat'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // Does NOT contain Developer/Admin specific menus or plus button
        expect(find.text('Pengajuan'), findsNothing);
        expect(find.text('Notifikasi'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);

        // Inactive tabs use outlined icons, active tab uses filled rounded icon
        expect(navIcon(Icons.home_rounded), findsOneWidget);
        expect(navIcon(Icons.assignment_outlined), findsOneWidget);
        expect(navIcon(Icons.person_outline), findsOneWidget);
      },
    );

    testWidgets(
      'applies Enterprise colors and top hairline border to bottom navigation',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final bottomNavFinder = find.byType(BottomNavigationBar);
        expect(bottomNavFinder, findsOneWidget);

        final bottomNav = tester.widget<BottomNavigationBar>(bottomNavFinder);
        expect(bottomNav.selectedItemColor, equals(AppColors.enterprisePrimary));
        expect(
          bottomNav.unselectedItemColor,
          equals(AppColors.enterpriseTextMuted),
        );
        expect(bottomNav.selectedLabelStyle?.fontWeight, equals(FontWeight.w600));
        expect(bottomNav.unselectedLabelStyle?.fontWeight, equals(FontWeight.w500));

        // Top border check
        final containerFinder = find.ancestor(
          of: bottomNavFinder,
          matching: find.byType(Container),
        );
        expect(containerFinder, findsWidgets);
        final containerWidget = tester.widget<Container>(containerFinder.first);
        final decoration = containerWidget.decoration as BoxDecoration?;
        expect(decoration, isNotNull);
        expect(decoration!.border, isNotNull);
        final topSide = (decoration.border as Border).top;
        expect(topSide.color, equals(AppColors.enterpriseBorder));
      },
    );

    testWidgets(
      'transitions icons and pages cleanly when tapping each tab',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Initial State: Beranda active
        expect(navIcon(Icons.home_rounded), findsOneWidget);
        expect(navIcon(Icons.assignment_outlined), findsOneWidget);
        expect(navIcon(Icons.person_outline), findsOneWidget);
        expect(find.text('Hasil Survey Terbaru'), findsOneWidget);

        // 2. Switch to Tab 1: Riwayat
        await tester.tap(find.text('Riwayat'));
        await tester.pumpAndSettle();

        expect(navIcon(Icons.home_outlined), findsOneWidget);
        expect(navIcon(Icons.assignment_rounded), findsOneWidget);
        expect(navIcon(Icons.person_outline), findsOneWidget);
        // Verify Riwayat screen content is displayed
        expect(find.text('Riwayat Survey & BA'), findsOneWidget);

        // 3. Switch to Tab 2: Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();

        expect(navIcon(Icons.home_outlined), findsOneWidget);
        expect(navIcon(Icons.assignment_outlined), findsOneWidget);
        expect(navIcon(Icons.person_rounded), findsOneWidget);

        // 4. Switch back to Tab 0: Beranda
        await tester.tap(find.text('Beranda'));
        await tester.pumpAndSettle();

        expect(navIcon(Icons.home_rounded), findsOneWidget);
        expect(navIcon(Icons.assignment_outlined), findsOneWidget);
        expect(navIcon(Icons.person_outline), findsOneWidget);
        expect(find.text('Hasil Survey Terbaru'), findsOneWidget);
      },
    );

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets(
        'renders bottom navigation without overflow on viewport ${width}dp',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(Size(width, 844));
          await tester.pumpWidget(buildSubject());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(AppBottomNavigation), findsOneWidget);
        },
      );
    }
  });
}
