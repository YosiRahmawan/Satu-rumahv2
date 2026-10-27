import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:satu_rumah/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/notifikasi/presentation/screens/notifikasi_list_screen.dart';
import 'package:satu_rumah/features/notifikasi/presentation/widgets/developer_notification_tile.dart';
import 'package:satu_rumah/features/notifikasi/presentation/widgets/developer_notification_view.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';

class _Notifications extends NotifikasiNotifier {
  _Notifications(List<NotifikasiModel> items) {
    state = items;
  }
}

List<NotifikasiModel> _items() => [
  NotifikasiModel(
    id: 'read',
    jenis: JenisNotifikasi.pengajuanBaru,
    judul: 'Pengajuan diterima',
    deskripsi: 'Informasi pengajuan contoh.',
    waktu: DateTime(2026, 10, 3, 8),
    isRead: true,
    penerima: AppRole.developer,
  ),
  NotifikasiModel(
    id: 'unread',
    jenis: JenisNotifikasi.reminderSurvey,
    judul: 'Jadwal survey tersedia',
    deskripsi: 'Buka pengajuan untuk melihat informasi survey.',
    waktu: DateTime(2026, 10, 5, 9),
    targetRoute: '/admin/pengajuan/detail/SR-TEST',
    penerima: AppRole.developer,
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<NotifikasiModel>? items,
  AppRole role = AppRole.developer,
  bool dashboard = false,
  double width = 390,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      notifikasiProvider.overrideWith(
        (ref) => _Notifications(items ?? _items()),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(roleSessionProvider.notifier).signIn(role);
  container.read(dashboardTabProvider.notifier).state = 2;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            dashboard ? const DashboardScreen() : const NotifikasiListScreen(),
      ),
      GoRoute(
        path: '/pengajuan/perbarui-berkas/:id',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Perbarui berkas')),
          body: Text(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/pengajuan/detail/:id',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Detail pengajuan')),
          body: Text(state.pathParameters['id']!),
        ),
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
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows newest first with explicit read states and survey color', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('1 notifikasi belum dibaca'), findsOneWidget);
    final tiles = tester
        .widgetList<DeveloperNotificationTile>(
          find.byType(DeveloperNotificationTile),
        )
        .toList();
    expect(tiles.map((tile) => tile.item.id), ['unread', 'read']);
    expect(find.bySemanticsLabel('Sudah dibaca'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-indicator')), findsOneWidget);
    expect(find.text('05/10/2026 • 09:00'), findsOneWidget);
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('unread')),
        matching: find.byIcon(Icons.event_available_outlined),
      ),
    );
    expect(icon.color, AppColors.statusSurveyText);
  });

  testWidgets(
    'filters unread, marks all read and can return from empty filter',
    (tester) async {
      final container = await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Belum dibaca (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan diterima'), findsNothing);
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();
      expect(container.read(unreadCountProvider), 0);
      expect(find.text('Tidak ada notifikasi belum dibaca'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      await tester.tap(find.text('Lihat semua notifikasi'));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperNotificationTile), findsNWidgets(2));
      expect(find.bySemanticsLabel('Sudah dibaca'), findsNWidgets(2));
      expect(find.byKey(const ValueKey('unread-indicator')), findsNothing);
      expect(find.byType(SvgPicture), findsNothing);
    },
  );

  testWidgets('opens developer detail and preserves read status after back', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Jadwal survey tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('SR-TEST'), findsOneWidget);
    expect(container.read(unreadCountProvider), 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Sudah dibaca'), findsNWidgets(2));
  });

  testWidgets('empty list has an explanation and no enabled read-all action', (
    tester,
  ) async {
    await _pump(tester, items: []);
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
    // Ilustrasi kosong dari aset, bukan ikon polos.
    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.byType(DeveloperNotificationTile), findsNothing);
    expect(
      tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
      isNull,
    );
  });

  testWidgets('missing target gives feedback without leaving the list', (
    tester,
  ) async {
    await _pump(tester, items: [_items().first.copyWith(isRead: false)]);
    await tester.tap(find.text('Pengajuan diterima'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(DeveloperNotificationView), findsOneWidget);
    // Tujuan gagal dibuka: tidak ditandai dibaca.
    expect(find.bySemanticsLabel('Belum dibaca'), findsOneWidget);
  });

  for (final width in [360.0, 412.0]) {
    testWidgets('dashboard keeps active notification tab at ${width}dp', (
      tester,
    ) async {
      final container = await _pump(tester, dashboard: true, width: width);
      final nav = find.byType(BottomAppBar);
      expect(nav, findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.notifications_rounded)).color,
        AppColors.primaryRed,
      );
      expect(
        find.descendant(of: nav, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();
      expect(container.read(unreadCountProvider), 0);
      expect(find.descendant(of: nav, matching: find.text('1')), findsNothing);
      await tester.tap(find.descendant(of: nav, matching: find.text('Profil')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: nav, matching: find.text('Notifikasi')),
      );
      await tester.pumpAndSettle();
      expect(container.read(dashboardTabProvider), 2);
      expect(find.text('Semua notifikasi sudah dibaca'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'long text scrolls without overflow at ${width}dp and 200% text',
      (tester) async {
        await _pump(
          tester,
          width: width,
          textScale: 2,
          items: [
            _items().last.copyWith(
              judul:
                  'Informasi perkembangan pengajuan perumahan untuk pengembang',
              deskripsi: List.filled(
                12,
                'Rincian informasi pengajuan.',
              ).join(' '),
            ),
          ],
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('admin retains the existing notification view', (tester) async {
    // Only verify role isolation here; legacy narrow layouts are unchanged.
    await _pump(tester, role: AppRole.admin, width: 800);
    expect(find.byType(DeveloperNotificationView), findsNothing);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('perwaskim uses its own view, not the developer one', (
    tester,
  ) async {
    await _pump(tester, role: AppRole.perwaskim, width: 800);
    expect(find.byType(DeveloperNotificationView), findsNothing);
  });

  group('Perlu Revisi dan penerima Pengembang', () {
    NotifikasiModel revisi(
      String id, {
      String pengajuanId = 'REG-2026-0142',
      bool isRead = false,
      DateTime? waktu,
      AppRole? penerima = AppRole.developer,
    }) => NotifikasiModel(
      id: id,
      jenis: JenisNotifikasi.perluRevisi,
      judul: 'Revisi $id',
      deskripsi: 'Permintaan perbaikan untuk $pengajuanId.',
      waktu: waktu ?? DateTime(2026, 10, 6, 9),
      isRead: isRead,
      pengajuanId: pengajuanId,
      penerima: penerima,
    );

    NotifikasiModel biasa(
      String id, {
      AppRole? penerima = AppRole.developer,
      bool isRead = false,
    }) => NotifikasiModel(
      id: id,
      jenis: JenisNotifikasi.pengajuanBaru,
      judul: 'Biasa $id',
      deskripsi: 'Informasi biasa.',
      waktu: DateTime(2026, 10, 4, 9),
      isRead: isRead,
      penerima: penerima,
    );

    Future<void> filter(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
    }

    testWidgets('tiga filter tersedia dan Perlu Revisi memuat revisi aktif', (
      tester,
    ) async {
      await _pump(
        tester,
        items: [revisi('r1'), biasa('b1'), biasa('b2', isRead: true)],
      );
      expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Belum dibaca (2)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ChoiceChip, 'Perlu Revisi'), findsOneWidget);

      await filter(tester, 'Perlu Revisi');
      expect(find.text('Revisi r1'), findsOneWidget);
      expect(find.text('Biasa b1'), findsNothing);
      expect(find.text('TINDAKAN DIPERLUKAN'), findsOneWidget);
    });

    testWidgets('revisi aktif yang sudah dibaca tetap muncul', (tester) async {
      await _pump(tester, items: [revisi('r1', isRead: true), biasa('b1')]);
      await filter(tester, 'Perlu Revisi');
      expect(find.text('Revisi r1'), findsOneWidget);
      // Sudah dibaca, tetapi masih butuh tindakan.
      expect(find.byKey(const ValueKey('unread-indicator')), findsNothing);
      expect(find.text('TINDAKAN DIPERLUKAN'), findsOneWidget);
      await filter(tester, 'Belum dibaca (1)');
      expect(find.text('Revisi r1'), findsNothing);
    });

    testWidgets('belum dibaca bukan berarti perlu revisi', (tester) async {
      await _pump(tester, items: [biasa('b1'), biasa('b2')]);
      await filter(tester, 'Perlu Revisi');
      expect(find.text('Tidak ada revisi aktif'), findsOneWidget);
      expect(
        find.text(
          'Pengajuan Anda belum memiliki permintaan perbaikan yang perlu ditindaklanjuti.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Lihat semua notifikasi'));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperNotificationTile), findsNWidgets(2));
    });

    testWidgets(
      'revisi yang sudah dikirim keluar dari filter, tetap di Semua',
      (tester) async {
        final container = await _pump(tester, items: [revisi('r1')]);
        final notifier = container.read(pengajuanListProvider.notifier);
        final item = container
            .read(pengajuanListProvider)
            .firstWhere((e) => e.id == 'REG-2026-0142');
        notifier.updatePengajuan(item.copyWith(revisionSubmitted: true));
        await tester.pumpAndSettle();

        expect(find.text('Revisi r1'), findsOneWidget);
        expect(find.text('REVISI'), findsOneWidget);
        expect(find.text('TINDAKAN DIPERLUKAN'), findsNothing);
        await filter(tester, 'Perlu Revisi');
        expect(find.text('Revisi r1'), findsNothing);
        expect(find.text('Tidak ada revisi aktif'), findsOneWidget);
      },
    );

    testWidgets('hanya permintaan revisi terbaru per pengajuan yang aktif', (
      tester,
    ) async {
      await _pump(
        tester,
        items: [
          revisi('lama', waktu: DateTime(2026, 9, 1)),
          revisi('baru', waktu: DateTime(2026, 10, 1)),
        ],
      );
      await filter(tester, 'Perlu Revisi');
      expect(find.text('Revisi baru'), findsOneWidget);
      expect(find.text('Revisi lama'), findsNothing);
    });

    testWidgets('revisi tanpa pengajuan valid tidak dianggap aktif', (
      tester,
    ) async {
      await _pump(tester, items: [revisi('r1', pengajuanId: 'REG-TIDAK-ADA')]);
      await filter(tester, 'Perlu Revisi');
      expect(find.text('Tidak ada revisi aktif'), findsOneWidget);
    });

    testWidgets('notifikasi Admin/Perwaskim dan tanpa penerima tidak bocor', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        items: [
          biasa('milik-dev'),
          biasa('milik-admin', penerima: AppRole.admin),
          biasa('milik-perwaskim', penerima: AppRole.perwaskim),
          biasa('lama', penerima: null),
        ],
      );
      expect(find.text('Biasa milik-dev'), findsOneWidget);
      expect(find.text('Biasa milik-admin'), findsNothing);
      expect(find.text('Biasa milik-perwaskim'), findsNothing);
      expect(find.text('Biasa lama'), findsNothing);
      expect(container.read(unreadCountProvider), 1);
      expect(find.text('1 notifikasi belum dibaca'), findsOneWidget);
    });

    testWidgets('Tandai semua dibaca hanya mengubah milik Pengembang', (
      tester,
    ) async {
      final container = await _pump(
        tester,
        items: [
          biasa('milik-dev'),
          biasa('milik-admin', penerima: AppRole.admin),
          biasa('lama', penerima: null),
        ],
      );
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      final byId = {
        for (final e in container.read(notifikasiProvider)) e.id: e.isRead,
      };
      expect(byId['milik-dev'], isTrue);
      expect(byId['milik-admin'], isFalse);
      expect(byId['lama'], isFalse);
    });

    test(
      'seed Pengembang bertanda simulasi dan merujuk pengajuan yang ada',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final ids = container
            .read(pengajuanListProvider)
            .map((e) => e.id)
            .toSet();
        final milikPengembang = container
            .read(notifikasiProvider)
            .where((e) => e.untukRole(AppRole.developer))
            .toList();

        expect(milikPengembang, isNotEmpty);
        for (final item in milikPengembang) {
          expect(item.isSimulasi, isTrue, reason: item.id);
          expect(ids, contains(item.pengajuanId), reason: item.id);
        }
        // Seed lama tanpa penerima jelas tidak pernah jatuh ke Pengembang.
        expect(
          container
              .read(notifikasiProvider)
              .where(
                (e) => e.penerima == null && e.untukRole(AppRole.developer),
              ),
          isEmpty,
        );
      },
    );

    test('badge belum dibaca dihitung per role', () {
      final container = ProviderContainer(
        overrides: [
          notifikasiProvider.overrideWith(
            (ref) => _Notifications([
              biasa('d'),
              biasa('a', penerima: AppRole.admin),
              biasa('p', penerima: AppRole.perwaskim),
              biasa('n', penerima: null),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final session = container.read(roleSessionProvider.notifier);

      session.signIn(AppRole.developer);
      expect(container.read(unreadNotifikasiCountProvider), 1);
      session.signIn(AppRole.admin);
      expect(container.read(unreadNotifikasiCountProvider), 2);
      session.signIn(AppRole.perwaskim);
      expect(container.read(unreadNotifikasiCountProvider), 2);
    });

    testWidgets('revisi aktif membuka Perbarui Berkas dan menandai dibaca', (
      tester,
    ) async {
      final container = await _pump(tester, items: [revisi('r1')]);
      await tester.tap(find.text('Revisi r1'));
      await tester.pumpAndSettle();
      expect(find.text('Perbarui berkas'), findsOneWidget);
      expect(find.text('REG-2026-0142'), findsOneWidget);
      expect(container.read(unreadCountProvider), 0);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperNotificationView), findsOneWidget);
    });

    testWidgets('revisi yang sudah dikirim membuka Detail Pengajuan', (
      tester,
    ) async {
      final container = await _pump(tester, items: [revisi('r1')]);
      final item = container
          .read(pengajuanListProvider)
          .firstWhere((e) => e.id == 'REG-2026-0142');
      container
          .read(pengajuanListProvider.notifier)
          .updatePengajuan(item.copyWith(revisionSubmitted: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revisi r1'));
      await tester.pumpAndSettle();
      expect(find.text('Detail pengajuan'), findsOneWidget);
      expect(find.text('Perbarui berkas'), findsNothing);
    });

    testWidgets(
      'pengajuan tidak ditemukan: umpan balik, tidak ditandai dibaca',
      (tester) async {
        final container = await _pump(
          tester,
          items: [revisi('r1', pengajuanId: 'REG-TIDAK-ADA')],
        );
        await tester.tap(find.text('Revisi r1'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byType(DeveloperNotificationView), findsOneWidget);
        expect(container.read(unreadCountProvider), 1);
      },
    );

    testWidgets('notifikasi biasa berpengajuanId membuka Detail', (
      tester,
    ) async {
      await _pump(
        tester,
        items: [biasa('b1').copyWith(pengajuanId: 'REG-2026-0084')],
      );
      await tester.tap(find.text('Biasa b1'));
      await tester.pumpAndSettle();
      expect(find.text('Detail pengajuan'), findsOneWidget);
      expect(find.text('REG-2026-0084'), findsOneWidget);
    });

    test('activeRevisionNotificationIds menilai data pengajuan', () {
      Pengajuan p(
        String id, {
        StatusTahapPengajuan tahap = StatusTahapPengajuan.perluPerbaikan,
        bool submitted = false,
        List<String> docs = const ['ktp'],
      }) => Pengajuan(
        id: id,
        namaPerumahan: 'P',
        namaPt: 'PT',
        namaDirektur: 'D',
        npwpPerusahaan: '0',
        luasLahan: 1,
        jumlahUnit: 1,
        tipePerumahan: 'Subsidi',
        status: 'x',
        statusTahap: tahap,
        tanggal: '1 Jan 2026',
        uploadedDocs: const {},
        revisionSubmitted: submitted,
        dokumenPerluRevisi: docs,
      );
      final aktif = activeRevisionNotificationIds(
        [
          revisi('a', pengajuanId: 'A'),
          revisi('b', pengajuanId: 'B'),
          revisi('c', pengajuanId: 'C'),
          revisi('d', pengajuanId: 'D'),
          biasa('e'),
        ],
        [
          p('A'),
          p('B', submitted: true),
          p('C', tahap: StatusTahapPengajuan.surveyLapangan),
          p('D', docs: const []),
        ],
      );
      expect(aktif, {'a'});
    });

    for (final width in [360.0, 390.0, 420.0]) {
      testWidgets(
        'tiga filter dan kartu tanpa overflow di ${width}dp, teks 2x',
        (tester) async {
          await _pump(
            tester,
            width: width,
            textScale: 2,
            items: [
              revisi('r1').copyWith(
                judul:
                    'Dokumen perlu diperbaiki pada pengajuan perumahan panjang',
                deskripsi: List.filled(
                  10,
                  'Rincian permintaan perbaikan.',
                ).join(' '),
              ),
              biasa('b1'),
            ],
          );
          expect(tester.takeException(), isNull);
          for (final label in ['Perlu Revisi', 'Semua']) {
            await tester.tap(find.widgetWithText(ChoiceChip, label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('chip dan aksi berukuran sentuh minimal 44dp', (tester) async {
      await _pump(tester, items: [revisi('r1')]);
      for (final label in ['Semua', 'Perlu Revisi']) {
        final size = tester.getSize(find.widgetWithText(ChoiceChip, label));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      final markAll = tester.getSize(find.byType(TextButton).first);
      expect(markAll.height, greaterThanOrEqualTo(44));
    });
  });
}
