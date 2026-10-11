import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('Verifikasi Tahap 2'), findsOneWidget);
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
      expect(find.text('SOP & Layanan Dinas Perkim'), findsOneWidget);
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
  });
}
