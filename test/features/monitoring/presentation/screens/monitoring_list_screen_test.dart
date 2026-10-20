import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_list_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/survey_not_found_illustration.dart';

class _FakeMonitoringRepository {
  final List<MonitoringModel> items;

  _FakeMonitoringRepository(this.items);

  List<MonitoringModel> getAllMonitoring() => List.unmodifiable(items);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  final items = [
    MonitoringModel(
      id: '1',
      nomorSuratBA: 'BA-001',
      tanggalMonitoring: DateTime(2026, 5, 20),
      namaPerumahan: 'Permata Hijau Residence',
      namaDeveloper: 'PT ABC Property',
      lokasiPerumahan: 'Tasikmalaya',
      statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
    ),
    MonitoringModel(
      id: '2',
      nomorSuratBA: 'BA-002',
      tanggalMonitoring: DateTime(2026, 5, 14),
      namaPerumahan: 'Bumi Asri Kawalu',
      namaDeveloper: 'PT Sentosa Graha',
      lokasiPerumahan: 'Kawalu',
      statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
    ),
    MonitoringModel(
      id: '3',
      nomorSuratBA: 'BA-003',
      tanggalMonitoring: DateTime(2026, 4, 28),
      namaPerumahan: 'Grand Tasik Harmoni',
      namaDeveloper: 'PT Harmoni Bangun Persada',
      lokasiPerumahan: 'Cihideung',
      statusHasilEvaluasi: StatusHasilEvaluasi.tidakSesuaiSiteplan,
    ),
  ];

  final draft = MonitoringModel(
    id: '4',
    nomorSuratBA: 'BA-004',
    tanggalMonitoring: DateTime(2026, 6, 1),
    namaPerumahan: 'Griya Draf Asri',
    namaDeveloper: 'PT Draf Mandiri',
    isDraft: true,
  );

  Widget buildSubject(List<MonitoringModel> data, {Widget? home}) {
    return ProviderScope(
      overrides: [
        monitoringListProvider.overrideWith(
          (ref) => MonitoringListNotifier(_FakeMonitoringRepository(data)),
        ),
      ],
      child: MaterialApp(home: home ?? const MonitoringListScreen()),
    );
  }

  testWidgets('shows one count, filters, and a light card per report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject(items));
    await tester.pumpAndSettle();

    expect(find.text('3 laporan'), findsOneWidget);
    expect(find.textContaining('Arsip'), findsNothing);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Draf'), findsOneWidget);
    // Chip filter dan badge kartu memakai kata yang sama.
    expect(find.text('Sesuai'), findsNWidgets(2));
    expect(find.text('Perlu evaluasi'), findsNWidgets(2));
    expect(find.text('20 Mei 2026 · BA-001'), findsOneWidget);
    expect(find.text('Lihat Dokumen BA'), findsNothing);
    expect(find.text('Tidak sesuai'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('lists the newest report first', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject([...items, draft]));
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Griya Draf Asri'), lessThan(top('Permata Hijau Residence')));
    expect(top('Permata Hijau Residence'), lessThan(top('Bumi Asri Kawalu')));
    expect(top('Bumi Asri Kawalu'), lessThan(top('Grand Tasik Harmoni')));
  });

  testWidgets('a draft shows one Draf badge and has its own filter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 844));
    await tester.pumpWidget(buildSubject([...items, draft]));
    await tester.pumpAndSettle();

    expect(find.text('Griya Draf Asri'), findsOneWidget);
    // Chip "Draf" dan badge "Draf" pada kartu.
    expect(find.text('Draf'), findsNWidgets(2));

    await tester.tap(find.text('Draf').first);
    await tester.pump();
    expect(find.text('Griya Draf Asri'), findsOneWidget);
    expect(find.text('Permata Hijau Residence'), findsNothing);

    await tester.tap(find.text('Sesuai').first);
    await tester.pump();
    expect(find.text('Griya Draf Asri'), findsNothing);
    expect(find.text('Bumi Asri Kawalu'), findsOneWidget);
  });

  testWidgets('combines search and status filter', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 844));
    await tester.pumpWidget(buildSubject(items));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perlu evaluasi').first);
    await tester.pump();
    expect(find.text('Permata Hijau Residence'), findsOneWidget);
    expect(find.text('Grand Tasik Harmoni'), findsOneWidget);
    expect(find.text('Bumi Asri Kawalu'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Permata');
    await tester.pump();
    expect(find.text('Permata Hijau Residence'), findsOneWidget);
    expect(find.text('Grand Tasik Harmoni'), findsNothing);
  });

  testWidgets('renders condition 1: empty database when no reports exist', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject([]));
    await tester.pumpAndSettle();

    expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsNothing);
    expect(find.text('Belum ada laporan survey'), findsOneWidget);
    expect(
      find.text(
        'Laporan hasil survey dan berita acara akan tampil di sini setelah survey dicatat.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reset Filter'), findsNothing);
    expect(find.text('Hapus Pencarian'), findsNothing);
  });

  testWidgets(
    'renders condition 2: search has no matches and allows clearing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildSubject(items));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'tidak ada nama ini');
      await tester.pumpAndSettle();

      expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
      expect(find.text('Laporan tidak ditemukan'), findsOneWidget);
      expect(find.textContaining('tidak ada nama ini'), findsWidgets);
      final clearButton = find.text('Hapus Pencarian');
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Permata Hijau Residence'), findsOneWidget);
      expect(find.text('Laporan tidak ditemukan'), findsNothing);
    },
  );

  testWidgets('renders condition 3: filter has no matches and allows reset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    // Provide items with NO draft
    await tester.pumpWidget(buildSubject(items));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draf'));
    await tester.pumpAndSettle();

    expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
    expect(find.text('Tidak ada laporan dengan status ini'), findsOneWidget);
    expect(
      find.text(
        'Tidak ada laporan survey dengan status "Draf". Coba pilih status filter lainnya.',
      ),
      findsOneWidget,
    );
    final resetButton = find.text('Reset Filter');
    expect(resetButton, findsOneWidget);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.text('Permata Hijau Residence'), findsOneWidget);
  });

  testWidgets(
    'renders condition 4: combined search and filter has no matches and resets both',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildSubject([...items, draft]));
      await tester.pumpAndSettle();

      // Select Draf filter
      await tester.tap(find.text('Draf').first);
      await tester.pumpAndSettle();
      expect(find.text('Griya Draf Asri'), findsOneWidget);

      // Search something that doesn't match the draft
      await tester.enterText(find.byType(TextField), 'Permata');
      await tester.pumpAndSettle();

      expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
      expect(find.text('Tidak ada laporan yang sesuai filter'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada laporan dengan kata kunci "Permata" dan status "Draf".',
        ),
        findsOneWidget,
      );
      final resetAllButton = find.text('Reset Pencarian & Filter');
      expect(resetAllButton, findsOneWidget);

      await tester.tap(resetAllButton);
      await tester.pumpAndSettle();

      expect(find.text('Permata Hijau Residence'), findsOneWidget);
      expect(find.text('Griya Draf Asri'), findsOneWidget);
    },
  );

  for (final width in [360.0, 390.0, 420.0]) {
    testWidgets('empty state renders without overflow on ${width}dp viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 640));
      await tester.pumpWidget(buildSubject([]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SurveyNotFoundIllustration), findsOneWidget);
    });
  }

  testWidgets('tapping a card opens its document', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/riwayat',
      routes: [
        GoRoute(
          path: '/riwayat',
          builder: (_, __) => const MonitoringListScreen(),
        ),
        GoRoute(
          path: '/monitoring/preview',
          builder: (_, state) {
            final model = (state.extra as Map)['model'] as MonitoringModel;
            return Scaffold(body: Text('PREVIEW:${model.namaPerumahan}'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monitoringListProvider.overrideWith(
            (ref) => MonitoringListNotifier(_FakeMonitoringRepository(items)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bumi Asri Kawalu'));
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW:Bumi Asri Kawalu'), findsOneWidget);
  });

  testWidgets('the whole page scrolls and the search band stays pinned', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    final many = [
      for (var i = 0; i < 10; i++)
        MonitoringModel(
          id: 'm$i',
          nomorSuratBA: 'BA-1$i',
          tanggalMonitoring: DateTime(2026, 3, 10 + i),
          namaPerumahan: 'Perumahan $i',
          namaDeveloper: 'PT Contoh $i',
        ),
    ];
    await tester.pumpWidget(buildSubject(many));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Survey & BA').hitTestable(), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Survey & BA').hitTestable(), findsNothing);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(find.text('Semua').hitTestable(), findsOneWidget);
  });

  testWidgets('does not overflow on 360dp viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(buildSubject(items));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports 200 percent text scaling at 412dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: buildSubject([...items, draft]),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Riwayat sebagai rute sendiri punya tombol kembali', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(
      buildSubject(
        const [],
        home: MonitoringListScreen(onBack: () => backCount++),
      ),
    );
    await tester.pumpAndSettle();

    final back = find.byTooltip('Kembali');
    expect(back, findsOneWidget);
    await tester.tap(back);
    expect(backCount, 1);
  });

  testWidgets('Riwayat sebagai tab tidak menampilkan tombol kembali', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(const []));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kembali'), findsNothing);
  });

  testWidgets('Riwayat langsung menampilkan data, tanpa kartu Memuat data', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject([
        MonitoringModel(
          id: 'seketika',
          tanggalMonitoring: DateTime(2026, 10, 19),
          namaPerumahan: 'Perumahan Seketika',
        ),
      ]),
    );
    // Hanya satu frame: tidak ada tahap loading di antaranya.
    await tester.pump();

    expect(find.text('Memuat data'), findsNothing);
    expect(find.text('Perumahan Seketika'), findsOneWidget);
  });
}
