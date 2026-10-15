import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/pengajuan_list_card.dart';

void main() {
  Pengajuan perluPerbaikan() => Pengajuan(
    id: 'REG-2026-0142',
    namaPerumahan: 'Perumahan Green Tasik',
    namaPt: 'PT Contoh',
    namaDirektur: 'Direktur',
    npwpPerusahaan: '01.234.567.8-411.000',
    luasLahan: 18500,
    jumlahUnit: 120,
    tipePerumahan: 'Subsidi',
    status: 'Perlu Perbaikan',
    statusTahap: StatusTahapPengajuan.perluPerbaikan,
    tanggal: '12 Sep 2026',
    uploadedDocs: const {},
    dokumenPerluRevisi: const ['ktp', 'nib'],
  );

  for (final entry in {360.0: 1.0, 300.0: 1.0, 360.0 + 0.1: 1.4}.entries) {
    testWidgets(
      'tombol Perbaiki Berkas tetap setinggi tap target di lebar ${entry.key} skala ${entry.value}',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(entry.key, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var opened = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(entry.key, 700),
                textScaler: TextScaler.linear(entry.value),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PengajuanListCard(
                    item: perluPerbaikan(),
                    onOpen: () => opened = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Font uji (Ahem) lebih lebar dari font asli; overflow horizontal di
        // sini bukan yang diuji, yang diuji adalah tinggi tombolnya.
        tester.takeException();

        final button = find.widgetWithText(ElevatedButton, 'Perbaiki Berkas');
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(36));

        await tester.tap(find.text('Perbaiki Berkas'));
        expect(opened, isTrue);
      },
    );
  }
}
