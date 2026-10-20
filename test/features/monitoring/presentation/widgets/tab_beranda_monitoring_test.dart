import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_beranda_monitoring.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

class _FakeMonitoringRepo {
  final List<MonitoringModel> items;
  _FakeMonitoringRepo(this.items);
  List<MonitoringModel> getAllMonitoring() => List.unmodifiable(items);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  group('PerwaskimIdentity tests', () {
    test(
      'resolves default Tim Perwaskim identity with RH initials and NIP',
      () {
        const session = RoleSessionState(
          role: AppRole.perwaskim,
          username: 'tim_monitoring_perwaskim',
        );
        final identity = PerwaskimIdentity.fromSession(session);
        expect(identity.nama, 'Drs. Rian Hidayat, M.Si');
        expect(identity.jabatan, 'Tim Verifikator Lapangan (Perwaskim)');
        expect(identity.nip, 'NIP: 197805122006041008');
        expect(identity.initials, 'RH');
      },
    );

    test('resolves custom username cleanly without hardcoding', () {
      const session = RoleSessionState(
        role: AppRole.perwaskim,
        username: 'ahmad_subagja',
      );
      final identity = PerwaskimIdentity.fromSession(session);
      expect(identity.nama, 'Ahmad Subagja');
      expect(identity.initials, 'AS');
    });
  });

  group('TabBerandaMonitoring Widget tests', () {
    testWidgets('renders Perwaskim dashboard header and task components', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roleSessionProvider.overrideWith(
              (ref) => RoleSessionNotifier()
                ..signIn(
                  AppRole.perwaskim,
                  username: 'tim_monitoring_perwaskim',
                ),
            ),
          ],
          child: const MaterialApp(home: TabBerandaMonitoring()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header components
      expect(find.text('Selamat bertugas,'), findsOneWidget);
      expect(find.text('RH'), findsOneWidget);
      expect(find.text('Drs. Rian Hidayat, M.Si'), findsOneWidget);
      // Removed items
      expect(find.text('Tim Verifikator Lapangan (Perwaskim)'), findsNothing);
      expect(find.text('NIP: 197805122006041008'), findsNothing);
      expect(find.text('Satu Rumah'), findsNothing);
      expect(find.text('PORTAL PERWASKIM'), findsNothing);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

      // Canonical header layout: identity on the left, profile avatar on the right
      final avatarDx = tester.getTopLeft(find.text('RH')).dx;
      final profileDx = tester
          .getTopLeft(find.text('Drs. Rian Hidayat, M.Si'))
          .dx;
      expect(avatarDx, greaterThan(profileDx));

      // Verify Active Survey Task Card
      expect(find.text('Tugas Survey Aktif'), findsOneWidget);
      expect(find.text('INSTRUKSI ADMIN'), findsOneWidget);
      expect(find.text('Buka Berita Acara & Mulai Survei'), findsOneWidget);

      // Verify Latest Survey Results section
      expect(find.text('Hasil Survey Terbaru'), findsOneWidget);
      expect(find.text('Lihat Semua →'), findsOneWidget);
      expect(find.textContaining('Mode prototipe'), findsNothing);
    });

    testWidgets(
      'avoids horizontal overflow on small 360dp viewport and keeps avatar on right',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roleSessionProvider.overrideWith(
                (ref) => RoleSessionNotifier()
                  ..signIn(
                    AppRole.perwaskim,
                    username: 'tim_monitoring_perwaskim',
                  ),
              ),
            ],
            child: const MaterialApp(home: TabBerandaMonitoring()),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final avatarDx = tester.getTopLeft(find.text('RH')).dx;
        final profileDx = tester
            .getTopLeft(find.text('Drs. Rian Hidayat, M.Si'))
            .dx;
        expect(avatarDx, greaterThan(profileDx));
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      },
    );

    testWidgets('header does not display notification bell or badge', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: TabBerandaMonitoring())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets(
      'renders all monitoring card metadata fields and status badge',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roleSessionProvider.overrideWith(
                (ref) => RoleSessionNotifier()
                  ..signIn(
                    AppRole.perwaskim,
                    username: 'tim_monitoring_perwaskim',
                  ),
              ),
            ],
            child: const MaterialApp(home: TabBerandaMonitoring()),
          ),
        );

        await tester.pumpAndSettle();

        // Ensure Hasil Survey section is present
        expect(find.text('Hasil Survey Terbaru'), findsOneWidget);
        expect(find.text('Draf'), findsWidgets);
        expect(find.text('Lanjutkan Draf Survei'), findsOneWidget);
        expect(find.text('Lihat Detail Hasil'), findsWidgets);
        expect(find.text('Lihat Dokumen BA'), findsNothing);
      },
    );

    testWidgets('tapping a draft result row navigates to /monitoring/draft', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final router = GoRouter(
        initialLocation: '/monitoring/lapangan',
        routes: [
          GoRoute(
            path: '/monitoring/lapangan',
            builder: (_, __) => const TabBerandaMonitoring(),
          ),
          GoRoute(
            path: '/monitoring/draft',
            builder: (_, state) {
              final model = state.extra as MonitoringModel;
              return Scaffold(
                body: Text('DRAFT_SCREEN:${model.namaPerumahan}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roleSessionProvider.overrideWith(
              (ref) => RoleSessionNotifier()
                ..signIn(
                  AppRole.perwaskim,
                  username: 'tim_monitoring_perwaskim',
                ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      final draftButton = find.text('Lanjutkan Draf Survei');
      expect(draftButton, findsOneWidget);

      await tester.scrollUntilVisible(draftButton, 300);
      await tester.tap(draftButton);
      await tester.pumpAndSettle();

      expect(find.text('DRAFT_SCREEN:Griya Mangkubumi Asri'), findsOneWidget);
    });

    testWidgets('tapping a compact task row starts the survey for it', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final router = GoRouter(
        initialLocation: '/monitoring/lapangan',
        routes: [
          GoRoute(
            path: '/monitoring/lapangan',
            builder: (_, __) => const TabBerandaMonitoring(),
          ),
          GoRoute(
            path: '/monitoring/tambah',
            builder: (_, __) => const Scaffold(body: Text('TAMBAH_SCREEN')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roleSessionProvider.overrideWith(
              (ref) => RoleSessionNotifier()
                ..signIn(
                  AppRole.perwaskim,
                  username: 'tim_monitoring_perwaskim',
                ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final secondTask = find.text('Kencana Kawalu Regency');
      expect(secondTask, findsOneWidget);
      await tester.ensureVisible(secondTask);
      await tester.tap(secondTask);
      await tester.pumpAndSettle();

      expect(find.text('TAMBAH_SCREEN'), findsOneWidget);
    });

    testWidgets('renders empty state when there are 0 active survey tasks', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [surveyAktifProvider.overrideWithValue(<Pengajuan>[])],
          child: const MaterialApp(home: TabBerandaMonitoring()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada tugas survey aktif'), findsOneWidget);
      expect(
        find.text('Penugasan dari Admin akan muncul di sini.'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state when there are 0 survey results', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringListProvider.overrideWith(
              (ref) => MonitoringListNotifier(_FakeMonitoringRepo([])),
            ),
          ],
          child: const MaterialApp(home: TabBerandaMonitoring()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada hasil survey'), findsOneWidget);
      expect(
        find.text('Hasil survey yang sudah dicatat akan tampil di sini.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'limits tasks to maximum 3 and reports exact total count in header',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        final manyTasks = List.generate(
          5,
          (i) => Pengajuan(
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
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [surveyAktifProvider.overrideWithValue(manyTasks)],
            child: const MaterialApp(home: TabBerandaMonitoring()),
          ),
        );
        await tester.pumpAndSettle();

        // Header shows total count
        expect(find.text('5 tugas'), findsOneWidget);

        // First task as primary
        expect(find.text('Perumahan Indah 0'), findsOneWidget);
        // Secondary tasks (only 2 shown: index 1 and 2)
        expect(find.text('Perumahan Indah 1'), findsOneWidget);
        expect(find.text('Perumahan Indah 2'), findsOneWidget);
        // Beyond 3 tasks should NOT be rendered in dashboard preview
        expect(find.text('Perumahan Indah 3'), findsNothing);
        expect(find.text('Perumahan Indah 4'), findsNothing);
      },
    );

    testWidgets('limits survey results to maximum 3 items', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final manyResults = List.generate(
        5,
        (i) => MonitoringModel(
          id: 'mon-$i',
          namaPerumahan: 'Hasil Perumahan $i',
          namaDeveloper: 'PT Developer $i',
          tanggalMonitoring: DateTime(2026, 5, 20 - i),
          statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringListProvider.overrideWith(
              (ref) => MonitoringListNotifier(_FakeMonitoringRepo(manyResults)),
            ),
          ],
          child: const MaterialApp(home: TabBerandaMonitoring()),
        ),
      );
      await tester.pumpAndSettle();

      // First 3 should appear
      expect(find.text('Hasil Perumahan 0'), findsOneWidget);
      expect(find.text('Hasil Perumahan 1'), findsOneWidget);
      expect(find.text('Hasil Perumahan 2'), findsOneWidget);
      // 4th and 5th should NOT appear
      expect(find.text('Hasil Perumahan 3'), findsNothing);
      expect(find.text('Hasil Perumahan 4'), findsNothing);
    });

    for (final width in [360.0, 390.0, 420.0]) {
      testWidgets('viewport ${width}dp renders without overflow', (
        WidgetTester tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 844));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roleSessionProvider.overrideWith(
                (ref) => RoleSessionNotifier()
                  ..signIn(
                    AppRole.perwaskim,
                    username: 'tim_monitoring_perwaskim',
                  ),
              ),
            ],
            child: const MaterialApp(home: TabBerandaMonitoring()),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
