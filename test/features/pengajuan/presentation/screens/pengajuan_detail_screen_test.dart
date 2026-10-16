import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_detail_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';

void main() {
  Widget createDetailTestWidget({
    String id = 'REG-2026-0142',
    double textScale = 1.0,
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: PengajuanDetailScreen(id: id),
        ),
      ),
    );
  }

  group('PengajuanDetailScreen - Perlu Perbaikan (REG-2026-0142)', () {
    testWidgets(
      'renders all 8 mandatory sections correctly matching prototype',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PengajuanDetailScreen(id: 'REG-2026-0142'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Header Detail Pengajuan
        expect(find.text('Detail Pengajuan'), findsOneWidget);
        expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.share_outlined), findsNothing);

        // 2. Informasi Pengajuan
        expect(find.text('REG-2026-0142'), findsOneWidget);
        expect(find.text('Perlu Perbaikan'), findsWidgets);
        expect(find.text('Perumahan Green Tasik'), findsOneWidget);
        expect(find.text('Pengajuan Site Plan Baru'), findsOneWidget);
        expect(find.text('PT. Tasik Indah Sentosa'), findsOneWidget);
        expect(find.text('H. Rahmat Hidayat, S.T.'), findsOneWidget);
        expect(find.text('9120003418291'), findsOneWidget);
        expect(find.text('01.345.678.9-425.000'), findsOneWidget);
        expect(find.text('18.500 m²'), findsOneWidget);
        expect(find.text('120 Unit'), findsOneWidget);
        expect(find.text('Subsidi & Komersil'), findsOneWidget);
        expect(find.text('12 Sep 2026'), findsOneWidget);

        // 3. Persentase Verifikasi Berkas
        expect(find.text('Persentase Verifikasi Berkas'), findsOneWidget);
        expect(find.text('65%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(
          find.textContaining('13 dari 20 berkas terverifikasi'),
          findsOneWidget,
        );

        // 4. Section Perlu Perbaikan
        expect(find.text('Perlu Perbaikan (2 Berkas)'), findsOneWidget);
        expect(find.text('Revisi Diperlukan'), findsOneWidget);
        expect(
          find.text('CATATAN TIM VERIFIKATOR DISPERWASKIM:'),
          findsOneWidget,
        );
        expect(find.text('Gambar Rencana Site Plan (DWG/PDF)'), findsOneWidget);
        expect(
          find.text('Sertifikat Tanah / Hak Milik (SHM/HGB)'),
          findsOneWidget,
        );
        expect(find.text('Belum Diperbaiki'), findsWidgets);

        // 5. Linimasa Status (6 Tahapan)
        await tester.scrollUntilVisible(find.text('Linimasa Status'), 200);
        expect(find.text('Linimasa Status'), findsOneWidget);
        expect(find.text('6 Tahapan'), findsOneWidget);
        expect(find.text('Pengajuan Dibuat (Draft)'), findsOneWidget);
        expect(find.text('Pengajuan Dikirim'), findsOneWidget);
        expect(find.text('Verifikasi Berkas oleh Admin'), findsOneWidget);
        expect(find.text('Survey Lapangan Dijadwalkan'), findsOneWidget);
        expect(
          find.text('Hasil Verifikasi: SK Disetujui / Ditolak'),
          findsOneWidget,
        );

        // 6. Riwayat Catatan Perbaikan
        await tester.scrollUntilVisible(
          find.text('Riwayat Catatan Perbaikan'),
          200,
        );
        expect(find.text('Riwayat Catatan Perbaikan'), findsOneWidget);
        expect(find.text('Perbaikan ke-1'), findsOneWidget);
        expect(find.textContaining('Ir. Deden Permana'), findsOneWidget);
        expect(find.text('Surat KRK'), findsOneWidget);
        expect(find.text('Peta Kontur & Topografi'), findsOneWidget);

        // 7. Berkas Terkirim
        await tester.scrollUntilVisible(find.text('Berkas Terkirim'), 200);
        expect(find.text('Berkas Terkirim'), findsOneWidget);
        expect(find.text('Total 20 Berkas'), findsOneWidget);
        expect(find.text('Perusahaan (5)'), findsOneWidget);
        expect(find.text('Perumahan (11)'), findsOneWidget);
        expect(find.text('Teknis (4)'), findsOneWidget);
        expect(find.text('KRK Kota Tasikmalaya'), findsOneWidget);
        expect(find.text('Peta Kontur & Elevasi'), findsOneWidget);
        expect(find.text('Rekomendasi Andalalin'), findsOneWidget);
        expect(find.text('Dokumen UKL-UPL DLH'), findsOneWidget);

        // 8. Bottom Action
        expect(find.text('Perbaiki Sekarang'), findsOneWidget);
      },
    );

    testWidgets('interactive category tabs switch displayed files', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PengajuanDetailScreen(id: 'REG-2026-0142'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Berkas Terkirim'), 200);

      // Default tab is Teknis (4)
      expect(find.text('KRK Kota Tasikmalaya'), findsOneWidget);

      // Tap Perusahaan (5)
      await tester.tap(find.text('Perusahaan (5)'));
      await tester.pumpAndSettle();
      expect(find.text('Akta Pendirian Perusahaan'), findsOneWidget);
      expect(find.text('Nomor Induk Berusaha (NIB)'), findsOneWidget);

      // Tap Perumahan (11)
      await tester.tap(find.text('Perumahan (11)'));
      await tester.pumpAndSettle();
      expect(find.text('Surat Permohonan Site Plan'), findsOneWidget);
      expect(find.text('Bukti Kepemilikan Lahan (SHM)'), findsOneWidget);
    });

    testWidgets(
      'tapping Perbaiki Sekarang opens revision upload bottom sheet',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PengajuanDetailScreen(id: 'REG-2026-0142'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Perbaiki Sekarang" button
        await tester.tap(find.text('Perbaiki Sekarang'));
        await tester.pumpAndSettle();

        // Verify bottom sheet appears
        expect(find.text('Upload Berkas Perbaikan'), findsOneWidget);
        expect(find.text('Kirim Revisi Dokumen'), findsOneWidget);
      },
    );

    testWidgets('responsive at 360dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createDetailTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive at 412dp without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createDetailTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 200% text scale without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createDetailTestWidget(textScale: 2.0, container: container),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Navigation from REG-2026-0142 -> Perbaiki -> Detail', () {
    testWidgets(
      'navigates from list screen to detail screen when Perbaiki tapped',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) =>
                  const Scaffold(body: PengajuanSayaListScreen()),
            ),
            GoRoute(
              path: '/pengajuan/detail/:id',
              builder: (_, state) =>
                  PengajuanDetailScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ],
        );
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(router.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the card for REG-2026-0142
        expect(find.text('Perumahan Green Tasik'), findsOneWidget);

        // Find and tap the "Perbaiki Berkas" button on the card
        final perbaikiBtn = find.widgetWithText(
          ElevatedButton,
          'Perbaiki Berkas',
        );
        await tester.scrollUntilVisible(
          perbaikiBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(perbaikiBtn);
        await tester.pumpAndSettle();
        expect(perbaikiBtn, findsOneWidget);
        await tester.tap(perbaikiBtn);
        await tester.pumpAndSettle();

        // Verify that PengajuanDetailScreen is now displayed!
        expect(find.text('Detail Pengajuan'), findsOneWidget);
        expect(find.text('DISPERWASKIM KOTA TASIKMALAYA'), findsOneWidget);
        expect(find.text('REG-2026-0142'), findsOneWidget);
        expect(find.text('Perumahan Green Tasik'), findsOneWidget);
        expect(find.text('Perbaiki Sekarang'), findsOneWidget);
      },
    );
  });

  group('PengajuanDetailScreen - Micro-refinements', () {
    testWidgets(
      'renders Belum tersedia with secondary styling for placeholders and zero values',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-ZERO',
                namaPerumahan: 'Perumahan Zero Placeholder',
                namaPt: '',
                namaDirektur: '-',
                nib: '0000000000000',
                npwpPerusahaan: '00.000.000.0-000.000',
                luasLahan: 0,
                jumlahUnit: 0,
                tipePengajuan: 'Pengajuan Site Plan Baru',
                tipePerumahan: '',
                status: 'Dalam Proses',
                statusTahap: StatusTahapPengajuan.verifikasiTeknis,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {},
                alamatProyek: null,
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-ZERO'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Zero and placeholder items should show "Belum tersedia"
        expect(find.text('Belum tersedia'), findsWidgets);
        // Ensure deretan nol are NOT shown as valid text
        expect(find.text('0000000000000'), findsNothing);
        expect(find.text('00.000.000.0-000.000'), findsNothing);
        expect(find.text('0 m²'), findsNothing);
        expect(find.text('0 Unit'), findsNothing);

        // Check ALAMAT PROYEK label is present
        expect(find.text('ALAMAT PROYEK'), findsOneWidget);
      },
    );

    testWidgets(
      'renders project address when available and timeline shows accurate statuses',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-VALID',
                namaPerumahan: 'Perumahan Sukamukti Asri',
                namaPt: 'PT Sukamukti Indah',
                namaDirektur: 'Budi Santoso',
                nib: '1234567890123',
                npwpPerusahaan: '12.345.678.9-423.000',
                luasLahan: 12000,
                jumlahUnit: 80,
                tipePengajuan: 'Pengajuan Site Plan Baru',
                tipePerumahan: 'Komersil',
                status: 'Dalam Proses',
                statusTahap: StatusTahapPengajuan.verifikasiTeknis,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {},
                alamatProyek: 'Jl. Ir. H. Juanda No. 12, Tasikmalaya',
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-VALID'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Project address should be visible
        expect(
          find.text('Jl. Ir. H. Juanda No. 12, Tasikmalaya'),
          findsOneWidget,
        );

        // Timeline should display Selesai, Aktif, and Belum badges
        expect(find.text('Timeline Pengajuan'), findsOneWidget);
        expect(find.text('Selesai'), findsWidgets);
        expect(find.text('Aktif'), findsWidgets);
        expect(find.text('Belum'), findsWidgets);
      },
    );
  });
}
