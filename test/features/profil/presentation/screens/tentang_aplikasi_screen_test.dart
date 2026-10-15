import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/config/app_config.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/profil/presentation/screens/tentang_aplikasi_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/tentang',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Halaman Beranda')),
        ),
        GoRoute(
          path: '/tentang',
          builder: (_, __) => const TentangAplikasiScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan identitas, versi, peran, dan pengembang', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Tentang aplikasi'), findsOneWidget);
    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Sistem Aplikasi Terpadu Urusan Rumah'), findsOneWidget);
    expect(find.text(AppConfig.versionLabel), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('© 2025–2026 Pemerintah Kota Tasikmalaya'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Diskominfo Kota Tasikmalaya'), findsOneWidget);
    expect(find.text('Disperwaskim'), findsOneWidget);
  });

  testWidgets('menjelaskan alur singkat dan tugas tiap peran', (tester) async {
    await pump(tester);
    final scroll = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Satu pengajuan melewati tiga peran secara berurutan.'),
      200,
      scrollable: scroll,
    );
    expect(find.textContaining('mengajukan berkas'), findsOneWidget);
    expect(find.textContaining('mengelola persetujuan'), findsOneWidget);

    for (final text in [
      'Pengembang',
      'Di aplikasi ini, Anda bisa',
      'Mengirim ulang berkas yang diminta diperbaiki',
      'Admin Disperwaskim',
      'Menjadwalkan survey dan menugaskan petugas lapangan',
      'Tim Perwaskim Lapangan',
      'Menyusun Berita Acara hasil survey',
    ]) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: scroll,
      );
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('tombol kembali tanpa riwayat menuju Beranda', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Halaman Beranda'), findsOneWidget);
  });

  testWidgets('aman pada skala teks 200% tanpa overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: TentangAplikasiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
