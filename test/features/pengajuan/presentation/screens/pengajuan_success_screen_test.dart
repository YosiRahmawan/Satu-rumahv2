import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_success_screen.dart';

void main() {
  group('PengajuanSuccessScreen Tests', () {
    GoRouter testRouter() {
      return GoRouter(
        initialLocation: '/pengajuan/success',
        routes: [
          GoRoute(
            path: '/pengajuan/success',
            builder: (_, __) =>
                const PengajuanSuccessScreen(pengajuanId: 'REG-TSK-2026-144'),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
          ),
          GoRoute(
            path: '/pengajuan/detail/:id',
            builder: (_, state) =>
                Scaffold(body: Text('DETAIL ${state.pathParameters['id']}')),
          ),
        ],
      );
    }

    Widget createWidgetUnderTest({
      required double width,
      required double height,
      required GoRouter router,
      ProviderContainer? container,
    }) {
      final app = MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );

      return container != null
          ? UncontrolledProviderScope(container: container, child: app)
          : ProviderScope(child: app);
    }

    testWidgets('renders all content elements without overflow on constrained height (550px)', (
      tester,
    ) async {
      final router = testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(createWidgetUnderTest(width: 360, height: 550, router: router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pengajuan Berhasil Disimpan!'), findsOneWidget);
      expect(find.text('REG-TSK-2026-144'), findsOneWidget);
      expect(find.text('Lihat Notifikasi'), findsOneWidget);
      expect(find.text('Lihat Detail Pengajuan'), findsOneWidget);
      expect(find.text('Lihat Status Pengajuan'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets('renders responsively without overflow across 360dp, 390dp, and 412dp viewports', (
      tester,
    ) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(412, 915),
      ];

      for (final vp in viewports) {
        final router = testRouter();
        addTearDown(router.dispose);

        await tester.pumpWidget(
          createWidgetUnderTest(width: vp.width, height: vp.height, router: router),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pengajuan Berhasil Disimpan!'), findsOneWidget);
        expect(find.text('REG-TSK-2026-144'), findsOneWidget);
      }
    });

    testWidgets('Lihat Notifikasi button sets dashboardTabProvider to 2 and navigates to dashboard', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        createWidgetUnderTest(
          width: 390,
          height: 844,
          router: router,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      final notifFinder = find.text('Lihat Notifikasi');
      await tester.ensureVisible(notifFinder);
      await tester.tap(notifFinder);
      await tester.pumpAndSettle();

      expect(container.read(dashboardTabProvider), 2);
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    testWidgets('Lihat Status Pengajuan button sets dashboardTabProvider to 1 and navigates to dashboard', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        createWidgetUnderTest(
          width: 390,
          height: 844,
          router: router,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      final statusFinder = find.text('Lihat Status Pengajuan');
      await tester.ensureVisible(statusFinder);
      await tester.tap(statusFinder);
      await tester.pumpAndSettle();

      expect(container.read(dashboardTabProvider), 1);
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    testWidgets('Kembali ke Beranda button sets dashboardTabProvider to 0 and navigates to dashboard', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(dashboardTabProvider.notifier).state = 2;

      final router = testRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        createWidgetUnderTest(
          width: 390,
          height: 844,
          router: router,
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      final berandaFinder = find.text('Kembali ke Beranda');
      await tester.ensureVisible(berandaFinder);
      await tester.tap(berandaFinder);
      await tester.pumpAndSettle();

      expect(container.read(dashboardTabProvider), 0);
      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });
}
