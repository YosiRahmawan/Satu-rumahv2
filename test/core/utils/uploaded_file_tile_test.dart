import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/utils/file_picker_util.dart';

void main() {
  Widget host(Widget child, {double width = 390}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  UploadedFileTile tile({
    String name = 'KTP_Direktur.pdf',
    int? size = 1024 * 1024,
    VoidCallback? onPreview,
    VoidCallback? onReplace,
    VoidCallback? onDelete,
  }) => UploadedFileTile(
    fileName: name,
    sizeBytes: size,
    onPreview: onPreview ?? () {},
    onReplace: onReplace ?? () {},
    onDelete: onDelete ?? () {},
  );

  testWidgets('PDF memakai ikon dokumen, DWG memakai ikon khusus', (
    tester,
  ) async {
    await tester.pumpWidget(host(tile()));
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.architecture), findsNothing);

    await tester.pumpWidget(host(tile(name: 'denah.dwg')));
    expect(find.byIcon(Icons.architecture), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
  });

  testWidgets('menampilkan nama asli dan metadata FORMAT · ukuran · status', (
    tester,
  ) async {
    await tester.pumpWidget(host(tile(size: 1536 * 1024)));
    expect(find.text('KTP_Direktur.pdf'), findsOneWidget);
    expect(find.text('PDF · 1.5 MB · Terunggah'), findsOneWidget);

    await tester.pumpWidget(host(tile(size: null)));
    expect(
      find.text('PDF · Ukuran tidak tersedia · Terunggah'),
      findsOneWidget,
    );
    expect(find.textContaining('Terverifikasi'), findsNothing);
  });

  testWidgets('aksi Lihat, Ganti, Hapus berurutan, berfungsi, dan 44dp', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        tile(
          onPreview: () => calls.add('lihat'),
          onReplace: () => calls.add('ganti'),
          onDelete: () => calls.add('hapus'),
        ),
      ),
    );

    final lihat = find.byTooltip('Lihat Dokumen');
    final ganti = find.byTooltip('Ganti Dokumen');
    final hapus = find.byTooltip('Hapus Dokumen');
    expect(
      tester.getTopLeft(lihat).dx < tester.getTopLeft(ganti).dx &&
          tester.getTopLeft(ganti).dx < tester.getTopLeft(hapus).dx,
      isTrue,
    );
    for (final finder in [lihat, ganti, hapus]) {
      expect(tester.getSize(finder).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
    }

    await tester.tap(lihat);
    await tester.tap(ganti);
    await tester.tap(hapus);
    expect(calls, ['lihat', 'ganti', 'hapus']);
  });

  testWidgets('nama file panjang tidak overflow di 360, 390, dan 420dp', (
    tester,
  ) async {
    for (final width in [360.0, 390.0, 420.0]) {
      await tester.pumpWidget(
        host(
          tile(
            name:
                'Dokumen_Perencanaan_Site_Plan_Perumahan_Revisi_Final_2026.pdf',
          ),
          width: width,
        ),
      );
      expect(tester.takeException(), isNull, reason: 'lebar $width');
    }
  });

  test('satu ikon unggah canonical', () {
    expect(FilePickerUtil.uploadIcon, Icons.cloud_upload_outlined);
  });
}
