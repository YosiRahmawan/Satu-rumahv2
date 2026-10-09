import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step3_screen.dart';

Widget _host({
  required ProviderContainer container,
  required Step3FilePickerSeam picker,
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
      child: MaterialApp(home: PengajuanStep3Screen(pickerSeam: picker)),
    ),
  );
}

PlatformFile _pdf(String name, int size, {String? path}) {
  return PlatformFile(name: name, size: size, path: path);
}

void main() {
  group('PengajuanStep3Screen', () {
    testWidgets('renders all 11 slots and mandatory/optional presentation', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _host(
          container: container,
          picker: ({required bool allowMultiple, allowedExtensions}) async =>
              const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daftar Berkas Persyaratan (11)'), findsOneWidget);
      expect(find.textContaining('1. Surat Permohonan'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('11. Proposal Rencana Pembangunan'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('11. Proposal Rencana Pembangunan'),
        findsOneWidget,
      );
      expect(find.text('Opsional'), findsOneWidget);
      expect(find.text('Wajib'), findsAtLeastNWidgets(1));
      expect(find.text('Belum Diunggah'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'supports single and multi-file selection with web-safe references',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        var multi = false;

        await tester.pumpWidget(
          _host(
            container: container,
            picker: ({required bool allowMultiple, allowedExtensions}) async {
              multi = allowMultiple;
              if (allowMultiple) {
                return [
                  _pdf('rekomendasi_a.pdf', 1024),
                  _pdf('rekomendasi_b.pdf', 2048),
                ];
              }
              return [_pdf('surat_permohonan.pdf', 1024)];
            },
          ),
        );
        await tester.pumpAndSettle();

        final uploadButton = find.widgetWithText(
          OutlinedButton,
          'Unggah Dokumen Permohonan',
        );
        tester.widget<OutlinedButton>(uploadButton).onPressed!();
        await tester.pumpAndSettle();
        expect(
          container
              .read(pengajuanFormProvider)
              .uploadedDocs['surat_permohonan'],
          'surat_permohonan.pdf',
        );

        await tester.scrollUntilVisible(
          find.text('Tambah File Rekomendasi'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        final multiButton = find.widgetWithText(
          OutlinedButton,
          'Tambah File Rekomendasi',
        );
        tester.widget<OutlinedButton>(multiButton).onPressed!();
        await tester.pumpAndSettle();
        expect(multi, isTrue);
        expect(
          container
              .read(pengajuanFormProvider)
              .multiUploadedDocs['rekomendasi_lingkungan'],
          hasLength(2),
        );
        expect(find.text('Multi-file: 2 Berkas Terlampir'), findsOneWidget);
      },
    );

    testWidgets(
      'cancellation leaves state unchanged and oversized file shows retryable error',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        var call = 0;

        await tester.pumpWidget(
          _host(
            container: container,
            picker: ({required bool allowMultiple, allowedExtensions}) async {
              call++;
              if (call == 1) return const [];
              return [_pdf('too_large.pdf', 11 * 1024 * 1024)];
            },
          ),
        );
        await tester.pumpAndSettle();

        final uploadButton = find.widgetWithText(
          OutlinedButton,
          'Unggah Dokumen Permohonan',
        );
        tester.widget<OutlinedButton>(uploadButton).onPressed!();
        await tester.pumpAndSettle();
        expect(container.read(pengajuanFormProvider).uploadedDocs, isEmpty);
        expect(
          find.text('Tidak ada berkas dipilih. Data tetap tidak berubah.'),
          findsOneWidget,
        );

        final retryUploadButton = find.widgetWithText(
          OutlinedButton,
          'Unggah Dokumen Permohonan',
        );
        tester.widget<OutlinedButton>(retryUploadButton).onPressed!();
        await tester.pumpAndSettle();
        expect(find.text('Gagal'), findsOneWidget);
        expect(find.text('Coba Lagi'), findsOneWidget);
        expect(container.read(pengajuanFormProvider).uploadedDocs, isEmpty);
      },
    );

    testWidgets(
      'preserves state and avoids overflow at target sizes and text scale',
      (tester) async {
        for (final size in [const Size(360, 800), const Size(412, 900)]) {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final notifier = container.read(pengajuanFormProvider.notifier);
          notifier.uploadDocument('surat_permohonan', 'surat.pdf');

          await tester.pumpWidget(
            _host(
              container: container,
              size: size,
              textScale: 2,
              picker:
                  ({required bool allowMultiple, allowedExtensions}) async =>
                      const [],
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            container
                .read(pengajuanFormProvider)
                .uploadedDocs['surat_permohonan'],
            'surat.pdf',
          );
        }
      },
    );
  });
}
