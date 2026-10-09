import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step1_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_step2_screen.dart';

void main() {
  Widget createTestWidget({
    required WidgetTester tester,
    ProviderContainer? container,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    GoRouter? router,
    FilePickerSeam? pickerSeam,
  }) {
    tester.view.physicalSize = Size(size.width, size.height * (textScale > 1.5 ? 2.0 : 1.2));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final effectiveRouter =
        router ??
        GoRouter(
          initialLocation: '/pengajuan/step2',
          routes: [
            GoRoute(
              path: '/pengajuan/step1',
              builder: (context, state) => const PengajuanStep1Screen(),
            ),
            GoRoute(
              path: '/pengajuan/step2',
              builder: (context, state) =>
                  PengajuanStep2Screen(pickerSeam: pickerSeam),
            ),
            GoRoute(
              path: '/pengajuan/step3',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Step 3 Screen'))),
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

  group('PengajuanStep2Screen (Fase 2 - Berkas PT Prototype Tests)', () {
    testWidgets('renders canonical hero header, agency pill, and StepperHeader', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(tester: tester));
      await tester.pumpAndSettle();

      // Canonical PengajuanStepHeader elements
      expect(find.text('Pengajuan Baru'), findsOneWidget);
      expect(find.text('Langkah 2 dari 5'), findsOneWidget);
      expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsOneWidget);

      // Stepper 5 steps
      expect(find.text('Data PT'), findsOneWidget);
      expect(find.text('Berkas PT'), findsOneWidget);
      expect(find.text('Perumahan'), findsOneWidget);
      expect(find.text('Teknis'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      // Section summary card
      expect(
        find.text('Kelengkapan Berkas Legalitas Perusahaan'),
        findsOneWidget,
      );
      expect(find.text('Wajib 5'), findsOneWidget);
      expect(find.text('0 dari 5 berkas dipilih'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // 5 Document slot titles
      expect(find.text('1. KTP-el Pemohon / Direktur Utama *'), findsOneWidget);
      expect(find.text('2. Nomor Induk Berusaha (NIB) *'), findsOneWidget);
      expect(find.text('3. NPWP Perusahaan *'), findsOneWidget);
      expect(find.text('4. Bukti Keanggotaan Asosiasi *'), findsOneWidget);
      expect(
        find.text('5. Akta Pendirian & SK Kemenkumham *'),
        findsOneWidget,
      );

      // 5 "Belum Unggah" badges initially
      expect(find.text('Belum Unggah'), findsNWidgets(5));

      // Next button is disabled initially
      final nextButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lanjut ke Langkah 3'),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('canceling file picker does not mutate state or show false selection', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestWidget(
          tester: tester,
          container: container,
          pickerSeam: ({allowedExtensions}) async => null, // User cancelled
        ),
      );
      await tester.pumpAndSettle();

      // Tap first "Pilih Berkas" button
      final pilihButtons = find.widgetWithText(OutlinedButton, 'Pilih Berkas');
      await tester.ensureVisible(pilihButtons.first);
      await tester.tap(pilihButtons.first);
      await tester.pumpAndSettle();

      // State remains unchanged: 0 of 5 selected, no error
      expect(find.text('0 dari 5 berkas dipilih'), findsOneWidget);
      expect(find.text('Belum Unggah'), findsNWidgets(5));
      expect(find.text('Gagal'), findsNothing);
      expect(container.read(pengajuanFormProvider).isStep2Valid, isFalse);
    });

    testWidgets('rejects file larger than 10 MB with actionable Gagal state and retry', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 14.2 MB oversized PDF
      final oversizedFile = PlatformFile(
        name: 'Akta_Perusahaan_Scan_HD.pdf',
        size: 14 * 1024 * 1024 + 200 * 1024, // 14.2 MB
      );

      await tester.pumpWidget(
        createTestWidget(
          tester: tester,
          container: container,
          pickerSeam: ({allowedExtensions}) async => oversizedFile,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 5th slot (Akta & SK)
      final pilihButtons = find.widgetWithText(OutlinedButton, 'Pilih Berkas');
      await tester.ensureVisible(pilihButtons.at(4));
      await tester.tap(pilihButtons.at(4));
      await tester.pumpAndSettle();

      // Error state displayed
      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text('Akta_Perusahaan_Scan_HD.pdf'), findsOneWidget);
      expect(find.text('File melebihi batas maksimal 10 MB.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Ganti Berkas'), findsOneWidget);

      // Oversized file does NOT count as valid
      expect(find.text('0 dari 5 berkas dipilih'), findsOneWidget);
      expect(container.read(pengajuanFormProvider).uploadedDocs['legalitas'], isNull);
      expect(container.read(pengajuanFormProvider).isStep2Valid, isFalse);
    });

    testWidgets('rejects non-PDF format with actionable error state', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final nonPdfFile = PlatformFile(
        name: 'foto_ktp.jpg',
        size: 2 * 1024 * 1024,
      );

      await tester.pumpWidget(
        createTestWidget(
          tester: tester,
          container: container,
          pickerSeam: ({allowedExtensions}) async => nonPdfFile,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1st slot (KTP)
      final pilihButtons = find.widgetWithText(OutlinedButton, 'Pilih Berkas');
      await tester.ensureVisible(pilihButtons.first);
      await tester.tap(pilihButtons.first);
      await tester.pumpAndSettle();

      // Error state displayed
      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text('foto_ktp.jpg'), findsOneWidget);
      expect(find.text('Format berkas harus berupa dokumen PDF.'), findsOneWidget);
      expect(container.read(pengajuanFormProvider).uploadedDocs['ktp'], isNull);
    });

    testWidgets('successfully uploads valid PDF, updates progress, and supports delete', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final validKtp = PlatformFile(
        name: 'KTP_Direktur_Hendra_Gunawan.pdf',
        size: 1400 * 1024, // 1.4 MB
        path: '/dummy/KTP_Direktur_Hendra_Gunawan.pdf',
      );

      await tester.pumpWidget(
        createTestWidget(
          tester: tester,
          container: container,
          pickerSeam: ({allowedExtensions}) async => validKtp,
        ),
      );
      await tester.pumpAndSettle();

      // Pick KTP
      final pilihButtons = find.widgetWithText(OutlinedButton, 'Pilih Berkas');
      await tester.ensureVisible(pilihButtons.first);
      await tester.tap(pilihButtons.first);
      await tester.pumpAndSettle();

      // Verified honest status
      expect(find.text('Siap Dikirim'), findsOneWidget);
      expect(find.text('KTP_Direktur_Hendra_Gunawan.pdf'), findsOneWidget);
      expect(find.text('1 dari 5 berkas dipilih'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(
        container.read(pengajuanFormProvider).uploadedDocs['ktp'],
        equals('/dummy/KTP_Direktur_Hendra_Gunawan.pdf'),
      );

      // Delete action restores slot to empty
      final deleteBtn = find.byTooltip('Hapus berkas');
      expect(deleteBtn, findsOneWidget);
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('0 dari 5 berkas dipilih'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Belum Unggah'), findsNWidgets(5));
      expect(container.read(pengajuanFormProvider).uploadedDocs['ktp'], isNull);
    });

    testWidgets('completing all 5 slots enables Step 3 navigation', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-fill 5 slots in provider
      final notifier = container.read(pengajuanFormProvider.notifier);
      notifier.uploadDocument('ktp', 'KTP_Direktur.pdf');
      notifier.uploadDocument('nib', 'NIB_Perusahaan.pdf');
      notifier.uploadDocument('npwp_doc', 'NPWP_Perusahaan.pdf');
      notifier.uploadDocument('asosiasi', 'Bukti_Asosiasi.pdf');
      notifier.uploadDocument('legalitas', 'Akta_Legalitas.pdf');

      await tester.pumpWidget(
        createTestWidget(tester: tester, container: container),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 dari 5 berkas dipilih'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Siap Dikirim'), findsNWidgets(5));

      // Lanjut ke Langkah 3 button is enabled
      final nextButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lanjut ke Langkah 3'),
      );
      expect(nextButton.onPressed, isNotNull);

      // Tap next button navigates to Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut ke Langkah 3'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 Screen'), findsOneWidget);
    });

    testWidgets('Simpan Draft persists session data and provides truthful feedback', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(tester: tester, container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Draft'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Draft formulir disimpan untuk sesi ini. Perubahan aman selama aplikasi aktif.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('navigating back preserves form state without resetting', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Step 1 data
      final notifier = container.read(pengajuanFormProvider.notifier);
      notifier.updateNamaPerumahan('Pesona Tasik Indah');
      notifier.uploadDocument('ktp', 'KTP_Direktur.pdf');

      await tester.pumpWidget(createTestWidget(tester: tester, container: container));
      await tester.pumpAndSettle();

      // Tap Kembali
      await tester.tap(find.widgetWithText(OutlinedButton, 'Kembali'));
      await tester.pumpAndSettle();

      // Still in state
      expect(
        container.read(pengajuanFormProvider).namaPerumahan,
        equals('Pesona Tasik Indah'),
      );
      expect(
        container.read(pengajuanFormProvider).uploadedDocs['ktp'],
        equals('KTP_Direktur.pdf'),
      );
    });

    testWidgets('renders cleanly without overflow at 360dp width', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(tester: tester, size: const Size(360, 640)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pengajuan Baru'), findsOneWidget);
      expect(find.text('Kelengkapan Berkas Legalitas Perusahaan'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 412dp width', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(tester: tester, size: const Size(412, 892)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pengajuan Baru'), findsOneWidget);
    });

    testWidgets('renders safely under 200% text scaling (2.0x)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          tester: tester,
          size: const Size(390, 844),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pengajuan Baru'), findsOneWidget);
    });
  });
}
