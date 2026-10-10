import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_beranda_monitoring.dart';

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
      expect(find.text('RH'), findsOneWidget);
      expect(find.text('Drs. Rian Hidayat, M.Si'), findsOneWidget);
      expect(find.text('Tim Verifikator Lapangan (Perwaskim)'), findsOneWidget);
      expect(find.text('NIP: 197805122006041008'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Verify Active Survey Task Card
      expect(find.textContaining('TUGAS SURVEY'), findsWidgets);
      expect(find.text('INSTRUKSI PENUGASAN ADMIN'), findsWidgets);
      expect(find.text('Buka Berita Acara & Mulai Survey'), findsWidgets);

      // Verify Latest Survey Results section
      expect(find.text('Hasil Survey Terbaru'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);
      expect(find.textContaining('Lihat Dokumen BA'), findsWidgets);
    });

    testWidgets('avoids horizontal overflow on small 360dp viewport', (
      WidgetTester tester,
    ) async {
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
    });
  });
}
