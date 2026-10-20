import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_colors.dart';
import 'package:satu_rumah/core/theme/app_radii.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/detail_perbarui_dokumen_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/perbarui_berkas_screen.dart';

/// Layar Perbarui Berkas harus memakai pengajuan aktif yang sama dengan
/// Detail Pengajuan: jumlah dokumen, catatan, dan daftar terverifikasi
/// diturunkan dari `Pengajuan`, bukan dari data contoh.
void main() {
  late ProviderContainer container;

  Pengajuan seed() => container
      .read(pengajuanListProvider)
      .firstWhere((e) => e.id == 'REG-2026-0142');

  Pengajuan custom(
    String id, {
    List<String> revisi = const ['ktp'],
    String? catatan = 'Scan KTP buram.',
    Map<String, bool> verified = const {},
  }) => Pengajuan(
    id: id,
    namaPerumahan: 'Perumahan Uji $id',
    namaPt: 'PT Uji',
    namaDirektur: 'Direktur Uji',
    npwpPerusahaan: '01.111.111.1-111.000',
    luasLahan: 1000,
    jumlahUnit: 10,
    tipePerumahan: 'Subsidi',
    status: 'Perlu Perbaikan',
    statusTahap: StatusTahapPengajuan.perluPerbaikan,
    tahapAsalPerbaikan: StatusTahapPengajuan.verifikasiAdministrasi,
    tanggal: '16 Okt 2026',
    uploadedDocs: const {'ktp': 'ktp_lama.pdf', 'nib': 'nib.pdf'},
    verifiedDocs: verified,
    dokumenPerluRevisi: revisi,
    catatanPerbaikan: catatan,
  );

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Widget buildTestWidget({
    String id = 'REG-2026-0142',
    double textScale = 1.0,
    DetailFilePickerSeam? pickerSeam,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: PerbaruiBerkasScreen(id: id, pickerSeam: pickerSeam),
      ),
    );
  }

  DetailFilePickerSeam pick(String name) =>
      ({allowedExtensions}) async =>
          PlatformFile(name: name, size: 2 * 1024 * 1024);

  group('PerbaruiBerkasScreen - sumber data', () {
    testWidgets('header dan kartu identitas memakai pengajuan aktif', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Perbarui Berkas'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
      expect(find.text(seed().namaPerumahan), findsOneWidget);
      expect(find.text('REG-2026-0142'), findsOneWidget);
    });

    testWidgets('jumlah dokumen revisi sama dengan Detail (2 untuk seed)', (
      tester,
    ) async {
      final item = seed();
      expect(item.dokumenPerluRevisi.length, 2);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Perlu Diperbaiki (2)'), findsOneWidget);
      expect(find.text('0/2 Berkas'), findsOneWidget);
      expect(
        find.text('1. Gambar Rencana Site Plan (DWG/PDF)'),
        findsOneWidget,
      );
      expect(
        find.text('2. Sertifikat Tanah / Hak Milik (SHM/HGB)'),
        findsOneWidget,
      );
      // Berkas contoh lama tidak lagi muncul.
      expect(find.text('1. KTP Direktur / Penanggung Jawab'), findsNothing);
      expect(find.textContaining('Pindaian buram'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('jumlah berkas multi-file mengikuti data pengajuan', (
      tester,
    ) async {
      final files = seed().technicalFiles.length;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      if (files > 1) {
        await tester.scrollUntilVisible(
          find.text('Perbarui Berkas ($files File)'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('$files file'), findsOneWidget);
      }
    });

    testWidgets('catatan verifikator sama dengan catatan di Detail', (
      tester,
    ) async {
      final note = seed().catatanPerbaikan!;
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CATATAN DARI ADMIN VERIFIKATOR'), findsOneWidget);
      expect(find.text(note), findsOneWidget);
      expect(find.text('Selengkapnya'), findsOneWidget);
      // Catatan tidak diulang per dokumen.
      expect(find.textContaining('Catatan:'), findsNothing);
    });

    testWidgets('tidak ada verifikator contoh: tampil state netral', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Hendra Wijaya'), findsNothing);
      expect(find.textContaining('18 Mar 2026'), findsNothing);
      expect(find.text('Informasi verifikator belum tersedia'), findsOneWidget);
    });

    testWidgets('dialog catatan tidak mengarang nama, waktu, atau instansi', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selengkapnya'));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Verifikator'), findsOneWidget);
      expect(find.text('Informasi perbaikan dokumen'), findsOneWidget);
      expect(find.text('Verifikator'), findsOneWidget);
      expect(find.text('Belum tersedia'), findsOneWidget);
      expect(find.text('Waktu belum tercatat'), findsOneWidget);
      expect(find.textContaining('09:30 WIB'), findsNothing);
      expect(find.text('Hendra Wijaya, S.T.'), findsNothing);
      expect(find.text('Disperwaskim Kota Tasikmalaya'), findsOneWidget);
      expect(find.text('Perbaiki Dokumen Sekarang'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Informasi perbaikan dokumen'), findsNothing);
    });

    testWidgets('pengajuan lain: 1 dokumen -> (1), 0/1, catatan miliknya', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-1'));
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-1'));
      await tester.pumpAndSettle();

      expect(find.text('Perlu Diperbaiki (1)'), findsOneWidget);
      expect(find.text('0/1 Berkas'), findsOneWidget);
      expect(find.text('Scan KTP buram.'), findsOneWidget);
      expect(find.text('Perumahan Uji REG-UJI-1'), findsOneWidget);
      expect(find.text('Perumahan Green Tasik'), findsNothing);
      expect(find.textContaining('Hendra'), findsNothing);
      expect(find.text('1. KTP Direktur / Penanggung Jawab'), findsOneWidget);
    });

    testWidgets('catatan kosong -> keterangan netral tanpa Selengkapnya', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-2', catatan: null));
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-2'));
      await tester.pumpAndSettle();

      expect(
        find.text('Belum ada catatan revisi dari verifikator.'),
        findsOneWidget,
      );
      expect(find.text('Selengkapnya'), findsNothing);
    });

    testWidgets('tanpa dokumen revisi -> empty state, kirim dinonaktifkan', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-3', revisi: const []));
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-3'));
      await tester.pumpAndSettle();

      expect(find.text('Perlu Diperbaiki (0)'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada berkas yang ditandai perlu perbaikan pada pengajuan ini.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tidak ada berkas yang perlu dikirim'), findsOneWidget);
      final kirim = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tinjau Perbaikan'),
      );
      expect(kirim.onPressed, isNull);
      expect(find.textContaining('Terverifikasi dan Terkunci'), findsNothing);
    });

    testWidgets('id tidak dikenal -> tidak jatuh ke pengajuan lain', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(id: 'REG-TIDAK-ADA'));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan tidak ditemukan.'), findsOneWidget);
      expect(find.text('Perumahan Green Tasik'), findsNothing);
      expect(find.text('Tinjau Perbaikan'), findsNothing);
    });
  });

  group('PerbaruiBerkasScreen - berkas terverifikasi', () {
    testWidgets('jumlah dan nama berasal dari data verifikasi pengajuan', (
      tester,
    ) async {
      final item = seed();
      final verified = item.verifiedDocs.entries
          .where((e) => e.value && !item.dokumenPerluRevisi.contains(e.key))
          .length;
      expect(verified, 13);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Terverifikasi dan Terkunci ($verified)'),
        findsOneWidget,
      );
      expect(find.text('$verified Berkas Sudah Terverifikasi'), findsOneWidget);
      expect(find.text('Tidak dapat diubah atau dihapus'), findsOneWidget);
      expect(find.text('NPWP Perusahaan'), findsOneWidget);
      expect(find.text('Akta Pendirian Perusahaan'), findsOneWidget);

      await tester.ensureVisible(
        find.text('$verified Berkas Sudah Terverifikasi'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('$verified Berkas Sudah Terverifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('NPWP Perusahaan'), findsNothing);

      await tester.tap(find.text('$verified Berkas Sudah Terverifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('NPWP Perusahaan'), findsOneWidget);
    });

    testWidgets('tanpa data verifikasi, bagian terkunci tidak ditampilkan', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-4'));
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-4'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Terverifikasi dan Terkunci'), findsNothing);
      expect(find.textContaining('Sudah Terverifikasi'), findsNothing);
    });

    testWidgets('dokumen yang diminta revisi tidak ikut daftar terkunci', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(
            custom(
              'REG-UJI-5',
              verified: const {'ktp': false, 'nib': true, 'npwp_doc': true},
            ),
          );
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-5'));
      await tester.pumpAndSettle();

      expect(find.text('Terverifikasi dan Terkunci (2)'), findsOneWidget);
      expect(find.text('Nomor Induk Berusaha (NIB)'), findsOneWidget);
    });
  });

  group('PerbaruiBerkasScreen - aksi dan progres', () {
    testWidgets('bilah bawah: belum disimpan, lalu Simpan Sementara', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Simpan Sementara'), findsOneWidget);
      expect(find.text('Belum disimpan permanen'), findsOneWidget);
      expect(find.textContaining('Tersimpan otomatis'), findsNothing);
      expect(find.text('Tinjau Perbaikan'), findsOneWidget);
      expect(
        find.text('Perbarui 2 berkas lagi untuk melanjutkan'),
        findsOneWidget,
      );

      await tester.tap(find.text('Simpan Sementara'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Pilihan Berkas Dicatat Sementara'), findsOneWidget);
      // Jujur: dicatat sementara, bukan persistence.
      expect(
        find.text(
          'Belum disimpan permanen. Pilihan hilang jika halaman ditutup.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('· sementara'), findsOneWidget);
      expect(find.textContaining('Berhasil Disimpan'), findsNothing);
      expect(find.textContaining('Tersimpan otomatis'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan Berkas Dicatat Sementara'), findsNothing);
    });

    testWidgets('label tombol Perbarui Berkas tidak mengecil', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final label = find.descendant(
        of: find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
        matching: find.text('Perbarui Berkas'),
      );
      await tester.ensureVisible(label);
      await tester.pumpAndSettle();
      final fitted = tester.widget<FittedBox>(
        find.ancestor(of: label, matching: find.byType(FittedBox)).first,
      );
      final box = tester.renderObject<RenderBox>(
        find.ancestor(of: label, matching: find.byType(FittedBox)).first,
      );
      // Dulu padding vertikal tema menyisakan 12px sehingga label menyusut.
      expect(box.size.height, greaterThanOrEqualTo(14));
      expect(fitted.fit, BoxFit.scaleDown);
    });

    testWidgets('Pratinjau membuka sheet simulasi yang berlabel jujur', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Pratinjau').first,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pratinjau').first);
      await tester.pumpAndSettle();

      expect(find.text('Pratinjau Dokumen'), findsOneWidget);
      expect(find.text('Pratinjau Dokumen Simulasi'), findsOneWidget);
      expect(find.text('Pratinjau Digital Dokumen Sah'), findsNothing);
      expect(find.textContaining('terdaftar resmi'), findsNothing);

      await tester.tap(find.text('Tutup Pratinjau'));
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau Dokumen'), findsNothing);
    });

    testWidgets('memperbarui satu dokumen menaikkan progres sesuai jumlah', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(
            custom(
              'REG-UJI-6',
              revisi: const ['ktp', 'bukti_kepemilikan_lahan'],
            ),
          );
      await tester.pumpWidget(
        buildTestWidget(id: 'REG-UJI-6', pickerSeam: pick('ktp_baru.pdf')),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/2 Berkas'), findsOneWidget);
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();

      // Tanpa berkas pengganti terpilih, tombol kirim nonaktif.
      expect(find.textContaining('KTP_Direktur_Revisi'), findsNothing);
      final kirim = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Kirim Perbaikan'),
      );
      expect(kirim.onPressed, isNull);

      await tester.scrollUntilVisible(
        find.text('Pilih Berkas'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pilih Berkas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Perbaikan'));
      await tester.pumpAndSettle();

      expect(find.text('1/2 Berkas'), findsOneWidget);
      expect(find.text('ktp_baru.pdf'), findsOneWidget);
      expect(
        find.text('Perbarui 1 berkas lagi untuk melanjutkan'),
        findsOneWidget,
      );
    });

    testWidgets(
      'layar detail dokumen tidak memuat tanggal atau berkas contoh',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Mar 2026'), findsNothing);
        expect(find.textContaining('KTP_Direktur'), findsNothing);
        expect(find.text(seed().catatanPerbaikan!), findsOneWidget);
        expect(find.text('Waktu belum tercatat'), findsWidgets);
      },
    );

    testWidgets('revisionSubmitted false: seed masih perlu diperbaiki', (
      tester,
    ) async {
      expect(seed().revisionSubmitted, isFalse);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('0/2 Berkas'), findsOneWidget);
      expect(find.text('Sudah Diperbarui'), findsNothing);
      expect(find.textContaining('sudah terkirim'), findsNothing);
      final tinjau = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tinjau Perbaikan'),
      );
      expect(tinjau.onPressed, isNotNull);
      final aksi = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      expect(aksi.onPressed, isNotNull);
    });

    testWidgets('revisionSubmitted true: state terkirim, aksi dinonaktifkan', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-8').copyWith(revisionSubmitted: true));
      await tester.pumpWidget(buildTestWidget(id: 'REG-UJI-8'));
      await tester.pumpAndSettle();

      expect(find.text('1/1 Berkas'), findsOneWidget);
      expect(
        find.text('Revisi sudah terkirim dan menunggu pemeriksaan verifikator'),
        findsOneWidget,
      );
      final tinjau = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tinjau Perbaikan'),
      );
      expect(tinjau.onPressed, isNull);
      final ubah = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Ubah Berkas'),
      );
      expect(ubah.onPressed, isNull);
    });

    testWidgets('dipilih belum berarti terkirim: submitted tetap false', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-9'));
      await tester.pumpWidget(
        buildTestWidget(id: 'REG-UJI-9', pickerSeam: pick('ktp_baru.pdf')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pilih Berkas'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pilih Berkas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Perbaikan'));
      await tester.pumpAndSettle();

      // Sudah dipilih, belum ditinjau/dikirim.
      expect(find.text('1/1 Berkas'), findsOneWidget);
      final item = container
          .read(pengajuanListProvider)
          .firstWhere((e) => e.id == 'REG-UJI-9');
      expect(item.revisionSubmitted, isFalse);
      expect(item.uploadedDocs['ktp'], 'ktp_lama.pdf');
    });

    testWidgets('Tinjau Perbaikan dengan dokumen belum lengkap ditolak', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tinjau Perbaikan'));
      await tester.pumpAndSettle();

      expect(find.text('Berkas Belum Lengkap'), findsOneWidget);
      expect(find.textContaining('Masih ada 2 berkas'), findsOneWidget);
    });

    testWidgets('semua dokumen diperbarui lalu dikirim memakai data nyata', (
      tester,
    ) async {
      container
          .read(pengajuanListProvider.notifier)
          .addPengajuan(custom('REG-UJI-7'));
      await tester.pumpWidget(
        buildTestWidget(id: 'REG-UJI-7', pickerSeam: pick('ktp_baru.pdf')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Perbarui Berkas').first,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pilih Berkas'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pilih Berkas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Perbaikan'));
      await tester.pumpAndSettle();

      expect(find.text('1/1 Berkas'), findsOneWidget);
      expect(
        find.text('Semua berkas siap ditinjau dan dikirim'),
        findsOneWidget,
      );

      // Snackbar "berhasil diperbarui" menutupi tombol sementara.
      ScaffoldMessenger.of(
        tester.element(find.byType(PerbaruiBerkasScreen)),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tinjau Perbaikan'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim Perbaikan Berkas?'), findsOneWidget);
      expect(find.textContaining('1 berkas'), findsOneWidget);

      await tester.tap(find.text('Ya, Kirim'));
      await tester.pumpAndSettle();

      final updated = container
          .read(pengajuanListProvider)
          .firstWhere((e) => e.id == 'REG-UJI-7');
      expect(updated.uploadedDocs['ktp'], 'ktp_baru.pdf');
      expect(updated.revisionSubmitted, isTrue);
      expect(find.text('Perbaikan Berhasil Dikirim'), findsOneWidget);
    });

    testWidgets('header memakai heroGradient dan AppRadii.hero', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final headerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final deco = widget.decoration as BoxDecoration;
          return deco.gradient == AppColors.heroGradient &&
              deco.borderRadius == AppRadii.hero;
        }
        return false;
      });
      expect(headerFinder, findsOneWidget);
    });

    testWidgets('toast bisa ditutup manual dan tidak ganda', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Sementara'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Simpan Sementara'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pilihan Berkas Dicatat Sementara'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan Berkas Dicatat Sementara'), findsNothing);
    });

    testWidgets('Perbaiki Dokumen Sekarang menutup dialog dan menggulir', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selengkapnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perbaiki Dokumen Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Informasi perbaikan dokumen'), findsNothing);
      expect(find.text('Perlu Diperbaiki (2)'), findsOneWidget);
    });
  });

  group('PerbaruiBerkasScreen - responsif', () {
    for (final size in const [Size(360, 800), Size(390, 844), Size(420, 860)]) {
      testWidgets('tanpa overflow di ${size.width.toInt()}dp', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (var i = 0; i < 4; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Tinjau Perbaikan'), findsOneWidget);
      });
    }

    testWidgets('teks 200% tanpa overflow, termasuk dialog catatan', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(textScale: 2.0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 5; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.scrollUntilVisible(
        find.text('Selengkapnya'),
        -50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Selengkapnya'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Catatan Verifikator'), findsOneWidget);
    });

    testWidgets('dialog catatan tanpa overflow di 360, 390, 420', (
      tester,
    ) async {
      for (final size in const [
        Size(360, 640),
        Size(390, 844),
        Size(420, 860),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Selengkapnya'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Selengkapnya'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Perbaiki Dokumen Sekarang'), findsOneWidget);

        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
