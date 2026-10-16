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
        // Accordion default tertutup: ringkasan terlihat, tahapan belum.
        expect(
          find.text('6 Tahapan · Saat ini: Perlu Perbaikan'),
          findsOneWidget,
        );
        expect(find.text('Pengajuan Dibuat (Draft)'), findsNothing);
        await tester.tap(find.text('Linimasa Status'));
        await tester.pumpAndSettle();
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
        expect(find.text('Perbaikan ke-1'), findsNothing);
        await tester.tap(find.text('Riwayat Catatan Perbaikan'));
        await tester.pumpAndSettle();
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

  group('Phase 1: Dynamic Data Binding & Integrity Tests', () {
    testWidgets(
      '2. & 3. Renders dynamic revision documents for 1, 2, and 3 docs with different keys',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 1 revision doc
        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-REV-1',
                namaPerumahan: 'Perumahan Single Revision',
                namaPt: 'PT Single',
                namaDirektur: 'Direktur A',
                npwpPerusahaan: '01.111.111.1-111.000',
                luasLahan: 10000,
                jumlahUnit: 50,
                tipePerumahan: 'Komersil',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {'ktp': 'ktp_direktur.pdf'},
                verifiedDocs: const {'ktp': false},
                dokumenPerluRevisi: const ['ktp'],
              ),
            );

        // 3 revision docs
        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-REV-3',
                namaPerumahan: 'Perumahan Triple Revision',
                namaPt: 'PT Triple',
                namaDirektur: 'Direktur B',
                npwpPerusahaan: '02.222.222.2-222.000',
                luasLahan: 20000,
                jumlahUnit: 100,
                tipePerumahan: 'Subsidi',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {
                  'ktp': 'ktp_direktur.pdf',
                  'surat_permohonan': 'surat_permohonan.pdf',
                  'pbg_induk': 'pbg_induk.pdf',
                },
                verifiedDocs: const {
                  'ktp': false,
                  'surat_permohonan': false,
                  'pbg_induk': false,
                },
                dokumenPerluRevisi: const [
                  'ktp',
                  'surat_permohonan',
                  'pbg_induk',
                ],
              ),
            );

        // Test 1 revision doc
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-REV-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Perlu Perbaikan (1 Berkas)'), findsOneWidget);
        expect(find.text('KTP Direktur / Penanggung Jawab'), findsOneWidget);

        // Test 3 revision docs
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-REV-3'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Perlu Perbaikan (3 Berkas)'), findsOneWidget);
        expect(find.text('KTP Direktur / Penanggung Jawab'), findsOneWidget);
        expect(find.text('Surat Permohonan Site Plan'), findsOneWidget);
        expect(find.text('PBG Induk Persetujuan Gedung'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Fallback for unknown docKey displays formatted title safely without dropping item',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-UNKNOWN-KEY',
                namaPerumahan: 'Perumahan Unknown Key',
                namaPt: 'PT Unknown',
                namaDirektur: 'Direktur X',
                npwpPerusahaan: '03.333.333.3-333.000',
                luasLahan: 15000,
                jumlahUnit: 80,
                tipePerumahan: 'Komersil',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {
                  'surat_rekomendasi_bupati_khusus': 'rekom_bupati.pdf',
                },
                verifiedDocs: const {'surat_rekomendasi_bupati_khusus': false},
                dokumenPerluRevisi: const ['surat_rekomendasi_bupati_khusus'],
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-UNKNOWN-KEY'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Perlu Perbaikan (1 Berkas)'), findsOneWidget);
        expect(find.text('Surat Rekomendasi Bupati Khusus'), findsOneWidget);
      },
    );

    testWidgets(
      '5. & 6. Verification progress: shows "Belum diverifikasi" when no data, and accurate % when partial',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // No verification data
        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-NO-VERIF',
                namaPerumahan: 'Perumahan No Verif',
                namaPt: 'PT No Verif',
                namaDirektur: 'Direktur N',
                npwpPerusahaan: '04.444.444.4-444.000',
                luasLahan: 12000,
                jumlahUnit: 60,
                tipePerumahan: 'Subsidi',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {'ktp': 'ktp.pdf', 'nib': 'nib.pdf'},
                verifiedDocs: const {},
                dokumenPerluRevisi: const ['ktp'],
              ),
            );

        // Partial verification data: 2 of 4 = 50%
        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-PARTIAL-VERIF',
                namaPerumahan: 'Perumahan Partial Verif',
                namaPt: 'PT Partial',
                namaDirektur: 'Direktur P',
                npwpPerusahaan: '05.555.555.5-555.000',
                luasLahan: 14000,
                jumlahUnit: 70,
                tipePerumahan: 'Komersil',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {
                  'ktp': 'ktp.pdf',
                  'nib': 'nib.pdf',
                  'npwp_doc': 'npwp.pdf',
                  'legalitas': 'akta.pdf',
                },
                verifiedDocs: const {
                  'ktp': true,
                  'nib': true,
                  'npwp_doc': false,
                  'legalitas': false,
                },
                dokumenPerluRevisi: const ['npwp_doc'],
              ),
            );

        // Test unverified state
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-NO-VERIF'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Belum diverifikasi'), findsOneWidget);
        expect(
          find.text(
            'Belum ada data verifikasi resmi oleh verifikator Disperwaskim',
          ),
          findsOneWidget,
        );
        expect(find.text('0%'), findsNothing);
        expect(find.text('65%'), findsNothing);

        // Test partial verification state
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-PARTIAL-VERIF'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('50%'), findsOneWidget);
        expect(
          find.text(
            '2 dari 4 berkas terverifikasi resmi oleh verifikator Disperwaskim',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('7. Empty uploaded docs renders empty state without crashing', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(
            Pengajuan(
              id: 'REG-TEST-EMPTY-DOCS',
              namaPerumahan: 'Perumahan Empty Docs',
              namaPt: 'PT Empty',
              namaDirektur: 'Direktur E',
              npwpPerusahaan: '06.666.666.6-666.000',
              luasLahan: 10000,
              jumlahUnit: 40,
              tipePerumahan: 'Subsidi',
              status: 'Perlu Perbaikan',
              statusTahap: StatusTahapPengajuan.perluPerbaikan,
              tanggal: '16 Okt 2026',
              uploadedDocs: const {},
              verifiedDocs: const {},
              dokumenPerluRevisi: const [],
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PengajuanDetailScreen(id: 'REG-TEST-EMPTY-DOCS'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Berkas Terkirim'), 200);
      expect(find.text('Belum Ada Berkas'), findsOneWidget);
      expect(find.text('Belum ada berkas pada kategori ini.'), findsOneWidget);
    });

    testWidgets(
      '8. & 9. Correct file icons for PDF and DWG and multi-file technical subtitle',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-FORMATS',
                namaPerumahan: 'Perumahan Formats',
                namaPt: 'PT Formats',
                namaDirektur: 'Direktur F',
                npwpPerusahaan: '07.777.777.7-777.000',
                luasLahan: 18000,
                jumlahUnit: 90,
                tipePerumahan: 'Komersil',
                status: 'Perlu Perbaikan',
                statusTahap: StatusTahapPengajuan.perluPerbaikan,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {
                  'site_plan_dwg': 'design_siteplan.dwg',
                  'rekomendasi_lingkungan': 'amdal_lingkungan.pdf',
                },
                technicalFiles: const [
                  'design_siteplan.dwg',
                  'kontur_tambahan.dwg',
                ],
                verifiedDocs: const {
                  'site_plan_dwg': false,
                  'rekomendasi_lingkungan': true,
                },
                dokumenPerluRevisi: const ['site_plan_dwg'],
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-FORMATS'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Berkas Terkirim'), 200);
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        expect(find.byIcon(Icons.map_outlined), findsOneWidget);
        // Multi-file subtitle
        expect(
          find.textContaining('(+1 berkas teknis lainnya)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '10. Pratinjau Dokumen opens simulation bottom sheet for valid file',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-2026-0142'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Berkas Terkirim'), 200);

        // Tap the preview icon for KRK
        final previewBtns = find.byTooltip('Lihat Dokumen');
        expect(previewBtns, findsWidgets);
        await tester.tap(previewBtns.first);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Pratinjau Dokumen Simulasi'),
          findsOneWidget,
        );
        expect(find.text('Tutup'), findsOneWidget);
        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '12. Non-Perlu Perbaikan submission (Dalam Proses / Selesai) does not show Perlu Perbaikan section',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container
            .read(pengajuanListProvider.notifier)
            .addPengajuan(
              Pengajuan(
                id: 'REG-TEST-SELESAI',
                namaPerumahan: 'Perumahan Green Park Selesai',
                namaPt: 'PT Green Park',
                namaDirektur: 'Direktur S',
                npwpPerusahaan: '08.888.888.8-888.000',
                luasLahan: 25000,
                jumlahUnit: 150,
                tipePerumahan: 'Komersil',
                status: 'Selesai',
                statusTahap: StatusTahapPengajuan.selesai,
                tanggal: '16 Okt 2026',
                uploadedDocs: const {'ktp': 'ktp.pdf'},
                verifiedDocs: const {'ktp': true},
                dokumenPerluRevisi: const [],
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PengajuanDetailScreen(id: 'REG-TEST-SELESAI'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Perlu Perbaikan'), findsNothing);
        expect(find.text('Perbaiki Sekarang'), findsNothing);
        expect(find.text('Timeline Pengajuan'), findsOneWidget);
      },
    );
  });

  group('Phase 2: Detail Perlu Perbaikan - accordion dan revisi', () {
    Pengajuan revisi(String id, {String? catatan}) => Pengajuan(
      id: id,
      namaPerumahan: 'Perumahan Fase Dua',
      namaPt: 'PT Dua',
      namaDirektur: 'Direktur Dua',
      npwpPerusahaan: '03.333.333.3-333.000',
      luasLahan: 5000,
      jumlahUnit: 30,
      tipePerumahan: 'Subsidi',
      status: 'Perlu Perbaikan',
      statusTahap: StatusTahapPengajuan.perluPerbaikan,
      tanggal: '16 Okt 2026',
      uploadedDocs: const {'ktp': 'ktp.pdf'},
      verifiedDocs: const {'ktp': false},
      dokumenPerluRevisi: const ['ktp'],
      catatanPerbaikan: catatan,
    );

    Future<void> pumpDetail(
      WidgetTester tester,
      Pengajuan item, {
      double width = 390,
      double scale = 1,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pengajuanListProvider.notifier).addPengajuan(item);
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: TextScaler.linear(scale),
              ),
              child: PengajuanDetailScreen(id: item.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Linimasa dan Riwayat default tertutup, buka-tutup berfungsi', (
      tester,
    ) async {
      await pumpDetail(tester, revisi('REG-P2-1'));

      await tester.scrollUntilVisible(find.text('Linimasa Status'), 200);
      expect(find.text('Pengajuan Dikirim'), findsNothing);
      await tester.tap(find.text('Linimasa Status'));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan Dikirim'), findsOneWidget);
      await tester.tap(find.text('Linimasa Status'));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan Dikirim'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Riwayat Catatan Perbaikan'),
        200,
      );
      expect(find.textContaining('Belum ada riwayat'), findsNothing);
      await tester.tap(find.text('Riwayat Catatan Perbaikan'));
      await tester.pumpAndSettle();
      // Tanpa data riwayat: empty state jujur, tanpa verifikator karangan.
      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
      expect(find.textContaining('Deden'), findsNothing);
    });

    testWidgets('catatan global tampil sekali dan tidak diulang per berkas', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        revisi('REG-P2-2', catatan: 'Koordinat UTM belum ada.'),
      );

      expect(find.text('"Koordinat UTM belum ada."'), findsOneWidget);
      expect(find.textContaining('Catatan verifikator:'), findsNothing);
      expect(find.text('KTP Direktur / Penanggung Jawab'), findsWidgets);
    });

    testWidgets(
      'pengajuan non-demo tidak menampilkan waktu atau catatan karangan',
      (tester) async {
        await pumpDetail(tester, revisi('REG-P2-7'));
        await tester.scrollUntilVisible(find.text('Linimasa Status'), 200);
        await tester.tap(find.text('Linimasa Status'));
        await tester.pumpAndSettle();

        expect(find.text('10 Sep 2026, 09:30 WIB'), findsNothing);
        expect(find.text('14 Sep 2026, 11:00 WIB'), findsNothing);
        expect(find.text('15 Sep 2026, 16:20 WIB'), findsNothing);
        expect(find.textContaining('14:15 WIB'), findsNothing);
        expect(find.text('Waktu belum tercatat'), findsWidgets);
        expect(find.textContaining('masa berlaku habis'), findsNothing);
      },
    );

    testWidgets('bottom sheet tidak menampilkan berkas lama sebagai Dipilih', (
      tester,
    ) async {
      await pumpDetail(tester, revisi('REG-P2-8'));
      await tester.tap(find.text('Perbaiki Sekarang'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.textContaining('Dipilih'), findsNothing);
      expect(find.text('ktp.pdf'), findsNothing);
    });

    testWidgets('CTA Perbaiki Sekarang tetap fixed dan membuka bottom sheet', (
      tester,
    ) async {
      await pumpDetail(tester, revisi('REG-P2-3'));
      final cta = find.text('Perbaiki Sekarang');
      expect(cta, findsOneWidget);
      // Fixed di bawah layar: posisi tidak berubah saat konten digulir.
      final before = tester.getTopLeft(cta);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(cta), before);

      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('tautan Perbarui Berkas berukuran minimal 44dp', (
      tester,
    ) async {
      await pumpDetail(tester, revisi('REG-P2-4'));
      final link = find
          .ancestor(
            of: find.text('Perbarui Berkas'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getSize(link).height, greaterThanOrEqualTo(44));
    });

    for (final width in [360.0, 390.0, 420.0]) {
      testWidgets('tanpa overflow saat semua accordion terbuka ($width)', (
        tester,
      ) async {
        await pumpDetail(tester, revisi('REG-P2-5'), width: width);
        for (final title in ['Linimasa Status', 'Riwayat Catatan Perbaikan']) {
          await tester.scrollUntilVisible(find.text(title), 200);
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tanpa overflow pada teks 2x dengan accordion terbuka', (
      tester,
    ) async {
      await pumpDetail(tester, revisi('REG-P2-6'), scale: 2);
      for (final title in ['Linimasa Status', 'Riwayat Catatan Perbaikan']) {
        await tester.scrollUntilVisible(find.text(title), 200);
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
