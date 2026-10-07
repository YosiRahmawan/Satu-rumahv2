import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/theme/app_radii.dart';
import 'package:satu_rumah/core/widgets/developer_header.dart';

void main() {
  Widget buildTestableWidget({
    required Widget child,
    double width = 390,
    double height = 844,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  group('DeveloperHeader Canonical Branding & Structure Tests', () {
    testWidgets('renders canonical brand identity and hero gradient', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const DeveloperHeader(),
        ),
      );
      await tester.pumpAndSettle();

      // Brand Title and Subtitle
      expect(find.text('SATU RUMAH'), findsOneWidget);
      expect(find.text('PORTAL PENGEMBANG'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

      // Verify Container decoration has hero gradient and bottom radius
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.gradient, equals(AppColors.heroGradient));
      expect(decoration.borderRadius, equals(AppRadii.hero));
    });

    testWidgets('renders Beranda variant correctly (avatar only, no page title)', (tester) async {
      var avatarTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: DeveloperHeader(
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            avatarTooltip: 'Profil Pengembang',
            onAvatarTap: () => avatarTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SATU RUMAH'), findsOneWidget);
      expect(find.text('YR'), findsOneWidget);

      await tester.tap(find.text('YR'));
      await tester.pumpAndSettle();
      expect(avatarTapped, isTrue);
    });

    testWidgets('renders Pengajuan variant correctly (notification bell with badge + avatar)', (tester) async {
      var notifTapped = false;
      var avatarTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: DeveloperHeader(
            pageTitle: 'Pengajuan',
            pageSubtitle: 'Daftar pengajuan site plan perumahan',
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            avatarTooltip: 'Buka profil',
            onAvatarTap: () => avatarTapped = true,
            notificationCount: 3,
            onNotificationTap: () => notifTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan'), findsOneWidget);
      expect(find.text('Daftar pengajuan site plan perumahan'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('YR'), findsOneWidget);

      // Tap notification bell
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(notifTapped, isTrue);

      // Tap avatar
      await tester.tap(find.text('YR'));
      await tester.pumpAndSettle();
      expect(avatarTapped, isTrue);
    });

    testWidgets('renders Notifikasi variant with child widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const DeveloperHeader(
            pageTitle: 'Notifikasi',
            pageSubtitle: 'Pantau informasi dan perkembangan pengajuan Anda',
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            avatarTooltip: 'Buka profil',
            child: Text('2 notifikasi belum dibaca'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Pantau informasi dan perkembangan pengajuan Anda'), findsOneWidget);
      expect(find.text('2 notifikasi belum dibaca'), findsOneWidget);
    });

    testWidgets('renders Profil variant with Terverifikasi badge and hidden avatar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const DeveloperHeader(
            pageTitle: 'Profil Pengembang',
            pageSubtitle: 'Kelola informasi perusahaan dan pengaturan akun',
            isVerified: true,
            showAvatar: false,
            bottomPadding: 40,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Pengembang'), findsOneWidget);
      expect(find.text('Kelola informasi perusahaan dan pengaturan akun'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('YR'), findsNothing);
    });
  });

  group('DeveloperHeader Responsive & Text Scaling Tests', () {
    testWidgets('renders safely without overflow at 360dp width and 1.0x text scale', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          width: 360,
          height: 800,
          textScale: 1.0,
          child: DeveloperHeader(
            pageTitle: 'Profil Pengembang',
            pageSubtitle: 'Kelola informasi perusahaan dan pengaturan akun',
            isVerified: true,
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            notificationCount: 2,
            onNotificationTap: () {},
            onAvatarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely without overflow at 360dp width and 2.0x text scale', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          width: 360,
          height: 800,
          textScale: 2.0,
          child: DeveloperHeader(
            pageTitle: 'Profil Pengembang',
            pageSubtitle: 'Kelola informasi perusahaan dan pengaturan akun',
            isVerified: true,
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            notificationCount: 5,
            onNotificationTap: () {},
            onAvatarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely without overflow at 412dp width and 1.0x text scale', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          width: 412,
          height: 915,
          textScale: 1.0,
          child: DeveloperHeader(
            pageTitle: 'Pengajuan',
            pageSubtitle: 'Daftar pengajuan site plan perumahan',
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            notificationCount: 1,
            onNotificationTap: () {},
            onAvatarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely without overflow at 412dp width and 2.0x text scale', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          width: 412,
          height: 915,
          textScale: 2.0,
          child: DeveloperHeader(
            pageTitle: 'Pengajuan',
            pageSubtitle: 'Daftar pengajuan site plan perumahan',
            avatarLabel: 'YR',
            showOnlineIndicator: true,
            notificationCount: 1,
            onNotificationTap: () {},
            onAvatarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
