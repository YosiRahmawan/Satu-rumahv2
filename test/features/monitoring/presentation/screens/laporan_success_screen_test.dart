import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/laporan_success_screen.dart';

MonitoringModel _monitoring() => MonitoringModel(
  id: 'ba-test',
  tanggalMonitoring: DateTime(2026, 6, 25),
  namaPerumahan: 'Perumahan Uji',
  namaDeveloper: 'PT Uji Properti',
  lokasiPerumahan: 'Jl. Karikil, Cipari',
  nomorSuratBA: 'BA/2026/001',
);

Widget _app({Size size = const Size(360, 800), double textScale = 1}) {
  final router = GoRouter(
    initialLocation: '/success',
    routes: [
      GoRoute(
        path: '/success',
        builder: (_, __) => LaporanSuccessScreen(monitoring: _monitoring()),
      ),
      GoRoute(
        path: '/monitoring/lapangan/riwayat',
        builder: (_, __) => const Scaffold(body: Text('Riwayat Monitoring')),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        builder: (_, __) => const Scaffold(body: Text('Beranda Monitoring')),
      ),
    ],
  );
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows generated document data from authentic monitoring model', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('Berita Acara Generated'), findsOneWidget);
    expect(find.text('Laporan Berhasil Dibuat!'), findsOneWidget);
    expect(
      find.text('Berita Acara Monitoring & Evaluasi Lapangan resmi telah diterbitkan oleh sistem.'),
      findsOneWidget,
    );
    expect(find.text('BERITA ACARA MONITORING DAN EVALUASI LAPANGAN'), findsOneWidget);
    expect(find.textContaining('Perumahan Uji'), findsOneWidget);
    expect(find.textContaining('Jl. Karikil, Cipari'), findsOneWidget);
    expect(find.textContaining('BA/2026/001'), findsOneWidget);
    expect(find.text('Download / Cetak PDF'), findsOneWidget);
    expect(find.text('Bagikan ringkasan'), findsOneWidget);
    expect(find.textContaining('Download Word'), findsNothing);
    expect(find.byIcon(Icons.qr_code), findsNothing);
    expect(find.byIcon(Icons.qr_code_2), findsNothing);
    expect(find.text('Identitas pihak yang tercatat'), findsNothing);
  });

  testWidgets('navigates to monitoring history', (tester) async {
    await tester.pumpWidget(_app());
    final backBtn = find.text('Kembali ke Menu Riwayat Monitoring');
    await tester.ensureVisible(backBtn);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Monitoring'), findsOneWidget);
  });

  testWidgets('shows authentic pelaksana identity without inventing fake QR', (
    tester,
  ) async {
    final monitoring = _monitoring().copyWith(
      pelaksanaNama: 'Petugas Uji, S.T.',
    );
    final router = GoRouter(
      initialLocation: '/success',
      routes: [
        GoRoute(
          path: '/success',
          builder: (_, __) => LaporanSuccessScreen(monitoring: monitoring),
        ),
      ],
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('Identitas pihak yang tercatat'), findsNothing);
    expect(find.textContaining('Nama     : Petugas Uji, S.T.'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code), findsNothing);
    expect(find.byIcon(Icons.qr_code_2), findsNothing);
  });

  testWidgets('fits 360dp and 412dp at 200 percent text scale', (tester) async {
    for (final width in [360.0, 412.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      final overflowErrors = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          overflowErrors.add(message);
        }
        previousOnError?.call(details);
      };
      try {
        await tester.pumpWidget(_app(size: Size(width, 800), textScale: 2));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previousOnError;
      }
      expect(tester.takeException(), isNull);
      expect(overflowErrors, isEmpty);
      expect(find.byType(OverflowBar), findsNothing);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
