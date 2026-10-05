import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ),
  NotifikasiModel(
    id: 'unread',
    jenis: JenisNotifikasi.reminderSurvey,
    judul: 'Jadwal survey tersedia',
    deskripsi: 'Buka pengajuan untuk melihat informasi survey.',
    waktu: DateTime(2026, 10, 5, 9),
    targetRoute: '/admin/pengajuan/detail/SR-TEST',
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
      notifikasiProvider.overrideWith((ref) => _Notifications(items ?? _items())),
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
    expect(find.text('Sudah dibaca'), findsOneWidget);
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
      await tester.tap(find.widgetWithText(ChoiceChip, 'Belum dibaca'));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan diterima'), findsNothing);
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();
      expect(container.read(unreadCountProvider), 0);
      expect(find.text('Tidak ada notifikasi belum dibaca'), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      await tester.tap(find.text('Lihat semua notifikasi'));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperNotificationTile), findsNWidgets(2));
      expect(find.text('Sudah dibaca'), findsNWidgets(2));
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
    expect(find.text('Sudah dibaca'), findsNWidgets(2));
  });

  testWidgets('empty list has an explanation and no enabled read-all action', (
    tester,
  ) async {
    await _pump(tester, items: []);
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
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
    expect(find.text('Sudah dibaca'), findsOneWidget);
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

  for (final role in [AppRole.admin, AppRole.perwaskim]) {
    testWidgets('${role.name} retains the existing notification view', (
      tester,
    ) async {
      // Only verify role isolation here; legacy narrow layouts are unchanged.
      await _pump(tester, role: role, width: 800);
      expect(find.byType(DeveloperNotificationView), findsNothing);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
  }
}
