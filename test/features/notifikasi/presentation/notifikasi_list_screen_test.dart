import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/notifikasi/presentation/screens/notifikasi_list_screen.dart';

Widget _buildSubject({
  required AppRole role,
  List<NotifikasiModel>? initialNotifs,
}) {
  return ProviderScope(
    overrides: [
      roleSessionProvider.overrideWith((ref) {
        final notifier = RoleSessionNotifier();
        notifier.signIn(role, username: 'petugas_lapangan');
        return notifier;
      }),
      if (initialNotifs != null)
        notifikasiProvider.overrideWith((ref) {
          final notifier = NotifikasiNotifier();
          notifier.state = initialNotifs;
          return notifier;
        }),
    ],
    child: const MaterialApp(
      home: NotifikasiListScreen(),
    ),
  );
}

void main() {
  final sampleNotifs = [
    NotifikasiModel(
      id: 'notif-1',
      jenis: JenisNotifikasi.reminderSurvey,
      judul: 'Penugasan Survey Lapangan',
      deskripsi: 'Lokasi Perumahan Griya Mangkubumi Asri telah dijadwalkan.',
      waktu: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      targetRoute: '/monitoring/lapangan',
    ),
    NotifikasiModel(
      id: 'notif-2',
      jenis: JenisNotifikasi.deadlineVerifikasi,
      judul: 'Hasil Monitoring Disahkan',
      deskripsi: 'Berita Acara untuk Permata Hijau Residence telah final.',
      waktu: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      targetRoute: '/monitoring/lapangan',
    ),
    NotifikasiModel(
      id: 'notif-3',
      jenis: JenisNotifikasi.dokumenDiunggahUlang,
      judul: 'Dokumen Perlu Diperiksa Ulang',
      deskripsi: 'Pengembang telah memperbarui siteplan perumahan.',
      waktu: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
      targetRoute: '/monitoring/lapangan',
    ),
  ];

  group('NotifikasiListScreen - Pengawas Lapangan (Perwaskim)', () {
    testWidgets('renders enterprise header, portal subtitle, avatar, and chips', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _buildSubject(
          role: AppRole.perwaskim,
          initialNotifs: sampleNotifs,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header elements matching minimalist prototype
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(
        find.text('Pembaruan penugasan, monitoring, dan evaluasi lapangan'),
        findsOneWidget,
      );
      // Removed decorative logo, portal text, and bell icon
      expect(find.text('SATU RUMAH'), findsNothing);
      expect(find.text('PORTAL PENGAWAS LAPANGAN'), findsNothing);
      expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
      expect(find.byIcon(Icons.home_work_outlined), findsNothing);

      // 2. Horizontal Filter Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Belum Dibaca (2)'), findsOneWidget);
      expect(find.text('Perlu Tindak Lanjut'), findsOneWidget);
      expect(find.text('Tandai semua dibaca'), findsOneWidget);

      // 3. Category badges on cards
      expect(find.text('JADWAL PENINJAUAN'), findsOneWidget);
      expect(find.text('EVALUASI LAPANGAN'), findsOneWidget);
      expect(find.text('TINDAKAN DIPERLUKAN'), findsOneWidget);

      // 4. Notification card contents
      expect(find.text('Penugasan Survey Lapangan'), findsOneWidget);
      expect(find.text('Hasil Monitoring Disahkan'), findsOneWidget);

      // 5. Verify Scaffold background uses Enterprise Canvas
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.enterpriseCanvas);
    });

    testWidgets('tapping notification marks it as read and synchronizes unread badge', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          roleSessionProvider.overrideWith((ref) {
            final notifier = RoleSessionNotifier();
            notifier.signIn(AppRole.perwaskim, username: 'petugas_lapangan');
            return notifier;
          }),
          notifikasiProvider.overrideWith((ref) {
            final notifier = NotifikasiNotifier();
            notifier.state = sampleNotifs;
            return notifier;
          }),
        ],
      );

      expect(container.read(unreadNotifikasiCountProvider), 2);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotifikasiListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap unread notification
      await tester.tap(find.text('Penugasan Survey Lapangan'));
      await tester.pumpAndSettle();

      // Unread count is updated from 2 to 1
      expect(container.read(unreadNotifikasiCountProvider), 1);
    });

    testWidgets('tapping filter chips correctly filters notification items', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _buildSubject(
          role: AppRole.perwaskim,
          initialNotifs: sampleNotifs,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Belum Dibaca (2)"
      await tester.tap(find.text('Belum Dibaca (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Penugasan Survey Lapangan'), findsOneWidget);
      expect(find.text('Dokumen Perlu Diperiksa Ulang'), findsOneWidget);
      expect(find.text('Hasil Monitoring Disahkan'), findsNothing);

      // Tap "Perlu Tindak Lanjut"
      await tester.ensureVisible(find.text('Perlu Tindak Lanjut'));
      await tester.tap(find.text('Perlu Tindak Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Dokumen Perlu Diperiksa Ulang'), findsOneWidget);
      expect(find.text('Hasil Monitoring Disahkan'), findsOneWidget);
      expect(find.text('Penugasan Survey Lapangan'), findsNothing);
    });

    testWidgets('tapping Tandai semua dibaca marks all items as read', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          roleSessionProvider.overrideWith((ref) {
            final notifier = RoleSessionNotifier();
            notifier.signIn(AppRole.perwaskim, username: 'petugas_lapangan');
            return notifier;
          }),
          notifikasiProvider.overrideWith((ref) {
            final notifier = NotifikasiNotifier();
            notifier.state = sampleNotifs;
            return notifier;
          }),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotifikasiListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(container.read(unreadNotifikasiCountProvider), 0);
    });

    testWidgets('shows empty state when no items match filter', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _buildSubject(
          role: AppRole.perwaskim,
          initialNotifs: [sampleNotifs[1]], // only read item
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Belum Dibaca (0)'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada notifikasi.'), findsOneWidget);
    });

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets('responsive layout on width ${width}dp with 200% text scale without overflow', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: _buildSubject(
              role: AppRole.perwaskim,
              initialNotifs: sampleNotifs,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('NotifikasiListScreen - Pengembang (Developer)', () {
    testWidgets('preserves developer warm surface and standard header without regression', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _buildSubject(
          role: AppRole.developer,
          initialNotifs: sampleNotifs,
        ),
      );
      await tester.pumpAndSettle();

      // In developer tab, back button is omitted and warm surface is preserved
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('SATU RUMAH'), findsOneWidget);
      expect(find.text('PORTAL PENGAWAS LAPANGAN'), findsNothing);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.surfaceWarm);
    });
  });
}
