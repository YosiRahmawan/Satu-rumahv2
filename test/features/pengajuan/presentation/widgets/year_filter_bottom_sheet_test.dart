import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_list_view_provider.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_list_filters.dart';

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
  Pengajuan(
    id: 'REG-2024-003',
    namaPerumahan: 'Pesona Tasik 2024',
    namaPt: 'PT Tasik Pesona',
    namaDirektur: 'Direktur C',
    npwpPerusahaan: '11223',
    luasLahan: 3000,
    jumlahUnit: 30,
    tipePerumahan: 'Komersil',
    status: 'Perlu Perbaikan',
    tanggal: '10 Mei 2024',
    statusTahap: StatusTahapPengajuan.perluPerbaikan,
    uploadedDocs: const {},
  ),
];

class _SubmissionsNotifier extends PengajuanListNotifier {
  _SubmissionsNotifier(List<Pengajuan> items) {
    state = items;
  }
}

Widget _buildTestApp({
  required ProviderContainer container,
  double width = 390,
  double height = 844,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: PengajuanListFilters(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Google Stitch Year Filter Bottom Sheet Tests', () {
    testWidgets('1. Opens Filter Tahun bottom sheet with header, trigger, and options', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Tap filter tahun button
      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      // Header verifies
      expect(find.text('Filter Tahun'), findsOneWidget);
      expect(
        find.text('Pilih tahun pengajuan yang ingin ditampilkan.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Tutup filter'), findsOneWidget);
      expect(find.text('PERIODE PENGAJUAN'), findsOneWidget);

      // Options derived from data source
      expect(find.text('Semua Tahun'), findsWidgets);
      expect(find.text('Tahun 2026'), findsOneWidget);
      expect(find.text('Tahun 2025'), findsOneWidget);
      expect(find.text('Tahun 2024'), findsOneWidget);

      // Footer buttons
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
    });

    testWidgets('2. Expand and collapse dropdown toggles options visibility', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      // Dropdown is open by default
      expect(find.text('Tahun 2026'), findsOneWidget);

      // Tap dropdown trigger to collapse
      await tester.tap(find.text('Semua Tahun').first);
      await tester.pumpAndSettle();

      // Options collapsed
      expect(find.text('Tahun 2026'), findsNothing);

      // Tap again to re-expand
      await tester.tap(find.text('Semua Tahun').first);
      await tester.pumpAndSettle();

      expect(find.text('Tahun 2026'), findsOneWidget);
    });

    testWidgets('3. Searches year in dropdown and shows empty state when not found', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      // Type search query
      final searchInput = find.widgetWithText(TextField, 'Cari tahun...');
      expect(searchInput, findsOneWidget);

      await tester.enterText(searchInput, '2025');
      await tester.pumpAndSettle();

      expect(find.text('Tahun 2025'), findsOneWidget);
      expect(find.text('Tahun 2026'), findsNothing);
      expect(find.text('Tahun 2024'), findsNothing);

      // Search non-existent year
      await tester.enterText(searchInput, '1990');
      await tester.pumpAndSettle();

      expect(find.text('Tahun tidak ditemukan'), findsOneWidget);
    });

    testWidgets('4. Selects a year updating temporary selection without applying immediately', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      // Tap 2025
      await tester.tap(find.text('Tahun 2025'));
      await tester.pumpAndSettle();

      // Applied state in query is still null before pressing Terapkan
      expect(container.read(pengajuanListQueryProvider).year, isNull);

      // Checkmark displayed for selected item
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('5. Apply filter commits selection and updates query state', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tahun 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      // Bottom sheet closed
      expect(find.text('Filter Tahun'), findsNothing);

      // Query state updated to 2026
      expect(container.read(pengajuanListQueryProvider).year, 2026);
      expect(find.textContaining('Periode: 2026'), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
      // Extra floating InputChip is eliminated
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('6. Reset selection returns temporary selection to Semua Tahun', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tahun 2024'));
      await tester.pumpAndSettle();

      // Press Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Apply reset
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      expect(container.read(pengajuanListQueryProvider).year, isNull);
    });

    testWidgets('7. Dismissing via close button (X) preserves applied filter', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Set initial applied year to 2025
      container.read(pengajuanListQueryProvider.notifier).year(2025);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();

      // Pick 2026 but do NOT apply
      await tester.tap(find.text('Tahun 2026'));
      await tester.pumpAndSettle();

      // Tap close button X
      await tester.tap(find.byTooltip('Tutup filter'));
      await tester.pumpAndSettle();

      // Year remains 2025
      expect(container.read(pengajuanListQueryProvider).year, 2025);
    });

    testWidgets('8. Combines status, search, and year filters seamlessly', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          pengajuanListProvider.overrideWith(
            (ref) => _SubmissionsNotifier(_sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Set search 'Pesona' and status 'Perlu Perbaikan'
      container.read(pengajuanListQueryProvider.notifier).search('Pesona');
      container
          .read(pengajuanListQueryProvider.notifier)
          .filter(PengajuanFilter.perbaikan);

      // Open year filter and apply 2024
      await tester.tap(find.byTooltip('Filter tahun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tahun 2024'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      final filtered = container.read(filteredPengajuanProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'REG-2024-003');
    });

    testWidgets('9. Responsive layouts without overflow across 360dp, 390dp, and 412dp', (
      tester,
    ) async {
      for (final width in [360.0, 390.0, 412.0]) {
        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(_sampleItems()),
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestApp(container: container, width: width, height: 740),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Filter Tahun'), findsOneWidget);
        expect(find.text('Terapkan Filter'), findsOneWidget);

        // Close sheet before next viewport
        await tester.tap(find.byTooltip('Tutup filter'));
        await tester.pumpAndSettle();
        container.dispose();
      }
    });

    testWidgets(
      '10. Smoothly animates sheet height at start, mid, and end of collapse & expand transition',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(_sampleItems()),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(_buildTestApp(container: container));
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();

        final sheetFinder = find.byType(BottomSheet);
        expect(sheetFinder, findsOneWidget);

        // 1. Initial State: Fully Expanded
        final expandedHeight = tester.getSize(sheetFinder).height;
        expect(expandedHeight, greaterThan(200));

        // 2. Start Collapse Transition
        await tester.tap(find.text('Semua Tahun').first);
        await tester.pump(); // Dispatch tap event & start controller.reverse()
        // Advance to mid-collapse (around 140ms into 280ms duration)
        await tester.pump(const Duration(milliseconds: 140));

        final midCollapseHeight = tester.getSize(sheetFinder).height;
        // Mid height must be strictly between expanded and collapsed
        expect(midCollapseHeight, lessThan(expandedHeight));

        // Let collapse finish
        await tester.pumpAndSettle();
        final collapsedHeight = tester.getSize(sheetFinder).height;
        expect(collapsedHeight, lessThan(midCollapseHeight));
        expect(find.text('Tahun 2026'), findsNothing);

        // 3. Start Expand Transition
        await tester.tap(find.text('Semua Tahun').first);
        await tester.pump(); // Dispatch tap event & start controller.forward()
        // Advance to mid-expand (around 175ms into 350ms duration)
        await tester.pump(const Duration(milliseconds: 175));

        final midExpandHeight = tester.getSize(sheetFinder).height;
        // Mid height must be strictly greater than collapsed and less than expanded
        expect(midExpandHeight, greaterThan(collapsedHeight));
        expect(midExpandHeight, lessThan(expandedHeight));

        // Let expand finish
        await tester.pumpAndSettle();
        final finalHeight = tester.getSize(sheetFinder).height;
        expect(finalHeight, equals(expandedHeight));
        expect(find.text('Tahun 2026'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Rapid dropdown toggles smoothly without exceptions or state corruption',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(_sampleItems()),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(_buildTestApp(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();

        final triggerFinder = find.text('Semua Tahun').first;

        // Toggle rapidly mid-animation
        await tester.tap(triggerFinder);
        await tester.pump(const Duration(milliseconds: 60)); // reverse started
        await tester.tap(triggerFinder);
        await tester.pump(const Duration(milliseconds: 50)); // forwarded back
        await tester.tap(triggerFinder);
        await tester.pump(const Duration(milliseconds: 40)); // reversed again
        await tester.pumpAndSettle();

        // Must settle cleanly without unhandled exception
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '12. Long list of years is constrained and bottom sheet re-opens cleanly',
      (tester) async {
        final manyYears = List.generate(
          15,
          (i) => Pengajuan(
            id: 'REG-202$i-001',
            namaPerumahan: 'Perumahan $i',
            namaPt: 'PT $i',
            namaDirektur: 'Direktur $i',
            npwpPerusahaan: '12345',
            luasLahan: 1000,
            jumlahUnit: 10,
            tipePerumahan: 'Cluster',
            status: 'Dalam Proses',
            tanggal: '12 September 202${i % 10}',
            statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
            uploadedDocs: const {},
          ),
        );

        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(manyYears),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(_buildTestApp(container: container));
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();
        expect(find.text('Filter Tahun'), findsOneWidget);

        // Close bottom sheet
        await tester.tap(find.byTooltip('Tutup filter'));
        await tester.pumpAndSettle();
        expect(find.text('Filter Tahun'), findsNothing);

        // Re-open bottom sheet
        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();
        expect(find.text('Filter Tahun'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '13. Compact period indicator lifecycle: hidden when all years, visible when selected, and Ubah button re-opens sheet with selected year',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            pengajuanListProvider.overrideWith(
              (ref) => _SubmissionsNotifier(_sampleItems()),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(_buildTestApp(container: container));
        await tester.pumpAndSettle();

        // 1. Initial State: All Years -> Indicator hidden
        expect(find.textContaining('Periode:'), findsNothing);
        expect(find.text('Ubah'), findsNothing);

        // 2. Select Year 2025 and apply
        await tester.tap(find.byTooltip('Filter tahun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tahun 2025'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pumpAndSettle();

        // Indicator is now visible with 2025
        expect(find.textContaining('Periode: 2025'), findsOneWidget);
        expect(find.text('Ubah'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);

        // 3. Tap 'Ubah' -> Opens bottom sheet with 2025 pre-selected
        await tester.tap(find.text('Ubah'));
        await tester.pumpAndSettle();

        expect(find.text('Filter Tahun'), findsOneWidget);
        // Pre-selected trigger label is 'Tahun 2025'
        expect(find.text('Tahun 2025'), findsWidgets);

        // 4. Change to 2024 and apply
        await tester.tap(find.text('Tahun 2024'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pumpAndSettle();

        // Indicator updated to 2024
        expect(find.textContaining('Periode: 2024'), findsOneWidget);
        expect(find.textContaining('Periode: 2025'), findsNothing);

        // 5. Open sheet, reset filter and apply
        await tester.tap(find.text('Ubah'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pumpAndSettle();

        // Indicator hidden again
        expect(find.textContaining('Periode:'), findsNothing);
        expect(find.text('Ubah'), findsNothing);
      },
    );
  });
}
