import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/laporan_preview_screen.dart';

MonitoringModel _monitoring() => MonitoringModel(
  id: 'preview-test',
  tanggalMonitoring: DateTime(2026, 6, 25),
  namaPerumahan: 'Perumahan Preview Uji',
  namaDeveloper: 'PT Preview Properti',
  lokasiPerumahan: 'Jl. Uji Preview',
  nomorSuratBA: 'BA/PREVIEW/001',
  temuanLapangan: const ['Temuan model'],
);

Widget _app({Size size = const Size(360, 800), double textScale = 1}) {
  final router = GoRouter(
    initialLocation: '/preview',
    routes: [
      GoRoute(
        path: '/preview',
        builder: (_, __) => LaporanPreviewScreen(monitoring: _monitoring()),
      ),
      GoRoute(
        path: '/monitoring/success',
        builder: (_, __) => const Scaffold(body: Text('success')),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('monitoring')),
      ),
    ],
  );
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('preview uses model data and truthful supported actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('Preview Berita Acara'), findsOneWidget);
    expect(find.text('Perumahan Preview Uji'), findsOneWidget);
    expect(find.text('BA/PREVIEW/001'), findsOneWidget);
    expect(find.text('Temuan model'), findsOneWidget);
    expect(find.text('Download / Cetak PDF'), findsOneWidget);
    expect(find.text('Bagikan ringkasan'), findsOneWidget);
    expect(find.text('Email: Belum tersedia'), findsOneWidget);
    expect(find.text('Arsip Sistem: Belum tersedia'), findsOneWidget);
    expect(find.textContaining('Download Word'), findsNothing);
    expect(find.byIcon(Icons.qr_code), findsNothing);
    expect(find.textContaining('_________________'), findsNothing);
    expect(find.text('Identitas pihak yang tercatat'), findsNothing);
  });

  testWidgets('preview remains usable at 360dp and 412dp with 200% text', (
    tester,
  ) async {
    for (final width in [360.0, 412.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(_app(size: Size(width, 800), textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(OverflowBar), findsNothing);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
