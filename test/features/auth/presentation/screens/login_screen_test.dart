import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/auth/presentation/screens/login_screen.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('MONITORING')),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const Scaffold(body: Text('ADMIN')),
      ),
    ],
  );
}

Widget _testApp(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('LoginScreen renders role selectors and form matching Figma prototype', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    expect(find.text('PILIH PERAN AKUN PENGGUNA'), findsOneWidget);
    expect(find.text('Pengembang'), findsOneWidget);
    expect(find.text('Pengawas Lapangan'), findsOneWidget);

    // Initial role is Pengembang
    expect(find.textContaining('Username / NIB Pengembang'), findsOneWidget);
    expect(find.text('Masukkan 13 digit NIB...'), findsOneWidget);
    expect(
      find.text('Contoh: 1234000567890 (NIB resmi terdaftar)'),
      findsOneWidget,
    );
    expect(find.textContaining('Kata Sandi'), findsOneWidget);
    expect(find.text('Bantuan Akses?'), findsOneWidget);
    expect(find.text('Ingat saya di perangkat ini'), findsOneWidget);
    expect(find.text('Masuk sebagai Pengembang'), findsOneWidget);
  });

  testWidgets('Toggling role switches form labels, placeholders, and action button', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    // Tap Pengawas Lapangan
    await tester.tap(find.text('Pengawas Lapangan'));
    await tester.pumpAndSettle();

    expect(find.text('Username / NIP Petugas'), findsOneWidget);
    expect(find.text('Masukkan username / NIP...'), findsOneWidget);
    expect(find.text('Contoh: 1234000567890 (NIP)'), findsOneWidget);
    expect(find.text('Masuk sebagai Pengawas Lapangan'), findsOneWidget);

    // Switch back to Pengembang
    await tester.tap(find.text('Pengembang'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Username / NIB Pengembang'), findsOneWidget);
    expect(find.text('Masukkan 13 digit NIB...'), findsOneWidget);
    expect(find.text('Masuk sebagai Pengembang'), findsOneWidget);
  });

  testWidgets('Validates required fields when submitted empty', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Masuk sebagai Pengembang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk sebagai Pengembang'));
    await tester.pumpAndSettle();

    expect(find.text('NIB atau email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Tapping "Bantuan Akses?" shows admin contact dialog', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bantuan Akses?'));
    await tester.pumpAndSettle();

    expect(find.text('Hubungi Administrator'), findsOneWidget);
    expect(
      find.textContaining('Admin Disperwaskim'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Hubungi Administrator'), findsNothing);
  });

  testWidgets(
    'Role selector animates sliding active indicator smoothly between roles',
    (tester) async {
      final router = _testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_testApp(router));
      await tester.pumpAndSettle();

      // Find the animated active indicator align widget
      final alignFinder = find.byKey(
        const ValueKey('role_active_indicator_align'),
      );
      expect(alignFinder, findsOneWidget);

      AnimatedAlign alignWidget = tester.widget<AnimatedAlign>(alignFinder);
      expect(alignWidget.alignment, equals(Alignment.centerLeft));

      // Verify AnimatedSwitcher for form content exists
      final formSwitcherFinder = find.byKey(
        const ValueKey('form_animated_switcher'),
      );
      expect(formSwitcherFinder, findsOneWidget);

      // Verify AnimatedContainer exists with primary red background
      final containerFinder = find.byKey(
        const ValueKey('role_active_indicator_container'),
      );
      expect(containerFinder, findsOneWidget);
      final containerWidget =
          tester.widget<AnimatedContainer>(containerFinder);
      final boxDec = containerWidget.decoration as BoxDecoration;
      expect(boxDec.color, equals(const Color(0xFFB91C1C))); // AppColors.primaryRed
      expect(boxDec.borderRadius, equals(BorderRadius.circular(14)));

      // Switch to Pengawas Lapangan
      await tester.tap(find.byKey(const ValueKey('role_tab_pengawas_lapangan')));
      // Pump mid-animation frame
      await tester.pump(const Duration(milliseconds: 100));

      // After settling, indicator is at centerRight
      await tester.pumpAndSettle();
      alignWidget = tester.widget<AnimatedAlign>(alignFinder);
      expect(alignWidget.alignment, equals(Alignment.centerRight));
      expect(find.text('Masuk sebagai Pengawas Lapangan'), findsOneWidget);

      // Switch back to Pengembang
      await tester.tap(find.byKey(const ValueKey('role_tab_pengembang')));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();
      alignWidget = tester.widget<AnimatedAlign>(alignFinder);
      expect(alignWidget.alignment, equals(Alignment.centerLeft));
      expect(find.text('Masuk sebagai Pengembang'), findsOneWidget);
    },
  );

  testWidgets(
    'Renders Google Stitch hero header, branding, and housing illustration painter',
    (tester) async {
      final router = _testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_testApp(router));
      await tester.pumpAndSettle();

      expect(find.text('SATU RUMAH'), findsOneWidget);
      expect(find.text('V2'), findsNothing);
      expect(find.text('KOTA TASIKMALAYA'), findsOneWidget);
      expect(find.text('DISPERWASKIM'), findsOneWidget);
      expect(
        find.text('Layanan Perumahan Terpadu Kota Tasikmalaya'),
        findsOneWidget,
      );
      expect(find.text('Modul Verifikasi Lapangan'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byIcon(Icons.replay_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    },
  );

  testWidgets(
    'Submits credentials and navigates to correct role homeRoute',
    (tester) async {
      final router = _testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_testApp(router));
      await tester.pumpAndSettle();

      // Enter Pengembang credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan 13 digit NIB...'),
        'pt_tasik_indah',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan kata sandi...'),
        'demo123',
      );

      await tester.ensureVisible(find.text('Masuk sebagai Pengembang'));
      await tester.tap(find.text('Masuk sebagai Pengembang'));
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
    },
  );

  testWidgets(
    'Submits Pengawas Lapangan credentials and navigates to monitoring',
    (tester) async {
      final router = _testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_testApp(router));
      await tester.pumpAndSettle();

      // Switch to Pengawas Lapangan
      await tester.tap(find.text('Pengawas Lapangan'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan username / NIP...'),
        'tim_monitoring_perwaskim',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan kata sandi...'),
        'monitoring123',
      );

      await tester.ensureVisible(find.text('Masuk sebagai Pengawas Lapangan'));
      await tester.tap(find.text('Masuk sebagai Pengawas Lapangan'));
      await tester.pumpAndSettle();

      expect(find.text('MONITORING'), findsOneWidget);
    },
  );

  testWidgets(
    'Responsive layouts without overflow across 360dp, 390dp, and 412dp widths',
    (tester) async {
      for (final width in [360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width * 2.0, 800.0 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = _testRouter();
        addTearDown(router.dispose);

        await tester.pumpWidget(_testApp(router));
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('PILIH PERAN AKUN PENGGUNA'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
