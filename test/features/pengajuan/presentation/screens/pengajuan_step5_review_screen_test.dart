import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_detail_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step5_review_screen.dart';

void main() {
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
}
