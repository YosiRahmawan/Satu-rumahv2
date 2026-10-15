import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step1_screen.dart';

void main() {
  Widget createTestWidget({
    ProviderContainer? container,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    GoRouter? router,
  }) {
    final effectiveRouter =
        router ??
        GoRouter(
          initialLocation: '/pengajuan/step1',
          routes: [
            GoRoute(
              path: '/pengajuan/step1',
              builder: (context, state) => const PengajuanStep1Screen(),
            ),
            GoRoute(
              path: '/pengajuan/step2',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Step 2 Screen'))),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Dashboard Screen'))),
            ),
          ],
        );

    final widget = MaterialApp.router(
      routerConfig: effectiveRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: child!,
        );
      },
    );

    if (container != null) {
      return UncontrolledProviderScope(container: container, child: widget);
    }
    return ProviderScope(child: widget);
  }

  group('PengajuanStep1Screen (Fase 1 Prototype Acceptance Tests)', () {
    testWidgets(
      'renders stepper and unavailable PT identity for demo username',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Sign in as the demo developer
        container
            .read(roleSessionProvider.notifier)
            .signIn(AppRole.developer, username: 'pt_tasik_indah');

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // 1. Header elements
        expect(find.text('Pengajuan Baru'), findsOneWidget);
        expect(find.text('Langkah 1 dari 5'), findsOneWidget);
        expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsNothing);

        // 2. Stepper labels & Card title
        expect(find.text('Data PT'), findsNWidgets(2));
        expect(find.text('Berkas PT'), findsOneWidget);
        expect(find.text('Perumahan'), findsOneWidget);
        expect(find.text('Teknis'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);

        // 3. 6 Read-only Data PT fields
        expect(find.text('Nomor Induk Berusaha (NIB)'), findsOneWidget);
        expect(find.text('Nama Perusahaan (PT)'), findsOneWidget);
        expect(find.text('Penanggung Jawab / Direktur'), findsOneWidget);
        expect(find.text('Email Perusahaan'), findsOneWidget);
        expect(find.text('No. Telepon / WhatsApp'), findsOneWidget);
        expect(find.text('Alamat Kantor Perusahaan'), findsOneWidget);
        expect(find.text('Belum tersedia'), findsNWidgets(6));
        expect(find.text('PT. Tasik Indah Sentosa'), findsNothing);
        expect(find.text('H. Tatang Sutisna'), findsNothing);
      },
    );

    testWidgets(
      'indicates truthful unavailable state for arbitrary user session',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Sign in as arbitrary/non-demo account
        container
            .read(roleSessionProvider.notifier)
            .signIn(AppRole.developer, username: 'pengembang_lain');

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Belum tersedia'), findsNWidgets(6));
        expect(find.text('Pengembang (pengembang_lain)'), findsNothing);
      },
    );

    testWidgets(
      'renders all form inputs and segmented control for permohonan site plan',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tipe Pengajuan options
        expect(find.text('Pengajuan Site Plan Baru'), findsOneWidget);
        expect(find.text('Perubahan Siteplan'), findsOneWidget);
        expect(find.text('Pengembangan Siteplan'), findsOneWidget);

        // Input labels
        expect(find.text('Nama Kawasan / Perumahan *'), findsOneWidget);
        expect(find.text('Alamat / Lokasi Proyek *'), findsOneWidget);
        expect(find.text('NPWP Perusahaan *'), findsOneWidget);
        expect(find.text('Luas Lahan *'), findsOneWidget);
        expect(find.text('Jumlah Unit *'), findsOneWidget);

        // Tipe Perumahan options
        expect(find.text('Subsidi'), findsOneWidget);
        expect(find.text('Komersil'), findsOneWidget);
        expect(find.text('Campuran'), findsOneWidget);

        // Bottom buttons
        expect(find.text('‹ Kembali'), findsOneWidget);
        expect(find.text('Lanjut ke Berkas'), findsOneWidget);
      },
    );

    testWidgets(
      'blocks navigation and displays field validation errors when required inputs are empty',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // Click "Lanjut ke Berkas" without filling fields
        await tester.tap(find.text('Lanjut ke Berkas'));
        await tester.pumpAndSettle();

        // Check field error messages are shown
        expect(find.text('Nama perumahan wajib diisi'), findsOneWidget);
        expect(find.text('Alamat lokasi proyek wajib diisi'), findsOneWidget);
        expect(find.text('NPWP wajib diisi'), findsOneWidget);
        expect(find.text('Luas lahan harus > 0'), findsOneWidget);
        expect(find.text('Jumlah unit harus > 0'), findsOneWidget);

        // Still on Step 1, not navigated
        expect(find.text('Step 2 Screen'), findsNothing);
      },
    );

    testWidgets(
      'navigates successfully to Fase 2 when form is completely valid',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // Fill in valid data
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Graha Sukatani Indah',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Jl. Tamansari KM 4, Kota Tasikmalaya',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          '01.234.567.8-411.000',
        );
        await tester.enterText(find.byType(TextFormField).at(3), '48500');
        await tester.enterText(find.byType(TextFormField).at(4), '320');

        await tester.ensureVisible(find.text('Verifikasi'));
        await tester.tap(find.text('Verifikasi'));
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        // Select Tipe Perumahan "Komersil"
        await tester.ensureVisible(find.text('Komersil'));
        await tester.tap(find.text('Komersil'));
        await tester.pumpAndSettle();

        // Tap "Lanjut ke Berkas"
        await tester.tap(find.text('Lanjut ke Berkas'));
        await tester.pumpAndSettle();

        // Successfully navigated to Step 2!
        expect(find.text('Step 2 Screen'), findsOneWidget);
      },
    );

    testWidgets('blocks Fase 2 until NPWP is verified, then shows status', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Graha Sukatani Indah',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Jl. Tamansari KM 4, Kota Tasikmalaya',
      );
      await tester.enterText(find.byType(TextFormField).at(3), '48500');
      await tester.enterText(find.byType(TextFormField).at(4), '320');

      // Format salah ditolak oleh tombol Verifikasi.
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.ensureVisible(find.text('Verifikasi'));
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('NPWP harus 15 atau 16 digit angka'), findsOneWidget);

      // NPWP valid tetapi belum diverifikasi tidak boleh lanjut.
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '01.234.567.8-411.000',
      );
      await tester.tap(find.text('Lanjut ke Berkas'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 Screen'), findsNothing);
      expect(find.text('Belum diverifikasi'), findsOneWidget);
      Navigator.of(tester.element(find.text('Belum diverifikasi'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verifikasi'));
      await tester.tap(find.text('Verifikasi'));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      expect(
        find.text('NPWP Terdaftar Aktif di KPP Tasikmalaya'),
        findsOneWidget,
      );
      expect(container.read(pengajuanFormProvider).npwpVerified, isTrue);

      // Mengubah NPWP membatalkan verifikasi.
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '09.876.543.2-123.000',
      );
      await tester.pumpAndSettle();
      expect(container.read(pengajuanFormProvider).npwpVerified, isFalse);
    });

    testWidgets(
      'daya listrik PLN is optional, defaults to null, and updates via scrollable dropdown',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // 1. Placeholder shown when null
        expect(find.text('Pilih daya listrik'), findsOneWidget);
        expect(container.read(pengajuanFormProvider).dayaListrik, isEmpty);

        // 2. Tap dropdown trigger and verify options are rendered in scrollable menu
        final dropdownTrigger = find.byKey(
          const ValueKey('daya_listrik_dropdown'),
        );
        await tester.ensureVisible(dropdownTrigger);
        await tester.tap(dropdownTrigger);
        await tester.pumpAndSettle();

        expect(find.byType(Scrollbar), findsOneWidget);
        expect(find.text('450 VA'), findsOneWidget);
        expect(find.text('900 VA'), findsOneWidget);
        expect(find.text('1.300 VA'), findsOneWidget);
        expect(find.text('2.200 VA'), findsOneWidget);

        // Scroll to reach higher power options
        await tester.scrollUntilVisible(
          find.text('6.600 VA ke atas'),
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text('6.600 VA ke atas'), findsOneWidget);

        // Select '6.600 VA ke atas'
        await tester.tap(find.text('6.600 VA ke atas').last);
        await tester.pumpAndSettle();

        expect(
          container.read(pengajuanFormProvider).dayaListrik,
          '6.600 VA ke atas',
        );
        expect(find.text('6.600 VA ke atas'), findsOneWidget);
      },
    );

    testWidgets(
      'implements Opsi B (Merah Tegas) for Tipe Perumahan and clean animated dropdown for Daya Listrik',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // 1. Tipe Perumahan track container: #F1F5F9
        final trackFinder = find.byWidgetPredicate((widget) {
          return widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFF1F5F9);
        });
        expect(trackFinder, findsOneWidget);

        // Active sliding indicator: #DC2626
        final activeIndicatorFinder = find.byWidgetPredicate((widget) {
          return widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFDC2626);
        });
        expect(activeIndicatorFinder, findsOneWidget);

        // 2. Daya Listrik: Dropdown trigger exists with chevron down icon and InputDecorator
        final dropdownFinder = find.byKey(
          const ValueKey('daya_listrik_dropdown'),
        );
        expect(dropdownFinder, findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
        expect(find.text('Pilih daya listrik'), findsOneWidget);

        final inputDecorator = tester.widget<InputDecorator>(
          find.descendant(
            of: dropdownFinder,
            matching: find.byType(InputDecorator),
          ),
        );
        expect(inputDecorator.decoration.fillColor, Colors.white);
        expect(inputDecorator.decoration.filled, isTrue);

        // Initial chevron rotation is 0.0 (pointing down)
        final rotationFinder = find.descendant(
          of: dropdownFinder,
          matching: find.byType(RotationTransition),
        );
        expect(rotationFinder, findsOneWidget);
        final initialRotation = tester.widget<RotationTransition>(
          rotationFinder,
        );
        expect(initialRotation.turns.value, 0.0);

        // Open dropdown: rotates chevron by 180° (0.5 turns)
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final openedRotation = tester.widget<RotationTransition>(
          rotationFinder,
        );
        expect(openedRotation.turns.value, 0.5);

        // Close dropdown by tapping trigger again: rotates back to 0.0
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final closedRotation = tester.widget<RotationTransition>(
          rotationFinder,
        );
        expect(closedRotation.turns.value, 0.0);
      },
    );

    testWidgets(
      'retains form entries when navigating Fase 1 -> Fase 2 -> back to Fase 1',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        late BuildContext step2Context;
        final router = GoRouter(
          initialLocation: '/pengajuan/step1',
          routes: [
            GoRoute(
              path: '/pengajuan/step1',
              builder: (context, state) => const PengajuanStep1Screen(),
            ),
            GoRoute(
              path: '/pengajuan/step2',
              builder: (context, state) {
                step2Context = context;
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to Step 1'),
                    ),
                  ),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(container: container, router: router),
        );
        await tester.pumpAndSettle();

        // Fill values
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Kencana Kawalu Asri',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Jl. Kawalu Raya No. 12',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          '09.876.543.2-123.000',
        );
        await tester.enterText(find.byType(TextFormField).at(3), '25000');
        await tester.enterText(find.byType(TextFormField).at(4), '150');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Verifikasi'));
        await tester.tap(find.text('Verifikasi'));
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        // Navigate to Step 2
        await tester.tap(find.text('Lanjut ke Berkas'));
        await tester.pumpAndSettle();
        expect(find.text('Back to Step 1'), findsOneWidget);

        // Pop back to Step 1
        step2Context.pop();
        await tester.pumpAndSettle();

        // Verify all field values are retained!
        expect(find.text('Kencana Kawalu Asri'), findsOneWidget);
        expect(find.text('Jl. Kawalu Raya No. 12'), findsOneWidget);
        expect(find.text('09.876.543.2-123.000'), findsOneWidget);
        expect(find.text('25000'), findsOneWidget);
        expect(find.text('150'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly without overflow at 360dp width and 412dp width',
      (tester) async {
        // 360dp viewport
        await tester.pumpWidget(createTestWidget(size: const Size(360, 640)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 412dp viewport
        await tester.pumpWidget(createTestWidget(size: const Size(412, 900)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'handles 200% (2.0x) text scaling gracefully without crashing or layout breaks',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(size: const Size(360, 640), textScale: 2.0),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
