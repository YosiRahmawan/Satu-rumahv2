import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_list_view_provider.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_empty_state.dart';

List<Pengajuan> _sampleItems() => [
  Pengajuan(
    id: 'REG-2026-001',
    namaPerumahan: 'Green Tasik 2026',
    namaPt: 'PT Tasik Jaya',
    namaDirektur: 'Direktur A',
    npwpPerusahaan: '12345',
    luasLahan: 1000,
    jumlahUnit: 10,
    tipePerumahan: 'Cluster',
    status: 'Dalam Proses',
    tanggal: '12 September 2026',
    statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
    uploadedDocs: const {},
  ),
  Pengajuan(
    id: 'REG-2025-002',
    namaPerumahan: 'Harmoni Tasik 2025',
    namaPt: 'PT Tasik Abadi',
    namaDirektur: 'Direktur B',
    npwpPerusahaan: '67890',
    luasLahan: 2000,
    jumlahUnit: 20,
    tipePerumahan: 'Subsidi',
    status: 'Dalam Proses',
    tanggal: '15 Agustus 2025',
    statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
    uploadedDocs: const {},
  ),
];

class _SubmissionsNotifier extends PengajuanListNotifier {
  _SubmissionsNotifier(List<Pengajuan> items) {
    state = items;
  }
}

Widget _wrapWidget(
  Widget child, {
  double width = 390,
  double height = 844,
  double textScale = 1.0,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16.0), child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('Pengajuan Empty State Google Stitch Redesign Tests', () {
    testWidgets(
      '1. Empty state renders white card, architectural illustration, and all text elements',
      (tester) async {
        await tester.pumpWidget(
          _wrapWidget(
            PengajuanEmptyState(
              isFilteredEmpty: true,
              totalRegistered: 6,
              onReset: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Card & Illustration
        expect(find.byType(SvgPicture), findsOneWidget);

        // Verbatim Headline
        expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);

        // Verbatim Subtitle
        expect(
          find.text(
            'Coba ubah kata kunci, status, atau filter tahun untuk melihat hasil lainnya.',
          ),
          findsOneWidget,
        );

        // Action Button
        expect(find.text('Reset pencarian dan filter'), findsOneWidget);

        // Supporting Microtext
        expect(
          find.text('Semua data pengajuan akan ditampilkan kembali.'),
          findsOneWidget,
        );

        // Record Counter & Prototype Banner are eliminated
        expect(find.textContaining('pengajuan terdaftar'), findsNothing);
        expect(find.textContaining('Mode prototipe lokal'), findsNothing);
      },
    );

    testWidgets(
      '2. Displays honest empty database state when isFilteredEmpty is false',
      (tester) async {
        bool createNewCalled = false;
        await tester.pumpWidget(
          _wrapWidget(
            PengajuanEmptyState(
              isFilteredEmpty: false,
              totalRegistered: 0,
              onCreateNew: () => createNewCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.text('Belum ada pengajuan'), findsOneWidget);
        expect(
          find.text(
            'Mulai pengajuan pertama Anda untuk mengajukan site plan dan dokumen perumahan.',
          ),
          findsOneWidget,
        );
        // Primary CTA Buat Pengajuan must be rendered
        expect(find.text('Buat Pengajuan'), findsOneWidget);
        await tester.tap(find.text('Buat Pengajuan'));
        await tester.pumpAndSettle();
        expect(createNewCalled, isTrue);

        // Reset button must NOT be rendered when there are no filters
        expect(find.text('Reset pencarian dan filter'), findsNothing);
      },
    );

    testWidgets(
      '3. Synchronous reset completes immediately without artificial delay',
      (tester) async {
        bool resetCalled = false;
        await tester.pumpWidget(
          _wrapWidget(
            PengajuanEmptyState(
              isFilteredEmpty: true,
              totalRegistered: 2,
              onReset: () {
                resetCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.text('Reset pencarian dan filter');
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(resetCalled, isTrue);
        // No active rotation animation on button
        expect(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(RotationTransition),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '4. Asynchronous reset displays smooth rotation loading animation and prevents double-tap',
      (tester) async {
        final completer = Completer<void>();
        int callCount = 0;

        await tester.pumpWidget(
          _wrapWidget(
            PengajuanEmptyState(
              isFilteredEmpty: true,
              totalRegistered: 2,
              onReset: () {
                callCount++;
                return completer.future;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.text('Reset pencarian dan filter');
        await tester.tap(buttonFinder);
        await tester.pump(); // Start async call

        final buttonRotationFinder = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(RotationTransition),
        );

        // Rotation animation is active during async operation
        expect(callCount, equals(1));
        expect(buttonRotationFinder, findsOneWidget);

        // Verify double-tap prevention: tapping while loading should not invoke callback again
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(callCount, equals(1));

        // Advance animation frames
        await tester.pump(const Duration(milliseconds: 200));
        expect(buttonRotationFinder, findsOneWidget);

        // Complete async process
        completer.complete();
        await tester.pumpAndSettle();

        // Loading state cleared
        expect(callCount, equals(1));
        expect(buttonRotationFinder, findsNothing);
      },
    );

    testWidgets(
      '5. Responsive layout across 360dp, 390dp, and 412dp viewports without overflow',
      (tester) async {
        for (final width in [360.0, 390.0, 412.0]) {
          await tester.pumpWidget(
            _wrapWidget(
              PengajuanEmptyState(
                isFilteredEmpty: true,
                totalRegistered: 5,
                onReset: () {},
              ),
              width: width,
              height: 700,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);
          expect(find.text('Reset pencarian dan filter'), findsOneWidget);
        }
      },
    );

    testWidgets(
      '6. Supports 150% and 200% text scale gracefully without layout clipping or overflow',
      (tester) async {
        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            _wrapWidget(
              PengajuanEmptyState(
                isFilteredEmpty: true,
                totalRegistered: 5,
                onReset: () {},
              ),
              width: 360,
              height: 800,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);
        }
      },
    );

    testWidgets(
      '7. End-to-end screen integration: Reset recovers search, status, and year filters to default',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(_sampleItems()),
            ),
          ],
        );
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Set initial non-matching filters
        container
            .read(pengajuanListQueryProvider.notifier)
            .search('nonexistent_word');
        container
            .read(pengajuanListQueryProvider.notifier)
            .filter(PengajuanFilter.selesai);
        container.read(pengajuanListQueryProvider.notifier).year(2024);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(390, 844)),
                child: Scaffold(body: PengajuanSayaListScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Empty State must be rendered
        expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.textContaining('pengajuan terdaftar'), findsNothing);
        expect(find.textContaining('Mode prototipe lokal'), findsNothing);

        // Tap Reset button
        final resetButton = find.text('Reset pencarian dan filter');
        expect(resetButton, findsOneWidget);
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton);
        await tester.pumpAndSettle();

        // Query state must be restored to defaults
        final query = container.read(pengajuanListQueryProvider);
        expect(query.search, isEmpty);
        expect(query.filter, equals(PengajuanFilter.semua));
        expect(query.year, isNull);

        // Data is recovered and empty state disappears
        expect(find.text('Tidak ada pengajuan ditemukan'), findsNothing);
        expect(find.text('Green Tasik 2026'), findsOneWidget);
        expect(find.text('Harmoni Tasik 2025'), findsOneWidget);
      },
    );

    testWidgets('8. No second/duplicate FloatingActionButton is introduced', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith((ref) => _SubmissionsNotifier([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: PengajuanSayaListScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PengajuanSayaListScreen does not own a FAB (FAB is owned by dashboard scaffold)
      // Verify no extra FAB was added inside the empty state or screen
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
