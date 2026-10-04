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
  testWidgets('LoginScreen renders role selectors, inputs, and footer', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    expect(find.text('PILIH PERAN AKUN PENGGUNA'), findsOneWidget);
    expect(find.text('Pengembang'), findsOneWidget);
    expect(find.text('Pengawas Lapangan'), findsOneWidget);
    expect(find.text('Masuk sebagai Pengembang'), findsOneWidget);
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(
      find.text(
        'Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Toggling role switches role mode and action label', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    // Tap Pengawas Lapangan
    await tester.tap(find.text('Pengawas Lapangan'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk sebagai Pengawas Lapangan'), findsOneWidget);
    expect(find.text('Login Tim Pengawas Lapangan'), findsOneWidget);
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

  testWidgets('Tapping "Lupa Kata Sandi?" shows dialog mentioning Disperwaskim', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lupa Kata Sandi?'));
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
}
