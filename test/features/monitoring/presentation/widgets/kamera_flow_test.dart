import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_main_screen.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

Pengajuan _task(int i) => Pengajuan(
  id: 'task-$i',
  namaPerumahan: 'Perumahan Indah $i',
  namaPt: 'PT Pengembang $i',
  namaDirektur: 'Direktur $i',
  npwpPerusahaan: '01.234.567.8',
  luasLahan: 1000,
  jumlahUnit: 20,
  tipePerumahan: 'Subsidi',
  status: 'Survey Dijadwalkan',
  tanggal: '2026-05-10',
  uploadedDocs: const {},
  tanggalSurvey: DateTime(2026, 5, 20 + i, 9, 0),
);

void main() {
  setUpAll(() async => initializeDateFormatting('id', null));

  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, List<Pengajuan> tasks) async {
    container = ProviderContainer(
      overrides: [
        surveyAktifProvider.overrideWithValue(tasks),
        monitoringRepositoryProvider.overrideWithValue(MonitoringRepository()),
        roleSessionProvider.overrideWith(
          (ref) => RoleSessionNotifier()
            ..signIn(AppRole.perwaskim, username: 'tim_monitoring_perwaskim'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MonitoringMainScreen()),
        GoRoute(
          path: '/monitoring/kamera',
          builder: (_, __) => const Scaffold(body: Text('LAYAR KAMERA')),
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tanpa tugas survei: memberi tahu, kamera tidak terbuka', (
    tester,
  ) async {
    await pump(tester, const []);
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada tugas survei aktif'), findsOneWidget);
    expect(find.text('LAYAR KAMERA'), findsNothing);
  });

  testWidgets('satu tugas: langsung membuka kamera dengan form terisi', (
    tester,
  ) async {
    await pump(tester, [_task(1)]);
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    expect(find.text('LAYAR KAMERA'), findsOneWidget);
    final form = container.read(monitoringFormProvider);
    expect(form.pengajuanId, 'task-1');
    expect(form.namaPerumahan, 'Perumahan Indah 1');
  });

  testWidgets('banyak tugas: pilih tugas dulu lalu kamera terbuka', (
    tester,
  ) async {
    await pump(tester, [_task(1), _task(2), _task(3)]);
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Foto untuk tugas mana?'), findsOneWidget);
    expect(find.text('LAYAR KAMERA'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Perumahan Indah 2'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('LAYAR KAMERA'), findsOneWidget);
    expect(container.read(monitoringFormProvider).pengajuanId, 'task-2');
  });
}
