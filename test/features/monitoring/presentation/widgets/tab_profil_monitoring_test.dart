import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_profil_monitoring.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

class _FakeMonitoringRepository {
  final List<MonitoringModel> items;

  _FakeMonitoringRepository(this.items);

  List<MonitoringModel> getAllMonitoring() => List.unmodifiable(items);
}

void main() {
  final items = [
    MonitoringModel(
      id: 'complete',
      tanggalMonitoring: DateTime(2026, 5, 20),
      namaPerumahan: 'Permata Hijau Residence',
      statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
    ),
    MonitoringModel(
      id: 'follow-up',
      tanggalMonitoring: DateTime(2026, 5, 18),
      namaPerumahan: 'Bumi Asri Kawalu',
      statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
    ),
  ];

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        roleSessionProvider.overrideWith((ref) {
          final notifier = RoleSessionNotifier();
          notifier.signIn(AppRole.perwaskim, username: 'petugas_lapangan');
          return notifier;
        }),
        monitoringListProvider.overrideWith(
          (ref) => MonitoringListNotifier(_FakeMonitoringRepository(items)),
        ),
        surveyAktifProvider.overrideWithValue(<Pengajuan>[]),
      ],
      child: const MaterialApp(home: TabProfilMonitoring()),
    );
  }

  testWidgets('uses session identity and data-derived profile statistics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('petugas_lapangan'), findsWidgets);
    expect(find.text('Tugas Aktif'), findsOneWidget);
    expect(find.text('Survey Selesai'), findsOneWidget);
    expect(find.text('Perlu Evaluasi'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('INFORMASI AKUN DINAS'), findsOneWidget);
  });

  testWidgets('does not overflow at 360dp with 200 percent text scaling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
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
