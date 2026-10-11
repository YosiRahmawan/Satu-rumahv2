import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_draft_screen.dart';

MonitoringModel _sampleDraft() => MonitoringModel(
  id: 'draft-test-1',
  pengajuanId: 'SR-2025-0148',
  nomorSuratBA: 'BA/PERWASKIM/2025/05/0148',
  tanggalMonitoring: DateTime(2025, 5, 22),
  namaPerumahan: 'Griya Mangkubumi Asri',
  namaDeveloper: 'PT Citra Tasik Mandiri',
  lokasiPerumahan: 'Kec. Mangkubumi, Kota Tasikmalaya',
  statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
  temuanLapangan: const [
    'Saluran drainase sisi timur belum sesuai detail rencana.',
  ],
  kesimpulan: const [
    'Kawasan dapat dilanjutkan setelah perbaikan desain drainase.',
  ],
  kesepakatan: const [
    'Pengembang akan mengunggah revisi dalam 7 hari kerja.',
  ],
  rencanaTindakLanjut: const [
    'Perbarui gambar drainase sebelum persetujuan dilanjutkan.',
  ],
  pelaksanaNama: 'Rahmat Hidayat, S.T.',
  pelaksanaJabatan: 'Petugas Pengawas Perwaskim',
  ditemuiNama: 'H. Asep Hendrayana, S.T.',
  ditemuiJabatan: 'Penanggung Jawab Pengembang',
  isDraft: true,
);

Widget _testApp({
  MonitoringModel? draft,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  ProviderContainer? container,
}) {
  final draftModel = draft ?? _sampleDraft();
  final router = GoRouter(
    initialLocation: '/monitoring/draft',
    routes: [
      GoRoute(
        path: '/monitoring/draft',
        builder: (_, __) => MonitoringDraftScreen(monitoring: draftModel),
      ),
      GoRoute(
        path: '/monitoring/tambah',
        builder: (_, __) => const Scaffold(body: Text('tambah-screen-mock')),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('lapangan-home-mock')),
      ),
    ],
  );

  final app = MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp.router(routerConfig: router),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  group('MonitoringDraftScreen tests', () {
    testWidgets('renders draft status, authentic details, and actions correctly', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      // Verify Header & Draft Status Banner
      expect(find.text('Dokumen Draft Monitoring'), findsOneWidget);
      expect(find.text('STATUS: DRAFT'), findsOneWidget);
      expect(find.text('Belum Difinalisasi'), findsOneWidget);
      expect(find.text('Laporan Pengawasan Belum Selesai'), findsOneWidget);

      // Verify Authentic Housing Information
      expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);
      expect(find.text('PT Citra Tasik Mandiri'), findsOneWidget);
      expect(find.text('Kec. Mangkubumi, Kota Tasikmalaya'), findsOneWidget);
      expect(find.text('BA/PERWASKIM/2025/05/0148'), findsOneWidget);

      // Verify Evaluation details
      expect(find.text('Hasil Evaluasi Lapangan'), findsOneWidget);
      expect(
        find.text('Saluran drainase sisi timur belum sesuai detail rencana.'),
        findsOneWidget,
      );
      expect(
        find.text('Kawasan dapat dilanjutkan setelah perbaikan desain drainase.'),
        findsOneWidget,
      );
      expect(
        find.text('Pengembang akan mengunggah revisi dalam 7 hari kerja.'),
        findsOneWidget,
      );
      expect(
        find.text('Perbarui gambar drainase sebelum persetujuan dilanjutkan.'),
        findsOneWidget,
      );

      // Verify Personnel details
      expect(find.text('Rahmat Hidayat, S.T.'), findsOneWidget);
      expect(find.text('Petugas Pengawas Perwaskim'), findsOneWidget);
      expect(find.text('H. Asep Hendrayana, S.T.'), findsOneWidget);
      expect(find.text('Penanggung Jawab Pengembang'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Lanjutkan Pengisian'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets('tapping Lanjutkan Pengisian loads draft into provider and navigates to tambah', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_testApp(container: container));
      await tester.pumpAndSettle();

      // Tap Lanjutkan Pengisian
      final lanjutkanButton = find.byKey(const ValueKey('lanjutkan_pengisian_button'));
      expect(lanjutkanButton, findsOneWidget);
      await tester.tap(lanjutkanButton);
      await tester.pumpAndSettle();

      // Navigation target is reached
      expect(find.text('tambah-screen-mock'), findsOneWidget);

      // Verify provider was populated with the draft data
      final state = container.read(monitoringFormProvider);
      expect(state.draftId, 'draft-test-1');
      expect(state.pengajuanId, 'SR-2025-0148');
      expect(state.namaPerumahan, 'Griya Mangkubumi Asri');
      expect(state.namaDeveloper, 'PT Citra Tasik Mandiri');
      expect(state.pelaksanaNama, 'Rahmat Hidayat, S.T.');
      expect(state.ditemuiNama, 'H. Asep Hendrayana, S.T.');
      expect(state.statusHasilEvaluasi, StatusHasilEvaluasi.perluEvaluasiLanjutan);
      expect(state.temuanLapangan, contains('Saluran drainase sisi timur belum sesuai detail rencana.'));
    });

    testWidgets('tapping Kembali ke Beranda navigates to monitoring lapangan', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      final kembaliButton = find.byKey(const ValueKey('kembali_beranda_button'));
      expect(kembaliButton, findsOneWidget);
      await tester.tap(kembaliButton);
      await tester.pumpAndSettle();

      expect(find.text('lapangan-home-mock'), findsOneWidget);
    });

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets('viewport ${width}dp renders without overflow', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        await tester.pumpWidget(_testApp(size: Size(width, 844), textScale: 1.5));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
