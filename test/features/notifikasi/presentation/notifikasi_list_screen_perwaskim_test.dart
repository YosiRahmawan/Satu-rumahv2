import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/app_illustration.dart';
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
    child: const MaterialApp(home: NotifikasiListScreen()),
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
    testWidgets(
      'renders enterprise header, portal subtitle, avatar, and chips',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          _buildSubject(role: AppRole.perwaskim, initialNotifs: sampleNotifs),
        );
        await tester.pumpAndSettle();

        // 1. Header elements matching minimalist prototype
        // Halaman ini tab, jadi tidak ada panah kembali yang mati.
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(
          find.text('Informasi tugas dan hasil pengawasan lapangan'),
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

        // 4. Notification card contents and chevron affordances
        expect(find.text('Penugasan Survey Lapangan'), findsOneWidget);
        expect(find.text('Hasil Monitoring Disahkan'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));

        // 5. Verify Scaffold background uses Enterprise Canvas
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.enterpriseCanvas);
      },
    );

    testWidgets(
      'chevron is displayed only for notifications with valid target route',
      (tester) async {
        final notifsWithAndWithoutRoute = [
          NotifikasiModel(
            id: 'route-valid',
            jenis: JenisNotifikasi.reminderSurvey,
            judul: 'Penugasan dengan Rute Valid',
            deskripsi: 'Memiliki route detail.',
            waktu: DateTime.now(),
            targetRoute: '/monitoring/lapangan',
          ),
          NotifikasiModel(
            id: 'route-none',
            jenis: JenisNotifikasi.pengajuanBaru,
            judul: 'Notifikasi Tanpa Rute',
            deskripsi: 'Tidak memiliki route detail.',
            waktu: DateTime.now(),
            targetRoute: null,
          ),
        ];

        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          _buildSubject(
            role: AppRole.perwaskim,
            initialNotifs: notifsWithAndWithoutRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Exactly 1 chevron for the valid route notification
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'tapping notification marks it as read and synchronizes unread badge',
      (tester) async {
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
      },
    );

    testWidgets('tapping filter chips correctly filters notification items', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _buildSubject(role: AppRole.perwaskim, initialNotifs: sampleNotifs),
      );
      await tester.pumpAndSettle();

      // Tap "Belum Dibaca (2)"
      await tester.tap(find.text('Belum Dibaca (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Penugasan Survey Lapangan'), findsOneWidget);
      expect(find.text('Dokumen Perlu Diperiksa Ulang'), findsOneWidget);
      expect(find.text('Hasil Monitoring Disahkan'), findsNothing);

      // Tap "Perlu Tindak Lanjut" (only active tasks, excluding completed/final evaluation)
      await tester.ensureVisible(find.text('Perlu Tindak Lanjut'));
      await tester.tap(find.text('Perlu Tindak Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Penugasan Survey Lapangan'), findsOneWidget);
      expect(find.text('Dokumen Perlu Diperiksa Ulang'), findsOneWidget);
      expect(find.text('Hasil Monitoring Disahkan'), findsNothing);
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

    testWidgets(
      'shows contextual empty states with SurveyNotFoundIllustration for Semua, Belum Dibaca, and Perlu Tindak Lanjut',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        // 1. Test "Semua" with 0 notifications
        await tester.pumpWidget(
          _buildSubject(role: AppRole.perwaskim, initialNotifs: []),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppIllustration), findsOneWidget);
        expect(find.text('Belum ada notifikasi'), findsOneWidget);
        expect(
          find.text('Informasi penugasan dan pengawasan akan muncul di sini.'),
          findsOneWidget,
        );

        // 2. Test "Belum Dibaca" when only read item exists (0 unread)
        await tester.pumpWidget(
          _buildSubject(
            role: AppRole.perwaskim,
            initialNotifs: [sampleNotifs[1]], // only read item
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Belum Dibaca (0)'));
        await tester.pumpAndSettle();

        expect(find.byType(AppIllustration), findsOneWidget);
        expect(find.text('Semua notifikasi sudah dibaca'), findsOneWidget);
        expect(
          find.text('Belum ada pemberitahuan baru yang perlu dibaca.'),
          findsOneWidget,
        );

        // 3. Test "Perlu Tindak Lanjut" when only non-actionable (completed) item exists
        await tester.ensureVisible(find.text('Perlu Tindak Lanjut'));
        await tester.tap(find.text('Perlu Tindak Lanjut'));
        await tester.pumpAndSettle();

        expect(find.byType(AppIllustration), findsOneWidget);
        expect(find.text('Tidak ada tindak lanjut'), findsOneWidget);
        expect(
          find.text('Belum ada tugas atau evaluasi yang memerlukan tindakan.'),
          findsOneWidget,
        );
      },
    );

    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets(
        'responsive layout on width ${width}dp with 200% text scale without overflow',
        (tester) async {
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
        },
      );
    }
  });
}
