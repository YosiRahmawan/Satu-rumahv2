import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_list_card.dart';

void main() {
  Pengajuan selesai({String? nomorSk, String? tanggalSk, String? skPath}) =>
      Pengajuan(
        id: 'REG-2026-0038',
        namaPerumahan: 'Grand Tasik Harmoni',
        namaPt: 'PT Contoh',
        namaDirektur: 'Direktur',
        npwpPerusahaan: '01.234.567.8-411.000',
        luasLahan: 12000,
        jumlahUnit: 85,
        tipePerumahan: 'Subsidi',
        status: 'Disetujui',
        statusTahap: StatusTahapPengajuan.selesai,
        tanggal: '12 Agu 2026',
        uploadedDocs: const {},
        nomorSk: nomorSk,
        tanggalSk: tanggalSk,
        skPersetujuanPath: skPath,
      );

  Future<void> pump(
    WidgetTester tester,
    Pengajuan item, {
    VoidCallback? onOpenSk,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 900),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PengajuanListCard(
                item: item,
                onOpen: () {},
                onOpenSk: onOpenSk,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Lihat SK memanggil onOpenSk dan berukuran minimal 44dp', (
    tester,
  ) async {
    var opened = 0;
    await pump(
      tester,
      selesai(
        nomorSk: '648/SK-SP/DPKP/2026',
        tanggalSk: '28 Agu 2026',
        skPath: 'SK_Persetujuan.pdf',
      ),
      onOpenSk: () => opened++,
    );

    final link = find
        .ancestor(of: find.text('Lihat SK'), matching: find.byType(InkWell))
        .first;
    expect(link, findsOneWidget);
    final size = tester.getSize(link);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Lihat SK'));
    expect(opened, 1);
    expect(find.text('648/SK-SP/DPKP/2026'), findsOneWidget);
    expect(find.text('28 Agu 2026'), findsOneWidget);
  });

  testWidgets('tanpa data SK tidak menampilkan nomor atau tanggal karangan', (
    tester,
  ) async {
    await pump(tester, selesai(), onOpenSk: () {});

    expect(find.text('648/SK-SP/DPKP/2026'), findsNothing);
    expect(find.text('Belum tersedia'), findsOneWidget);
    // Tanggal SK tidak diganti tanggal pengajuan.
    expect(find.text('12 Agu 2026'), findsNothing);
    // Tanpa berkas SK tercatat: bukan tombol, melainkan keterangan tenang.
    expect(find.text('Lihat SK'), findsNothing);
    expect(find.text('SK belum tersedia'), findsOneWidget);
  });

  testWidgets('tidak overflow pada teks besar', (tester) async {
    await pump(tester, selesai(), onOpenSk: () {}, scale: 2);
    expect(tester.takeException(), isNull);
    await pump(
      tester,
      selesai(
        nomorSk: '648/SK-SP/DPKP/2026',
        tanggalSk: '28 Agu 2026',
        skPath: 'SK.pdf',
      ),
      onOpenSk: () {},
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
