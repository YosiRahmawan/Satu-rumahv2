import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/theme/app_theme.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_detail_screen.dart';

Pengajuan _ditolak() => Pengajuan(
  id: 'SR-2026-0009',
  namaPerumahan: 'Griya Tolak',
  namaPt: 'PT Uji',
  namaDirektur: 'Direktur Uji',
  npwpPerusahaan: '01.234.567.8-901.000',
  luasLahan: 1500,
  jumlahUnit: 40,
  tipePerumahan: 'Campuran',
  status: 'Ditolak',
  statusTahap: StatusTahapPengajuan.ditolak,
  tanggal: '26 Okt 2026',
  alamatProyek: 'Jl. Uji No. 1',
  uploadedDocs: const {},
);

void main() {
  testWidgets('pengajuan ditolak menampilkan kartu alasan dan tombol Ajukan Ulang', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pengajuanListProvider.notifier).addPengajuan(_ditolak());

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PengajuanDetailScreen(id: 'SR-2026-0009'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan ditolak'), findsOneWidget);
    expect(find.text('Ajukan Ulang'), findsOneWidget);
  });

  test('prefillFrom menyalin isian tanpa berkas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pengajuanFormProvider.notifier).prefillFrom(_ditolak());

    final form = container.read(pengajuanFormProvider);
    expect(form.namaPerumahan, 'Griya Tolak');
    expect(form.alamatProyek, 'Jl. Uji No. 1');
    expect(form.jumlahUnit, 40);
    expect(form.tipePerumahan, 'Campuran');
    expect(form.isStep1Valid, isTrue);
    expect(form.uploadedDocs, isEmpty);
  });
}
