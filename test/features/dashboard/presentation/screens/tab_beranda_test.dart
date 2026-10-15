import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/developer_header.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:satu_rumah/features/dashboard/presentation/screens/tab_beranda.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';

void main() {
  group('TabBeranda Unit Tests', () {
    test('latest pengajuan safely returns null for an empty list', () {
      expect(latestPengajuan(const []), isNull);
    });

    test(
      'dashboard shortcuts map to real tabs or an explicit unavailable outcome',
      () {
        expect(dashboardShortcutTab('Pengajuan Saya'), 1);
        expect(dashboardShortcutTab('Notifikasi'), 2);
        expect(dashboardShortcutTab('Profil Saya'), 3);
        expect(dashboardShortcutTab('Format Dokumen'), isNull);
      },
    );
  });

  group('TabBeranda (Home Pengembang) UI & Responsiveness Tests', () {
    Widget createWidgetUnderTest({
      double width = 390,
      double height = 844,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 44, bottom: 34),
            ),
            child: const TabBeranda(),
          ),
        ),
      );
    }

    testWidgets('renders Header Profile Card with Satu Rumah and PORTAL PENGEMBANG', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Satu Rumah'), findsOneWidget);
      expect(find.text('PORTAL PENGEMBANG'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('renders Developer Identity Card with company, ID, and Terverifikasi badge', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('PT. Tasik Indah Sentosa'), findsOneWidget);
      expect(find.text('ID Pengembang: Dev-2026-082'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);
    });

    testWidgets('renders Card Pengajuan Terakhir with Dalam Proses badge and Cek Detail CTA', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        overrides: [
          pengajuanListProvider.overrideWith((ref) {
            final notifier = PengajuanListNotifier();
            notifier.state = [
              Pengajuan(
                id: 'TSK-2026-084',
                namaPerumahan: 'Mutiara Regency Tasik',
                namaPt: 'PT. Tasik Indah Sentosa',
                namaDirektur: 'H. Tatang Sutisna',
                npwpPerusahaan: '09.123.456.7-423.000',
                luasLahan: 12500.0,
                jumlahUnit: 45,
                tipePerumahan: 'Subsidi',
                status: 'Dalam Proses',
                tanggal: '20 Juli 2026',
                uploadedDocs: const {},
              ),
            ];
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('PENGAJUAN TERAKHIR'), findsOneWidget);
      expect(find.text('Dalam Proses'), findsOneWidget);
      expect(find.text('Mutiara Regency Tasik'), findsOneWidget);
      expect(find.text('REG - TSK-2026-084'), findsOneWidget);
      expect(find.text('Tahap: Verifikasi Administrasi Dokumen (Langkah 2 dari 4)'), findsOneWidget);
      expect(find.text('Progres kelengkapan (40%)'), findsOneWidget);
      expect(find.text('Cek Detail'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Menu Layanan Pengembang section with 4 services cards', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);
      expect(find.text('4 Layanan'), findsOneWidget);

      expect(find.text('Template Berkas'), findsOneWidget);
      expect(find.text('Download 16 slot berkas resmi'), findsOneWidget);

      expect(find.text('Jadwal Survey'), findsOneWidget);
      expect(find.text('Jadwal aktif & petugas Perwaskim'), findsOneWidget);

      expect(find.text('Unduh SK & BA'), findsOneWidget);
      expect(find.text('File persetujuan PDF resmi'), findsOneWidget);

      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(find.text('Panduan dan kontak layanan'), findsOneWidget);

      // Verify each card height is at least 162dp
      for (final title in [
        'Template Berkas',
        'Jadwal Survey',
        'Unduh SK & BA',
        'Pusat Bantuan',
      ]) {
        final cardFinder = find.ancestor(
          of: find.text(title),
          matching: find.byType(AnimatedScale),
        ).first;
        final cardSize = tester.getSize(cardFinder);
        expect(cardSize.height, greaterThanOrEqualTo(162.0));
      }
    });

    testWidgets('tapping each service card invokes its callback safely', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Tapping 'Jadwal Survey' opens JadwalSurveyScreen and can navigate back
      final jadwalCard = find.text('Jadwal Survey');
      await tester.ensureVisible(jadwalCard);
      await tester.pumpAndSettle();
      await tester.tap(jadwalCard);
      await tester.pumpAndSettle();

      expect(find.text('Daftar jadwal survey lapangan perumahan'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);

      // 2. Tapping 'Unduh SK & BA' opens UnduhSkBaScreen and can navigate back
      final unduhCard = find.text('Unduh SK & BA');
      await tester.ensureVisible(unduhCard);
      await tester.pumpAndSettle();
      await tester.tap(unduhCard);
      await tester.pumpAndSettle();

      expect(find.text('Dokumen resmi pengajuan perumahan'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);

      // 3. Tapping 'Template Berkas' opens TemplateBerkasScreen and can navigate back
      final templateCard = find.text('Template Berkas');
      await tester.ensureVisible(templateCard);
      await tester.pumpAndSettle();
      await tester.tap(templateCard);
      await tester.pumpAndSettle();

      expect(find.text('Panduan persyaratan pengajuan'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);

      // 4. Pusat Bantuan opens PusatBantuanScreen and can navigate back
      final bantuanCard = find.text('Pusat Bantuan');
      await tester.ensureVisible(bantuanCard);
      await tester.pumpAndSettle();
      await tester.tap(bantuanCard);
      await tester.pumpAndSettle();

      expect(
        find.text('Panduan dan kontak layanan Disperwaskim'),
        findsOneWidget,
      );

      // Tap back button
      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);
    });

    testWidgets('renders without overflow on 360px viewport', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(width: 360, height: 640));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Satu Rumah'), findsOneWidget);
      expect(find.text('PT. Tasik Indah Sentosa'), findsOneWidget);
      expect(find.text('PENGAJUAN TERAKHIR'), findsOneWidget);
      expect(find.text('Menu Layanan Pengembang'), findsOneWidget);
    });

    testWidgets('renders without overflow on 390px viewport', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(width: 390, height: 844));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Satu Rumah'), findsOneWidget);
    });

    testWidgets('renders without overflow on 412px viewport', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(width: 412, height: 915));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Satu Rumah'), findsOneWidget);
    });

    testWidgets('scrolling moves DeveloperHeader up with content naturally', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final headerFinder = find.byType(DeveloperHeader);
      expect(headerFinder, findsOneWidget);
      expect(tester.getTopLeft(headerFinder).dy, 0.0);

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);

      await tester.drag(scrollFinder, const Offset(0, -150));
      await tester.pumpAndSettle();

      // DeveloperHeader moves up when scrolling
      expect(tester.getTopLeft(headerFinder).dy, lessThan(0.0));
    });

    testWidgets('gap between DeveloperHeader bottom and DeveloperIdentityCard is exactly 16dp', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final headerFinder = find.byType(DeveloperHeader);
      final headerRect = tester.getRect(headerFinder);

      final cardFinder = find.ancestor(
        of: find.text('PT. Tasik Indah Sentosa'),
        matching: find.byType(Container),
      ).first;
      final cardRect = tester.getRect(cardFinder);

      // Visual gap between header bottom and identity card top must be exactly 16dp
      expect(cardRect.top - headerRect.bottom, 16.0);
    });

    testWidgets('tapping header avatar switches dashboardTabProvider to 3 (Profil)', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TabBeranda(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(dashboardTabProvider), 0);

      // Find the avatar widget inside DeveloperHeader
      final avatarFinder = find.descendant(
        of: find.byType(DeveloperHeader),
        matching: find.byType(InkWell),
      );
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pump();

      // State switches to 3 (Profil tab) without navigating to success screen
      expect(container.read(dashboardTabProvider), 3);
    });

    testWidgets('renders and taps Template Berkas menu card', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final cardFinder = find.text('Template Berkas');
      expect(cardFinder, findsOneWidget);
      expect(find.text('Download 16 slot berkas resmi'), findsOneWidget);

      await tester.ensureVisible(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
