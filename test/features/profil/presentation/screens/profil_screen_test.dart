import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/profil/presentation/screens/profil_screen.dart';

void main() {
  Widget createWidgetUnderTest({double width = 390, double height = 844}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: const ProfilScreen(),
        ),
      ),
    );
  }

  group('ProfilScreen (Profil Pengembang) Visual & Functional Target Tests', () {
    testWidgets('renders header merah with title, subtitle, and terverifikasi badge', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Profil Pengembang'), findsOneWidget);
      expect(
        find.text('Kelola informasi perusahaan dan pengaturan akun'),
        findsOneWidget,
      );
      expect(find.text('Terverifikasi'), findsOneWidget);
    });

    testWidgets('renders identity card with initials, company name, ID, and Aktif badge', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('TI'), findsOneWidget);
      expect(find.text('PT. Tasik Indah Sentosa'), findsOneWidget);
      expect(find.text('ID: Dev-2026-082'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
    });

    testWidgets('renders statistics: Total Pengajuan, Dalam Proses, Selesai', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Total Pengajuan'), findsOneWidget);
      expect(find.text('Dalam Proses'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      expect(find.text('6'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders Section Data Akun & Perusahaan with email and contact', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Data Akun & Perusahaan'), findsOneWidget);
      expect(find.text('Email Terdaftar'), findsOneWidget);
      expect(find.text('tasikindah@developer.com'), findsOneWidget);
      expect(find.text('No. Kontak Pengembang'), findsOneWidget);
      expect(find.text('0812-9876-5432'), findsOneWidget);
    });

    testWidgets('renders Section Pengaturan & Bantuan with all required menu options', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan & Bantuan'), findsOneWidget);
      expect(find.text('Profil Perusahaan & Dokumen NIB'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Pusat Bantuan Disperwaskim'), findsOneWidget);
      expect(find.text('Tentang Aplikasi Satu Rumah'), findsOneWidget);
    });

    testWidgets('renders logout button and footer text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Keluar Akun'), findsOneWidget);
      expect(find.text('SATU RUMAH • v1.0.0 (Build 2026)'), findsOneWidget);
      expect(
        find.text('Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya'),
        findsOneWidget,
      );
    });

    testWidgets('is responsive without overflow at 360dp and 412dp screen widths', (tester) async {
      // 360dp width
      await tester.pumpWidget(createWidgetUnderTest(width: 360, height: 780));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 412dp width
      await tester.pumpWidget(createWidgetUnderTest(width: 412, height: 915));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('updates statistics reactively when pengajuanListProvider updates', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfilScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget); // total
      expect(find.text('5'), findsOneWidget); // dalam proses
      expect(find.text('1'), findsOneWidget); // selesai

      // Tambahkan pengajuan baru dengan status selesai
      container.read(pengajuanListProvider.notifier).addPengajuan(
        Pengajuan(
          id: 'TEST-REACTIVE-01',
          namaPerumahan: 'Test Reactive Residence',
          namaPt: 'PT. Tasik Indah Sentosa',
          namaDirektur: 'H. Tatang Sutisna',
          npwpPerusahaan: '09.123.456.7-423.000',
          luasLahan: 10000,
          jumlahUnit: 50,
          tipePerumahan: 'Subsidi',
          status: 'Selesai',
          statusTahap: StatusTahapPengajuan.selesai,
          tanggal: '21 Juli 2026',
          uploadedDocs: const {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget); // total: 7
      expect(find.text('5'), findsOneWidget); // dalam proses: 7 - 2 = 5
      expect(find.text('2'), findsOneWidget); // selesai: 2
    });
  });
}

