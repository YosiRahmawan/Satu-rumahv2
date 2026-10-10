import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/tambah_monitoring_stepper_screen.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  Widget harness({GoRouter? router, TextScaler? textScaler}) {
    final appRouter = router ?? _router();
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        builder: (context, child) {
          if (textScaler == null) return child!;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
      ),
    );
  }

  Future<void> pumpStep1(
    WidgetTester tester, {
    Size size = const Size(412, 900),
    TextScaler? textScaler,
    GoRouter? router,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(harness(router: router, textScaler: textScaler));
    await tester.pumpAndSettle();
  }

  testWidgets('renders Langkah 1 and binds all canonical provider fields', (
    tester,
  ) async {
    final notifier = container.read(monitoringFormProvider.notifier);
    final date = DateTime(2026, 1, 2);
    notifier.updateTanggal(date);
    notifier.updateNamaPerumahan('Perumahan Uji');
    notifier.updateLokasi('Jl. Uji No. 1');
    notifier.updateTemuan(['Temuan tersimpan']);
    notifier.updateKesimpulan(['Kesimpulan tersimpan']);

    await pumpStep1(tester);

    expect(find.text('Formulir Pengawasan'), findsOneWidget);
    expect(find.text('Langkah 1 dari 3: Info Umum'), findsOneWidget);
    expect(find.textContaining('2 January 2026'), findsOneWidget);
    expect(find.text('Perumahan Uji'), findsOneWidget);
    expect(find.text('Jl. Uji No. 1'), findsOneWidget);
    expect(
      find.text(container.read(monitoringFormProvider).maksudTujuan),
      findsOneWidget,
    );
    expect(find.text('Temuan tersimpan'), findsOneWidget);
    expect(find.text('Kesimpulan tersimpan'), findsOneWidget);
    expect(find.text('Wajib'), findsNWidgets(2));
    expect(find.text('Opsional'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits fields and preserves add/remove point state in provider', (
    tester,
  ) async {
    await pumpStep1(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Perumahan Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lokasi Baru');
    final addPoint = find.text('+ Tambah Poin').first;
    await tester.ensureVisible(addPoint);
    await tester.tap(addPoint);
    await tester.pump();

    var state = container.read(monitoringFormProvider);
    expect(state.namaPerumahan, 'Perumahan Baru');
    expect(state.lokasiPerumahan, 'Lokasi Baru');
    expect(state.temuanLapangan, hasLength(2));

    final deletePoint = find.byTooltip('Hapus poin').first;
    await tester.ensureVisible(deletePoint);
    await tester.tap(deletePoint);
    await tester.pump();

    state = container.read(monitoringFormProvider);
    expect(state.temuanLapangan, hasLength(1));
    expect(state.kesimpulan, ['']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requires nama perumahan, then navigates and retains state', (
    tester,
  ) async {
    final router = _router();
    await pumpStep1(tester, router: router);

    await tester.tap(find.text('Lanjut ke Langkah 2'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 0);
    expect(find.text('Nama Perumahan wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Perumahan Persisten',
    );
    await tester.tap(find.text('Lanjut ke Langkah 2'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 1);
    expect(find.text('Langkah 2 dari 3: Info Lanjutan'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    expect(container.read(monitoringFormProvider).currentStep, 0);
    expect(find.text('Perumahan Persisten'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/monitoring/tambah',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Simpan Draft is clearly disabled when no draft contract exists',
    (tester) async {
      await pumpStep1(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Simpan Draft'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Simpan Draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stepper remains stable at 360dp and 412dp with 200% text', (
    tester,
  ) async {
    for (final size in [const Size(360, 900), const Size(412, 900)]) {
      await pumpStep1(
        tester,
        size: size,
        textScaler: const TextScaler.linear(2),
      );
      expect(find.text('Formulir Pengawasan'), findsOneWidget);
      expect(find.text('Lanjut ke Langkah 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/monitoring/tambah',
    routes: [
      GoRoute(
        path: '/monitoring/tambah',
        builder: (_, __) => const TambahMonitoringStepperScreen(),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('Monitoring')),
      ),
    ],
  );
}
