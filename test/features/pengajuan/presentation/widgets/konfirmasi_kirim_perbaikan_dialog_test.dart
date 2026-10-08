import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/perbarui_berkas_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/konfirmasi_kirim_perbaikan_dialog.dart';

void main() {
  Widget buildDialogTestWidget({
    int jumlahBerkas = 3,
    Future<void> Function()? onConfirm,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showKonfirmasiKirimPerbaikanDialog(
                context: context,
                jumlahBerkas: jumlahBerkas,
                onConfirm: onConfirm,
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  Widget buildScreenTestWidget({
    String id = 'REG-2026-0142',
    double textScale = 1.0,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: PerbaruiBerkasScreen(id: id),
      ),
    );
  }

  group('Fase 4 - Konfirmasi Kirim Perbaikan Dialog Widget Tests', () {
    testWidgets('renders dialog elements and dynamic count correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialogTestWidget(jumlahBerkas: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.textContaining('3 berkas'), findsOneWidget);
      expect(
        find.textContaining(
          'yang telah diperbarui akan dikirimkan ke Admin Verifikator. Anda tidak dapat mengubah berkas selama proses verifikasi berlangsung.',
        ),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Kirim'), findsOneWidget);
    });

    testWidgets('dynamic file count updates for different numbers', (
      tester,
    ) async {
      await tester.pumpWidget(buildDialogTestWidget(jumlahBerkas: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('5 berkas'), findsOneWidget);
    });

    testWidgets('tapping Batal closes dialog without calling onConfirm', (
      tester,
    ) async {
      bool confirmCalled = false;
      await tester.pumpWidget(
        buildDialogTestWidget(
          jumlahBerkas: 3,
          onConfirm: () async {
            confirmCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Perbaikan Berkas?'), findsNothing);
      expect(confirmCalled, isFalse);
    });

    testWidgets('tapping Ya, Kirim calls onConfirm and prevents double submit', (
      tester,
    ) async {
      int confirmCalls = 0;
      await tester.pumpWidget(
        buildDialogTestWidget(
          jumlahBerkas: 3,
          onConfirm: () async {
            confirmCalls++;
            await Future.delayed(const Duration(milliseconds: 100));
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Ya, Kirim twice rapidly
      await tester.tap(find.text('Ya, Kirim'));
      await tester.pump(const Duration(milliseconds: 20));
      // Second tap while submitting should be ignored
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(confirmCalls, equals(1));
      expect(find.text('Kirim Perbaikan Berkas?'), findsNothing);
    });

    testWidgets('dialog responsive at 360dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildDialogTestWidget(jumlahBerkas: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
    });

    testWidgets('dialog supports 200% text scale without overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDialogTestWidget(jumlahBerkas: 3, textScale: 2.0),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
    });
  });

  group('Fase 2 -> Fase 3 -> Fase 2 -> Fase 4 Integration Flow Tests', () {
    testWidgets(
      'complete user flow: update all documents and confirm sending in Fase 4',
      (tester) async {
        await tester.pumpWidget(buildScreenTestWidget());
        await tester.pumpAndSettle();

        // Initial: 1/3 Berkas updated
        expect(find.text('1/3 Berkas'), findsOneWidget);

        // Update Card 2 (Bukti Kepemilikan Lahan): Fase 2 -> Fase 3
        await tester.scrollUntilVisible(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
        );
        await tester.pumpAndSettle();

        // Fase 3 -> Fase 2: Kirim Perbaikan pops back
        expect(find.text('Kirim Perbaikan'), findsOneWidget);
        await tester.tap(find.text('Kirim Perbaikan'));
        await tester.pumpAndSettle();

        // Now 2/3 Berkas updated
        expect(find.text('2/3 Berkas'), findsOneWidget);

        // Update Card 3 (Site Plan): Fase 2 -> Fase 3
        await tester.scrollUntilVisible(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas (3 File)'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas (3 File)'),
        );
        await tester.pumpAndSettle();

        // Fase 3 -> Fase 2: Kirim Perbaikan pops back
        expect(find.text('Kirim Perbaikan'), findsOneWidget);
        await tester.tap(find.text('Kirim Perbaikan'));
        await tester.pumpAndSettle();

        // Clear snackbars immediately
        ScaffoldMessenger.of(
          tester.element(find.byType(PerbaruiBerkasScreen)),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        // Now 3/3 Berkas updated! All revised documents are ready.
        expect(find.text('3/3 Berkas'), findsOneWidget);
        expect(
          find.text('Semua berkas siap ditinjau dan dikirim'),
          findsOneWidget,
        );

        // Tap Tinjau Perbaikan -> Fase 4 Dialog appears!
        await tester.tap(find.text('Tinjau Perbaikan'));
        await tester.pumpAndSettle();

        expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
        expect(find.textContaining('3 berkas'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Ya, Kirim'), findsOneWidget);

        // Test Batal: closes dialog without sending
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Kirim Perbaikan Berkas?'), findsNothing);
        expect(find.text('3/3 Berkas'), findsOneWidget);

        // Re-open Fase 4 dialog and confirm with Ya, Kirim
        await tester.tap(find.text('Tinjau Perbaikan'));
        await tester.pumpAndSettle();

        expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
        await tester.tap(find.text('Ya, Kirim'));
        await tester.pumpAndSettle();

        // Verifies success SnackBar and transition to Fase 5 (StatusPerbaikanBerkasScreen)
        expect(
          find.text('Revisi berkas berhasil dikirim ke Verifikator!'),
          findsOneWidget,
        );
        expect(find.text('Status Pengajuan'), findsOneWidget);
        expect(find.text('Perbaikan Berhasil Dikirim'), findsOneWidget);
        expect(find.text('Lihat Detail Pengajuan'), findsOneWidget);
        expect(find.text('Kembali ke Beranda'), findsOneWidget);
      },
    );
  });
}
