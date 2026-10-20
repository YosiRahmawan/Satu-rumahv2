import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_main_screen.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  Widget buildSubject({
    int initialIndex = 0,
    VoidCallback? onCameraPressed,
    int? unreadCount,
    Key? key,
  }) {
    return ProviderScope(
      key: key,
      overrides: [
        roleSessionProvider.overrideWith(
          (ref) => RoleSessionNotifier()
            ..signIn(AppRole.perwaskim, username: 'tim_monitoring_perwaskim'),
        ),
        if (unreadCount != null)
          unreadNotifikasiCountProvider.overrideWithValue(unreadCount),
      ],
      child: MaterialApp(
        home: MonitoringMainScreen(
          initialIndex: initialIndex,
          onCameraPressed: onCameraPressed,
        ),
      ),
    );
  }

  group('MonitoringMainScreen Bottom Navigation & Docked FAB', () {
    Finder navIcon(IconData icon) {
      return find.descendant(
        of: find.byType(BottomAppBar),
        matching: find.byIcon(icon),
      );
    }

    testWidgets(
      'renders 4 menus (Beranda, Riwayat, Notifikasi, Profil) and center docked camera FAB',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(buildSubject(initialIndex: 0));
        await tester.pumpAndSettle();

        // 4 tabs exist
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Riwayat'), findsOneWidget);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // Does NOT contain Developer 'Pengajuan'
        expect(find.text('Pengajuan'), findsNothing);

        // Center Docked FAB with Camera Icon
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
        expect(find.byType(BottomAppBar), findsOneWidget);

        // Active tab 0 uses rounded/filled icon, others use outline icons
        expect(navIcon(Icons.home_rounded), findsOneWidget);
        expect(navIcon(Icons.assignment_outlined), findsOneWidget);
        expect(navIcon(Icons.notifications_none_rounded), findsOneWidget);
        expect(navIcon(Icons.person_outline_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'applies canonical pill style to active tab and secondary color to inactive tabs',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        TextStyle? labelStyle(String label) =>
            tester.widget<Text>(find.text(label)).style;

        expect(labelStyle('Beranda')?.color, equals(AppColors.primaryRed));
        expect(labelStyle('Beranda')?.fontWeight, equals(FontWeight.w700));

        expect(labelStyle('Riwayat')?.color, equals(AppColors.textSecondary));
        expect(labelStyle('Riwayat')?.fontWeight, equals(FontWeight.w500));

        expect(
          labelStyle('Notifikasi')?.color,
          equals(AppColors.textSecondary),
        );
        expect(labelStyle('Profil')?.color, equals(AppColors.textSecondary));

        // FAB styling
        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.backgroundColor, equals(AppColors.primaryRed));
        expect(fab.tooltip, equals('Kamera Lapangan'));
      },
    );

    testWidgets(
      'displays dynamic unread badge on Notifikasi tab when count > 0',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        await tester.pumpWidget(
          buildSubject(unreadCount: 3, key: const ValueKey('with_unread')),
        );
        await tester.pumpAndSettle();

        // Exactly 3 unread badge displayed in Notifikasi tab
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets('hides unread badge on Notifikasi tab when count == 0', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        buildSubject(unreadCount: 0, key: const ValueKey('no_unread')),
      );
      await tester.pumpAndSettle();

      // No unread badge
      expect(find.text('0'), findsNothing);
    });

    testWidgets('transitions icons and pages cleanly across all 4 tabs', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // 1. Initial State: Beranda active
      expect(navIcon(Icons.home_rounded), findsOneWidget);
      expect(find.text('Hasil Survey Terbaru'), findsOneWidget);

      // 2. Switch to Tab 1: Riwayat
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(navIcon(Icons.home_outlined), findsOneWidget);
      expect(navIcon(Icons.assignment_rounded), findsOneWidget);
      expect(find.text('Riwayat Survey & BA'), findsOneWidget);

      // 3. Switch to Tab 2: Notifikasi
      await tester.tap(find.text('Notifikasi'));
      await tester.pumpAndSettle();
      expect(navIcon(Icons.assignment_outlined), findsOneWidget);
      expect(navIcon(Icons.notifications_rounded), findsOneWidget);

      // 4. Switch to Tab 3: Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(navIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(navIcon(Icons.person_rounded), findsOneWidget);
      expect(find.text('Drs. Rian Hidayat, M.Si'), findsWidgets);

      // 5. Switch back to Tab 0: Beranda
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      expect(navIcon(Icons.home_rounded), findsOneWidget);
      expect(navIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('tab can be reset to Beranda via monitoringTabProvider', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(navIcon(Icons.assignment_rounded), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MonitoringMainScreen)),
      );
      container.read(monitoringTabProvider.notifier).state = 0;
      await tester.pumpAndSettle();

      expect(navIcon(Icons.home_rounded), findsOneWidget);
      expect(navIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('camera FAB invokes onCameraPressed when tapped', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      var cameraTapped = false;
      await tester.pumpWidget(
        buildSubject(onCameraPressed: () => cameraTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(cameraTapped, isTrue);
    });

    for (final width in [360.0, 390.0, 420.0]) {
      testWidgets(
        'renders bottom navigation without overflow on viewport ${width}dp',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(Size(width, 844));
          await tester.pumpWidget(buildSubject());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(BottomAppBar), findsOneWidget);
          expect(find.byType(FloatingActionButton), findsOneWidget);
        },
      );
    }

    testWidgets(
      'renders bottom navigation without overflow at text scale 200%',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: buildSubject(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(BottomAppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );
  });
}
