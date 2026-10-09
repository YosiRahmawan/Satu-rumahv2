import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_detail_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step5_review_screen.dart';

void main() {
  testWidgets(
    'uses the canonical Fase 3 contract and blocks review until required documents are complete',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pengajuanFormProvider.notifier);
      notifier.fillDummyData();
      notifier.deleteDocument('proposal_pembangunan');

      final router = GoRouter(
        initialLocation: '/pengajuan/step5',
        routes: [
          GoRoute(
            path: '/pengajuan/step5',
            builder: (context, state) => const PengajuanStep5ReviewScreen(),
          ),
          GoRoute(
            path: '/pengajuan/success',
            builder: (context, state) =>
                const Scaffold(body: Text('Pengajuan berhasil')),
          ),
          GoRoute(
            path: '/pengajuan/detail/:id',
            builder: (context, state) =>
                PengajuanDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      for (final slot in PengajuanStep3DocumentContract.slots) {
        expect(find.text(slot.label), findsOneWidget);
      }
      final optionalSlot = PengajuanStep3DocumentContract.slots.firstWhere(
        (slot) => slot.isOptional,
      );
      final missingRequiredSlot = PengajuanStep3DocumentContract.slots
          .firstWhere((slot) => slot.key == 'proposal_pembangunan');
      Finder rowStatus(String label, String status) => find.descendant(
        of: find
            .ancestor(of: find.text(label), matching: find.byType(Padding))
            .first,
        matching: find.text(status),
      );

      expect(rowStatus(missingRequiredSlot.label, 'Belum Ada'), findsOneWidget);
      expect(
        rowStatus(optionalSlot.label, 'Opsional · Belum Ada'),
        findsOneWidget,
      );

      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Kirim Pengajuan',
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
      expect(find.text('Pengajuan berhasil'), findsNothing);

      notifier.uploadDocument('proposal_pembangunan', 'proposal-baru.pdf');
      await tester.pumpAndSettle();

      expect(rowStatus(missingRequiredSlot.label, 'Belum Ada'), findsNothing);
      expect(
        rowStatus(optionalSlot.label, 'Opsional · Belum Ada'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);

      await tester.tap(find.text('Kirim Pengajuan'));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan berhasil'), findsOneWidget);
    },
  );

  testWidgets('submits without inventing company or director identity', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pengajuanFormProvider.notifier).fillDummyData();

    final router = GoRouter(
      initialLocation: '/pengajuan/step5',
      routes: [
        GoRoute(
          path: '/pengajuan/step5',
          builder: (context, state) => const PengajuanStep5ReviewScreen(),
        ),
        GoRoute(
          path: '/pengajuan/success',
          builder: (context, state) =>
              const Scaffold(body: Text('Pengajuan berhasil')),
        ),
        GoRoute(
          path: '/pengajuan/detail/:id',
          builder: (context, state) =>
              PengajuanDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum tersedia'), findsNWidgets(2));
    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan berhasil'), findsOneWidget);
    final submitted = container.read(pengajuanListProvider).first;
    expect(submitted.namaPt, isEmpty);
    expect(submitted.namaDirektur, isEmpty);
    expect(submitted.nib, isNull);

    router.go('/pengajuan/detail/${submitted.id}');
    await tester.pumpAndSettle();
    expect(find.text('Belum tersedia'), findsAtLeastNWidgets(3));
  });

  testWidgets('persists kajian technical files in the submitted record', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pengajuanFormProvider.notifier);
    notifier.fillDummyData();
    notifier.uploadDocuments(PengajuanFormState.technicalOtherDocumentsKey, [
      'kajian-geoteknik.pdf',
    ]);

    final router = GoRouter(
      initialLocation: '/pengajuan/step5',
      routes: [
        GoRoute(
          path: '/pengajuan/step5',
          builder: (context, state) => const PengajuanStep5ReviewScreen(),
        ),
        GoRoute(
          path: '/pengajuan/success',
          builder: (context, state) =>
              const Scaffold(body: Text('Pengajuan berhasil')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pumpAndSettle();

    final submitted = container.read(pengajuanListProvider).first;
    expect(submitted.technicalFiles, contains('kajian-geoteknik.pdf'));
  });

  testWidgets('does not submit deleted kajian references', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(pengajuanFormProvider.notifier);
    notifier.fillDummyData();
    notifier.uploadDocuments(PengajuanFormState.technicalOtherDocumentsKey, [
      'kajian-a.pdf',
      'kajian-b.pdf',
    ]);
    notifier.removeTechnicalOtherFile(0);
    notifier.removeTechnicalOtherFile(0);

    final router = GoRouter(
      initialLocation: '/pengajuan/step5',
      routes: [
        GoRoute(
          path: '/pengajuan/step5',
          builder: (context, state) => const PengajuanStep5ReviewScreen(),
        ),
        GoRoute(
          path: '/pengajuan/success',
          builder: (context, state) =>
              const Scaffold(body: Text('Pengajuan berhasil')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pumpAndSettle();

    final submitted = container.read(pengajuanListProvider).first;
    expect(submitted.uploadedDocs.containsKey('kajian_teknis'), isFalse);
    expect(submitted.technicalFiles, isNot(contains('kajian-a.pdf')));
    expect(submitted.technicalFiles, isNot(contains('kajian-b.pdf')));
  });

  testWidgets('renders provider-derived review summaries and file names', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pengajuanFormProvider.notifier).fillDummyData();

    final router = _reviewRouter();
    addTearDown(router.dispose);
    await _pumpReview(tester, container, router);

    expect(find.text('Green Tasik Residence'), findsOneWidget);
    expect(find.text('85 Unit'), findsOneWidget);
    expect(find.text('5 dari 5 berkas tersedia.'), findsOneWidget);
    expect(find.text('10 dari 10 berkas wajib tersedia.'), findsOneWidget);
    expect(find.text('surat_permohonan_persetujuan.pdf'), findsOneWidget);
    expect(find.text('berkas_gambar_teknis_lengkap.pdf'), findsOneWidget);
  });

  testWidgets(
    'each Ubah action routes to its matching step and preserves state',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).fillDummyData();

      final router = _reviewRouter(includeStepRoutes: true);
      addTearDown(router.dispose);
      await _pumpReview(tester, container, router);

      const expectedRoutes = [
        '/pengajuan/step1',
        '/pengajuan/step1',
        '/pengajuan/step2',
        '/pengajuan/step3',
        '/pengajuan/step4',
      ];
      for (var index = 0; index < expectedRoutes.length; index++) {
        final editAction = find.byType(TextButton).at(index);
        await tester.ensureVisible(editAction);
        await tester.tap(editAction);
        await tester.pumpAndSettle();
        expect(
          find.text(expectedRoutes[index].split('/').last),
          findsOneWidget,
        );
        expect(
          container.read(pengajuanFormProvider).namaPerumahan,
          'Green Tasik Residence',
        );
        router.pop();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'declaration gates submit while optional technical owner does not',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pengajuanFormProvider.notifier);
      notifier.fillDummyData();
      notifier.deleteDocument('penanggung_jawab_teknis');

      final router = _reviewRouter(includeSuccessRoute: true);
      addTearDown(router.dispose);
      await _pumpReview(tester, container, router);

      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Kirim Pengajuan',
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
      final agreement = find.byType(CheckboxListTile);
      await tester.ensureVisible(agreement);
      await tester.tap(agreement);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
      await tester.ensureVisible(agreement);
      await tester.tap(agreement);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'draft stays local and shows the existing session-only feedback',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).fillDummyData();

      final router = _reviewRouter();
      addTearDown(router.dispose);
      await _pumpReview(tester, container, router);
      final before = container.read(pengajuanListProvider).length;

      await tester.tap(find.text('Simpan sebagai Draft'));
      await tester.pump();

      expect(
        find.textContaining('Draft formulir disimpan untuk sesi ini'),
        findsOneWidget,
      );
      expect(container.read(pengajuanListProvider), hasLength(before));
      expect(
        container.read(pengajuanFormProvider).namaPerumahan,
        'Green Tasik Residence',
      );
    },
  );

  testWidgets(
    'local submit creates notification metadata for the submitted id',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).fillDummyData();

      final router = _reviewRouter(includeSuccessRoute: true);
      addTearDown(router.dispose);
      await _pumpReview(tester, container, router);
      await tester.tap(find.text('Kirim Pengajuan'));
      await tester.pumpAndSettle();

      final submitted = container.read(pengajuanListProvider).first;
      final notification = container.read(notifikasiProvider).first;
      expect(notification.id, 'notif-${submitted.id}');
      expect(notification.deskripsi, contains('(${submitted.id})'));
      expect(
        notification.targetRoute,
        '/admin/pengajuan/detail/${submitted.id}',
      );
      expect(find.text('Pengajuan berhasil'), findsOneWidget);
    },
  );
}

Future<void> _pumpReview(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _reviewRouter({
  bool includeStepRoutes = false,
  bool includeSuccessRoute = false,
}) {
  final routes = <RouteBase>[
    GoRoute(
      path: '/pengajuan/step5',
      builder: (context, state) => const PengajuanStep5ReviewScreen(),
    ),
  ];
  if (includeStepRoutes) {
    for (final step in [1, 2, 3, 4]) {
      routes.add(
        GoRoute(
          path: '/pengajuan/step$step',
          builder: (context, state) => Scaffold(body: Text('step$step')),
        ),
      );
    }
  }
  if (includeSuccessRoute) {
    routes.add(
      GoRoute(
        path: '/pengajuan/success',
        builder: (context, state) =>
            const Scaffold(body: Text('Pengajuan berhasil')),
      ),
    );
  }
  return GoRouter(initialLocation: '/pengajuan/step5', routes: routes);
}
