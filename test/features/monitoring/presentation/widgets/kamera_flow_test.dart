import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/kamera_context.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/screens/monitoring_main_screen.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/kamera_flow.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

Pengajuan _task(int i) => Pengajuan(
  id: 'SR-2026-000$i',
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
  KameraContext? capturedContext;

  Future<void> pump(WidgetTester tester, List<Pengajuan> tasks) async {
    capturedContext = null;
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
          builder: (_, state) {
            capturedContext = state.extra is KameraContext
                ? state.extra as KameraContext
                : null;
            return Scaffold(
              body: Text('LAYAR KAMERA: ${capturedContext?.taskTitle}'),
            );
          },
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

  testWidgets(
    'menekan FAB kamera membuka bottom sheet Mode Selector dengan 3 opsi',
    (tester) async {
      await pump(tester, [_task(1), _task(2)]);

      // Tekan FAB kamera centerDocked
      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      // Memverifikasi elemen Mode Selector sesuai Stitch
      expect(find.text('Kamera Lapangan'), findsOneWidget);
      expect(
        find.text('Pilih cara mengambil dokumentasi lapangan.'),
        findsOneWidget,
      );
      expect(find.text('Foto Geotagging'), findsOneWidget);
      expect(find.text('GPS Watermark'), findsOneWidget);
      expect(find.text('Foto untuk Tugas Survei'), findsOneWidget);
      expect(find.text('2 Aktif'), findsOneWidget);
      expect(find.text('Dokumentasi Saya (Galeri & Arsip)'), findsOneWidget);
    },
  );

  testWidgets(
    'opsi Foto Geotagging langsung membuka kamera fullscreen mode mandiri',
    (tester) async {
      await pump(tester, [_task(1)]);

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto Geotagging'));
      await tester.pumpAndSettle();

      expect(find.text('LAYAR KAMERA: Dokumentasi Mandiri'), findsOneWidget);
      expect(capturedContext?.isTaskFlow, isFalse);
      expect(capturedContext?.taskId, isNull);
    },
  );

  testWidgets(
    'opsi Foto untuk Tugas Survei beralih ke sub-view pilih tugas dengan ID terasosiasi',
    (tester) async {
      await pump(tester, [_task(1), _task(2)]);

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto untuk Tugas Survei'));
      await tester.pumpAndSettle();

      // Memverifikasi sub-view task picker
      expect(find.text('Foto untuk tugas mana?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KameraModeBottomSheet),
          matching: find.text('Perumahan Indah 1'),
        ),
        findsOneWidget,
      );
      expect(find.text('No. Registrasi: SR-2026-0001'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KameraModeBottomSheet),
          matching: find.text('Perumahan Indah 2'),
        ),
        findsOneWidget,
      );
      expect(find.text('No. Registrasi: SR-2026-0002'), findsOneWidget);

      // Memilih tugas 2
      await tester.tap(
        find.descendant(
          of: find.byType(KameraModeBottomSheet),
          matching: find.text('Perumahan Indah 2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LAYAR KAMERA: Perumahan Indah 2'), findsOneWidget);
      expect(capturedContext?.isTaskFlow, isTrue);
      expect(capturedContext?.taskId, 'SR-2026-0002');
      expect(capturedContext?.nomorRegistrasi, 'SR-2026-0002');
    },
  );

  testWidgets(
    'tombol kembali pada sub-view pilih tugas mengembalikan ke Mode Selector',
    (tester) async {
      await pump(tester, [_task(1)]);

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto untuk Tugas Survei'));
      await tester.pumpAndSettle();
      expect(find.text('Foto untuk tugas mana?'), findsOneWidget);

      // Tekan tombol kembali
      await tester.tap(find.byTooltip('Kembali ke pilihan mode'));
      await tester.pumpAndSettle();

      expect(find.text('Kamera Lapangan'), findsOneWidget);
      expect(find.text('Foto Geotagging'), findsOneWidget);
    },
  );

  testWidgets('opsi Dokumentasi Saya menampilkan feedback snackbar', (
    tester,
  ) async {
    await pump(tester, []);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dokumentasi Saya (Galeri & Arsip)'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Dokumentasi Saya (Galeri & Arsip) akan tersedia'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tanpa tugas aktif: memilih Foto untuk Tugas Survei menampilkan notifikasi',
    (tester) async {
      await pump(tester, []);

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto untuk Tugas Survei'));
      await tester.pumpAndSettle();

      expect(
        find.text('Belum ada tugas survei aktif untuk diasosiasikan.'),
        findsOneWidget,
      );
      expect(find.text('Foto untuk tugas mana?'), findsNothing);
    },
  );
}
