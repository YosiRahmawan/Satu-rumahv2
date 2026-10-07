import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/theme/app_radii.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/core/widgets/developer_header.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:satu_rumah/features/dashboard/presentation/screens/tab_beranda.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/notifikasi/presentation/widgets/developer_notification_view.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_list_header.dart';
import 'package:satu_rumah/features/profil/presentation/screens/profil_screen.dart';

Widget _wrap(
  Widget child, {
  double width = 390,
  double height = 844,
  double textScale = 1.0,
  ProviderContainer? container,
}) {
  final widget = MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: widget);
  }
  return ProviderScope(child: widget);
}

void main() {
  group('DeveloperHeader Canonical Unit & Design System Tests', () {
    testWidgets('renders brand SATU RUMAH, icon 40x40, and hero gradient', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const DeveloperHeader()));
      await tester.pumpAndSettle();

      expect(find.text('SATU RUMAH'), findsOneWidget);
      expect(find.text('PORTAL PENGEMBANG'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient ==
                  AppColors.heroGradient,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadii.hero);
    });

    testWidgets('renders page title, subtitle, and Terverifikasi badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DeveloperHeader(
            pageTitle: 'Test Page Title',
            pageSubtitle: 'Test Page Subtitle',
            isVerified: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Page Title'), findsOneWidget);
      expect(find.text('Test Page Subtitle'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.sealCheck), findsOneWidget);
    });

    testWidgets(
      'renders canonical notification button with badge and triggers tap',
      (tester) async {
        var notifTapped = false;
        await tester.pumpWidget(
          _wrap(
            DeveloperHeader(
              notificationCount: 3,
              onNotificationTap: () => notifTapped = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final notifBtn = find.byTooltip('Buka notifikasi');
        expect(notifBtn, findsOneWidget);

        final badge = tester.widget<Badge>(
          find.descendant(of: notifBtn, matching: find.byType(Badge)),
        );
        expect(badge.isLabelVisible, isTrue);

        await tester.tap(notifBtn);
        expect(notifTapped, isTrue);
      },
    );

    testWidgets(
      'renders canonical avatar button with initials and triggers tap',
      (tester) async {
        var avatarTapped = false;
        await tester.pumpWidget(
          _wrap(
            DeveloperHeader(
              avatarLabel: 'YR',
              showOnlineIndicator: true,
              avatarTooltip: 'Buka profil',
              onAvatarTap: () => avatarTapped = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final avatarBtn = find.byTooltip('Buka profil');
        expect(avatarBtn, findsOneWidget);
        expect(find.text('YR'), findsOneWidget);

        await tester.tap(avatarBtn);
        expect(avatarTapped, isTrue);
      },
    );

    testWidgets('hides avatar when showAvatar is false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DeveloperHeader(
            showAvatar: false,
            pageTitle: 'Profil Pengembang',
            isVerified: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Buka profil'), findsNothing);
      expect(find.text('Profil Pengembang'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
    });

    testWidgets(
      'enforces accessible 48x48 min touch targets for all action controls',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            DeveloperHeader(
              notificationCount: 1,
              onNotificationTap: () {},
              avatarLabel: 'YR',
              onAvatarTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final iconButtons = tester.widgetList<IconButton>(
          find.byType(IconButton),
        );
        for (final button in iconButtons) {
          expect(button.constraints?.minWidth, greaterThanOrEqualTo(48.0));
          expect(button.constraints?.minHeight, greaterThanOrEqualTo(48.0));
        }
      },
    );

    for (final width in [360.0, 412.0]) {
      testWidgets('no overflow at ${width}dp and 100% text scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            DeveloperHeader(
              pageTitle: 'Profil Pengembang',
              pageSubtitle: 'Kelola informasi perusahaan dan akun',
              isVerified: true,
              notificationCount: 2,
              onNotificationTap: () {},
              avatarLabel: 'YR',
              onAvatarTap: () {},
            ),
            width: width,
            textScale: 1.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('no overflow at ${width}dp and 200% text scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            DeveloperHeader(
              pageTitle: 'Profil Pengembang',
              pageSubtitle: 'Kelola informasi perusahaan dan akun',
              isVerified: true,
              notificationCount: 5,
              onNotificationTap: () {},
              avatarLabel: 'YR',
              onAvatarTap: () {},
            ),
            width: width,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Cross-Screen Header Consistency Integration Tests', () {
    testWidgets(
      'Beranda header renders brand and notification/avatar action buttons',
      (tester) async {
        final container = ProviderContainer(
          overrides: [unreadCountProvider.overrideWith((ref) => 2)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrap(const TabBeranda(), container: container),
        );
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('PORTAL PENGEMBANG'), findsOneWidget);
        expect(find.byTooltip('Buka notifikasi'), findsOneWidget);
        expect(find.byTooltip('Profil pengembang'), findsOneWidget);

        await tester.tap(find.byTooltip('Buka notifikasi'));
        expect(container.read(dashboardTabProvider), 2);
      },
    );

    testWidgets(
      'Pengajuan header renders canonical title, notification, and profile action',
      (tester) async {
        final container = ProviderContainer(
          overrides: [unreadCountProvider.overrideWith((ref) => 1)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrap(const PengajuanListHeader(), container: container),
        );
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('Pengajuan'), findsOneWidget);
        expect(
          find.text('Daftar pengajuan site plan perumahan'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Buka notifikasi'));
        expect(container.read(dashboardTabProvider), 2);

        await tester.tap(find.byTooltip('Buka profil'));
        expect(container.read(dashboardTabProvider), 3);
      },
    );

    testWidgets(
      'Notifikasi header renders canonical title, subtitle, and unread child',
      (tester) async {
        var profileOpened = false;
        await tester.pumpWidget(
          _wrap(
            DeveloperNotificationView(
              items: const [],
              unreadCount: 3,
              unreadOnly: false,
              onFilterChanged: (_) {},
              onMarkAllRead: () {},
              onOpen: (_) {},
              onAvatarTap: () => profileOpened = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(
          find.text('Pantau informasi dan perkembangan pengajuan Anda'),
          findsOneWidget,
        );
        expect(find.text('3 notifikasi belum dibaca'), findsOneWidget);

        await tester.tap(find.byTooltip('Buka profil'));
        expect(profileOpened, isTrue);
      },
    );

    testWidgets(
      'Profil header renders canonical title, subtitle, and Terverifikasi badge',
      (tester) async {
        await tester.pumpWidget(_wrap(const ProfilScreen()));
        await tester.pumpAndSettle();

        expect(find.text('SATU RUMAH'), findsOneWidget);
        expect(find.text('Profil Pengembang'), findsOneWidget);
        expect(
          find.text('Kelola informasi perusahaan dan pengaturan akun'),
          findsOneWidget,
        );
        expect(find.text('Terverifikasi'), findsOneWidget);
        expect(find.byIcon(PhosphorIconsRegular.sealCheck), findsOneWidget);
        expect(find.byTooltip('Buka profil'), findsNothing);
      },
    );
  });
}
