import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
      Finder rowStatus(String label) => find.descendant(
        of: find
            .ancestor(of: find.text(label), matching: find.byType(Padding))
            .first,
        matching: find.text('Belum Ada'),
      );

      expect(rowStatus(missingRequiredSlot.label), findsOneWidget);
      expect(rowStatus(optionalSlot.label), findsOneWidget);

      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Kirim Pengajuan',
      );
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
      expect(find.text('Pengajuan berhasil'), findsNothing);

      notifier.uploadDocument('proposal_pembangunan', 'proposal-baru.pdf');
      await tester.pumpAndSettle();

      expect(rowStatus(missingRequiredSlot.label), findsNothing);
      expect(rowStatus(optionalSlot.label), findsOneWidget);
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
}
