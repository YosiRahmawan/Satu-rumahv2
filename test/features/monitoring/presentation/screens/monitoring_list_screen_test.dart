import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_list_screen.dart';

class _FakeMonitoringRepository {
  final List<MonitoringModel> items;

  _FakeMonitoringRepository(this.items);

  List<MonitoringModel> getAllMonitoring() => List.unmodifiable(items);
}

void main() {
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

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        monitoringListProvider.overrideWith(
          (ref) => MonitoringListNotifier(_FakeMonitoringRepository(items)),
        ),
      ],
      child: const MaterialApp(home: MonitoringListScreen()),
    );
  }

  testWidgets('renders data-derived archive counts and BA metadata', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('3 Arsip'), findsOneWidget);
    expect(find.text('Semua (3)'), findsOneWidget);
    expect(find.text('Sesuai (1)'), findsOneWidget);
    expect(find.text('Perlu Evaluasi (2)'), findsOneWidget);
    expect(find.text('BA-001'), findsOneWidget);
    expect(
      find.text('Lihat Dokumen BA', skipOffstage: false),
      findsNWidgets(3),
    );
  });

  testWidgets('combines search and status filter', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 844));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perlu Evaluasi (2)'));
    await tester.pump();
    expect(find.text('Permata Hijau Residence'), findsOneWidget);
    expect(find.text('Grand Tasik Harmoni'), findsOneWidget);
    expect(find.text('Bumi Asri Kawalu'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Permata');
    await tester.pump();
    expect(find.text('Permata Hijau Residence'), findsOneWidget);
    expect(find.text('Grand Tasik Harmoni'), findsNothing);
  });

  testWidgets('does not overflow on 360dp viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports 200 percent text scaling at 412dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: buildSubject(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
