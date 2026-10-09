import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step4_screen.dart';

Widget _host({
  required ProviderContainer container,
  required Step4FilePickerSeam picker,
  Size size = const Size(390, 844),
  double textScale = 1,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(home: PengajuanStep4Screen(pickerSeam: picker)),
    ),
  );
}

PlatformFile _file(String name, int size) =>
    PlatformFile(name: name, size: size);

void main() {
  group('PengajuanStep4Screen', () {
    testWidgets('shows two technical groups and step 4 composition', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) async =>
              const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Baru'), findsOneWidget);
      expect(find.text('Langkah 4 dari 5'), findsOneWidget);
      expect(find.text('Ketentuan Format Teknis'), findsOneWidget);
      expect(
        find.text('Dokumen Perencanaan & Perancangan Site Plan Perumahan'),
        findsOneWidget,
      );
      expect(find.text('Dokumen Kajian Teknis Lainnya'), findsOneWidget);
      expect(find.text('Lanjut ke Review & Submit'), findsOneWidget);
    });

    testWidgets('accepts DWG/PDF for site plan and PDF for kajian', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var call = 0;
      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) async {
            call++;
            return call == 1
                ? [
                    _file('site-plan.dwg', 18 * 1024 * 1024),
                    _file('site-plan.pdf', 3 * 1024 * 1024),
                  ]
                : [_file('soil-test.pdf', 8 * 1024 * 1024)];
          },
        ),
      );
      await tester.pumpAndSettle();

      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              '+ Tambah File Site Plan (DWG/PDF)',
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('+ Tambah File Kajian (PDF)'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '+ Tambah File Kajian (PDF)'),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      final state = container.read(pengajuanFormProvider);
      expect(state.technicalFiles, ['site-plan.dwg', 'site-plan.pdf']);
      expect(state.technicalOtherFiles, ['soil-test.pdf']);
      expect(state.isStep4Valid, isTrue);
      expect(find.text('18.0 MB'), findsOneWidget);
      expect(find.text('8.0 MB'), findsOneWidget);
    });

    testWidgets(
      'rejects invalid kajian file without clearing prior valid file',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(pengajuanFormProvider.notifier).uploadDocuments(
          'kajian_teknis',
          ['previous.pdf'],
        );
        await tester.pumpWidget(
          _host(
            container: container,
            picker: ({required allowMultiple, allowedExtensions}) async => [
              _file('sketsa.jpg', 10),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('+ Tambah File Kajian (PDF)'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, '+ Tambah File Kajian (PDF)'),
            )
            .onPressed!();
        await tester.pumpAndSettle();

        expect(container.read(pengajuanFormProvider).technicalOtherFiles, [
          'previous.pdf',
        ]);
        expect(
          find.textContaining('Format tidak didukung. Gunakan PDF.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('supports delete, cancellation, and responsive text scaling', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).addTechnicalFiles([
        'existing.dwg',
      ]);
      for (final size in [const Size(360, 800), const Size(412, 900)]) {
        await tester.pumpWidget(
          _host(
            container: container,
            size: size,
            textScale: 2,
            picker: ({required allowMultiple, allowedExtensions}) async =>
                const [],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('existing.dwg'), findsOneWidget);
      }

      final deleteButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline),
      );
      deleteButton.onPressed!();
      await tester.pumpAndSettle();
      expect(container.read(pengajuanFormProvider).technicalFiles, isEmpty);
    });

    testWidgets('rejects oversized files and preserves existing valid files', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).addTechnicalFiles([
        'existing.dwg',
      ]);
      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) async => [
            _file('too-large.pdf', 50 * 1024 * 1024 + 1),
          ],
        ),
      );
      await tester.pumpAndSettle();

      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              '+ Tambah File Site Plan (DWG/PDF)',
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(container.read(pengajuanFormProvider).technicalFiles, [
        'existing.dwg',
      ]);
      expect(
        find.textContaining('Ukuran melebihi batas 50 MB'),
        findsOneWidget,
      );
    });

    testWidgets('does not add duplicate references within a group', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanFormProvider.notifier).addTechnicalFiles([
        'existing.dwg',
      ]);
      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) async => [
            _file('existing.dwg', 2 * 1024 * 1024),
            _file('new.pdf', 2 * 1024 * 1024),
          ],
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              '+ Tambah File Site Plan (DWG/PDF)',
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(container.read(pengajuanFormProvider).technicalFiles, [
        'existing.dwg',
        'new.pdf',
      ]);
    });

    testWidgets('cancelled and failed picker operations do not mutate state', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final pickerResult = Completer<List<PlatformFile>>();
      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) =>
              pickerResult.future,
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              '+ Tambah File Site Plan (DWG/PDF)',
            ),
          )
          .onPressed!();
      await tester.pump();
      final cancelButton = find.ancestor(
        of: find.text('Batal'),
        matching: find.byType(TextButton),
      );
      tester.widget<TextButton>(cancelButton).onPressed!();
      pickerResult.complete([_file('cancelled.dwg', 2)]);
      await tester.pumpAndSettle();
      expect(container.read(pengajuanFormProvider).technicalFiles, isEmpty);

      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required allowMultiple, allowedExtensions}) async {
            throw StateError('picker failed');
          },
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              '+ Tambah File Site Plan (DWG/PDF)',
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(container.read(pengajuanFormProvider).technicalFiles, isEmpty);
      expect(
        find.textContaining('Pemilih berkas tidak dapat dibuka'),
        findsOneWidget,
      );
    });

    testWidgets('uses stack navigation between step 3, 4, and 5', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/pengajuan/step3',
        routes: [
          GoRoute(
            path: '/pengajuan/step3',
            builder: (_, __) => Scaffold(
              body: TextButton(
                onPressed: () => router.push('/pengajuan/step4'),
                child: const Text('open step 4'),
              ),
            ),
          ),
          GoRoute(
            path: '/pengajuan/step4',
            builder: (_, __) => PengajuanStep4Screen(
              pickerSeam: ({required allowMultiple, allowedExtensions}) async =>
                  [_file('technical.pdf', 2)],
            ),
          ),
          GoRoute(
            path: '/pengajuan/step5',
            builder: (_, __) => const Scaffold(body: Text('step 5')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('open step 4'));
      await tester.pumpAndSettle();
      expect(find.text('Langkah 4 dari 5'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(
          OutlinedButton,
          '+ Tambah File Site Plan (DWG/PDF)',
        ),
      );
      await tester.pumpAndSettle();
      final next = find.text('Lanjut ke Review & Submit');
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('step 5'), findsOneWidget);
    });
  });
}
