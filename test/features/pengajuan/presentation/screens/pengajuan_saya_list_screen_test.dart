import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:satu_rumah/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_list_view_provider.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_list_card.dart';

class _Submissions extends PengajuanListNotifier {
  _Submissions(List<Pengajuan> items) {
    state = items;
  }
}

List<Pengajuan> _items() => [
  Pengajuan(
    id: 'REG-2026-0142',
    namaPerumahan: 'Perumahan Green Tasik',
    namaPt: 'PT Contoh',
    namaDirektur: 'Direktur',
    npwpPerusahaan: '123',
    luasLahan: 18500,
    jumlahUnit: 120,
    tipePengajuan: 'Pengajuan Site Plan Baru (Tahap 2)',
    tipePerumahan: 'Subsidi',
    status: 'Perlu Perbaikan',
    statusTahap: StatusTahapPengajuan.perluPerbaikan,
    tanggal: '12 September 2026',
    diperbarui: 'Diperbarui 2 hari lalu',
    uploadedDocs: {},
    dokumenPerluRevisi: ['ktp', 'nib'],
    catatanPerbaikan: 'Lengkapi berkas revisi.',
  ),
  Pengajuan(
    id: 'REG-2026-0095',
    namaPerumahan: 'Mutiara Regency Tasik',
    namaPt: 'PT Contoh',
    namaDirektur: 'Direktur',
    npwpPerusahaan: '123',
    luasLahan: 24200,
    jumlahUnit: 165,
    tipePengajuan: 'Perubahan Site Plan (Tahap 1B)',
    tipePerumahan: 'Komersil',
    status: 'Terjadwal',
    statusTahap: StatusTahapPengajuan.surveyLapangan,
    tanggal: '15 Juli 2026',
    uploadedDocs: {},
  ),
  Pengajuan(
    id: 'REG-2025-0310',
    namaPerumahan: 'Grand Tasik Harmoni',
    namaPt: 'PT Contoh',
    namaDirektur: 'Direktur',
    npwpPerusahaan: '123',
    luasLahan: 32000,
    jumlahUnit: 210,
    tipePengajuan: 'Pengajuan Site Plan Awal (Tahap 1)',
    tipePerumahan: 'Komersil',
    status: 'Final',
    statusTahap: StatusTahapPengajuan.selesai,
    tanggal: '18 Desember 2025',
    nomorSk: '412/SK-SP/DPKP/2025',
    tanggalSk: '18 Des 2025',
    uploadedDocs: {},
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Pengajuan>? items,
  double width = 390,
  double height = 844,
  double textScale = 1,
  bool dashboard = false,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      pengajuanListProvider.overrideWith(
        (ref) => _Submissions(items ?? _items()),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(roleSessionProvider.notifier).signIn(AppRole.developer);
  container.read(dashboardTabProvider.notifier).state = 1;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => dashboard
            ? const DashboardScreen()
            : const PengajuanSayaListScreen(),
      ),
      GoRoute(
        path: '/pengajuan/detail/:id',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Detail pengajuan')),
          body: Text(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/pengajuan/step1',
        builder: (_, __) => const Scaffold(body: Text('Form pengajuan baru')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(
            key: const ValueKey('qa-capture'),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder get _scroll => find
    .descendant(
      of: find.byKey(const PageStorageKey('developer-submissions')),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  test('filters use stages, including scheduled and final legacy labels', () {
    final items = _items();
    expect(items.where(PengajuanFilter.proses.matches), [items[1]]);
    expect(items.where(PengajuanFilter.selesai.matches), [items[2]]);
    expect(items.where(PengajuanFilter.perbaikan.matches), [items[0]]);
    expect(pengajuanYear(items[0]), 2026);
    expect(pengajuanYear(items[0].copyWith(tanggal: 'Belum tersedia')), isNull);
    expect(pengajuanYear(items[0].copyWith(tanggal: '2026-10-05')), 2026);
  });

  testWidgets('search and filter reset recover an empty result', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), '  mutiara  ');
    await tester.pumpAndSettle();
    expect(find.text('Mutiara Regency Tasik'), findsOneWidget);
    expect(find.text('Perumahan Green Tasik'), findsNothing);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reset pencarian dan filter'));
    await tester.tap(find.text('Reset pencarian dan filter'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Perumahan Green Tasik'), findsOneWidget);
  });

  testWidgets('year and status filters combine without mutating source data', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.byTooltip('Filter tahun'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '2025'));
    await tester.pumpAndSettle();
    expect(find.text('Grand Tasik Harmoni'), findsOneWidget);
    expect(find.text('Perumahan Green Tasik'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Perlu Perbaikan (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);
    expect(container.read(pengajuanListProvider), hasLength(3));
  });

  testWidgets('revision opens developer detail and query survives back', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Perlu Perbaikan (1)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Perbaiki →'),
      200,
      scrollable: _scroll,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Perbaiki →')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perbaiki →'));
    await tester.pumpAndSettle();
    expect(find.text('Detail pengajuan'), findsOneWidget);
    expect(find.text('REG-2026-0142'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      container.read(pengajuanListQueryProvider).filter,
      PengajuanFilter.perbaikan,
    );
    expect(
      container.read(pengajuanListProvider).first.revisionSubmitted,
      isFalse,
    );
  });

  testWidgets('submitted revision never offers another edit action', (
    tester,
  ) async {
    await _pump(
      tester,
      items: [_items().first.copyWith(revisionSubmitted: true)],
    );
    await tester.scrollUntilVisible(
      find.text('Cek Detail →'),
      200,
      scrollable: _scroll,
    );
    expect(find.text('Perbaiki →'), findsNothing);
    expect(find.text('Revisi terkirim · Menunggu pemeriksaan'), findsOneWidget);
  });

  testWidgets(
    'load more reveals additional records and search resets page size',
    (tester) async {
      final data = [
        ..._items(),
        _items().last.copyWith(id: 'REG-2025-EXTRA', namaPerumahan: 'Tambahan'),
      ];
      final container = await _pump(tester, items: data);
      expect(container.read(pengajuanListQueryProvider).limit, 3);
      await tester.scrollUntilVisible(
        find.text('Muat Lebih Banyak'),
        300,
        scrollable: _scroll,
      );
      await tester.tap(find.text('Muat Lebih Banyak'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tambahan'),
        200,
        scrollable: _scroll,
      );
      expect(find.text('Tambahan'), findsOneWidget);
      container.read(pengajuanListQueryProvider.notifier).search('Tambahan');
      await tester.pumpAndSettle();
      expect(container.read(pengajuanListQueryProvider).limit, 3);
      expect(
        container.read(filteredPengajuanProvider).single.id,
        'REG-2025-EXTRA',
      );
    },
  );

  testWidgets('empty data has an honest empty state', (tester) async {
    await _pump(tester, items: []);
    expect(find.text('Belum ada pengajuan'), findsOneWidget);
    expect(find.byType(PengajuanListCard), findsNothing);
    expect(find.text('Total: 0 Pengajuan'), findsOneWidget);
  });

  testWidgets('provider updates recompute summary and active filter', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Perlu Perbaikan (1)'));
    await tester.pumpAndSettle();
    container
        .read(pengajuanListProvider.notifier)
        .updatePengajuan(
          _items().first.copyWith(
            statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
            status: 'Dalam Proses',
            revisionSubmitted: true,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Perlu Perbaikan (0)'), findsOneWidget);
    expect(find.text('Tidak ada pengajuan ditemukan'), findsOneWidget);
  });

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('dashboard list scrolls at ${width}dp / ${scale}x text', (
        tester,
      ) async {
        await _pump(
          tester,
          dashboard: true,
          width: width,
          textScale: scale,
          items: _items()
              .map(
                (item) => item.copyWith(
                  namaPerumahan:
                      '${item.namaPerumahan} dengan nama perumahan yang panjang',
                ),
              )
              .toList(),
        );
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(BottomAppBar), findsOneWidget);
        for (final label in ['Beranda', 'Pengajuan', 'Notifikasi', 'Profil']) {
          final navLabel = find.descendant(
            of: find.byType(BottomAppBar),
            matching: find.text(label),
          );
          final paragraph = tester.renderObject<RenderParagraph>(navLabel);
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          expect(
            tester
                .getRect(find.byType(BottomAppBar))
                .contains(tester.getBottomRight(navLabel) - const Offset(1, 1)),
            isTrue,
            reason: '$label must remain inside the bottom bar',
          );
        }
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 12; i++) {
          await tester.drag(_scroll, const Offset(0, -300));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets(
    'header tabs preserve list query and central FAB starts the form',
    (tester) async {
      final container = await _pump(tester, dashboard: true);
      await tester.enterText(find.byType(TextField), 'Green');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Buka notifikasi'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardTabProvider), 2);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomAppBar),
          matching: find.text('Pengajuan'),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(pengajuanListQueryProvider).search, 'Green');
      await tester.tap(find.byTooltip('Buka profil'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardTabProvider), 3);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Form pengajuan baru'), findsOneWidget);
    },
  );

  if (const bool.fromEnvironment('CAPTURE_QA')) {
    testWidgets('capture developer list for visual review', (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final loader = FontLoader('Plus Jakarta Sans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      const width = int.fromEnvironment('QA_WIDTH', defaultValue: 390);
      const scale = int.fromEnvironment('QA_SCALE', defaultValue: 1);
      await _pump(
        tester,
        dashboard: true,
        width: width.toDouble(),
        textScale: scale.toDouble(),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('qa-capture')),
      );
      await tester.runAsync(() async {
        final picture = await boundary.toImage();
        final data = await picture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/qa').create(recursive: true);
        await File(
          'build/qa/pengajuan-${width.toInt()}-${scale.toInt()}x.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        picture.dispose();
      });
      // Flutter verifies painting flags before package:test tearDown runs.
      debugDisableShadows = true;
    });
  }
}
