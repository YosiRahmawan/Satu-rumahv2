import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_verifikasi_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';

void main() {
  testWidgets(
    'Fase 5 completion updates only target submission to Menunggu Verifikasi Perbaikan on Pengajuan Saya list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: PengajuanSayaListScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before revision: REG-2026-0142 has 'Perlu Perbaikan'
      final itemsBefore = container.read(pengajuanListProvider);
      final targetBefore =
          itemsBefore.firstWhere((p) => p.id == 'REG-2026-0142');
      expect(targetBefore.status, equals('Perlu Perbaikan'));
      expect(targetBefore.revisionSubmitted, isFalse);

      // Perform kirimRevisi (equivalent to Ya, Kirim in Fase 4 / Fase 5 completion)
      final result = container
          .read(pengajuanVerifikasiControllerProvider.notifier)
          .kirimRevisi(
            'REG-2026-0142',
            {
              'ktp': 'revisi_ktp.pdf',
              'bukti_kepemilikan_lahan': 'revisi_sertifikat.pdf',
              'site_plan_dwg': 'revisi_site_plan.pdf',
            },
          );
      expect(result.allowed, isTrue);
      expect(result.stateChanged, isTrue);
      await tester.pumpAndSettle();

      // Check state after kirimRevisi:
      final itemsAfter = container.read(pengajuanListProvider);
      final targetAfter =
          itemsAfter.firstWhere((p) => p.id == 'REG-2026-0142');
      expect(targetAfter.status, equals('Menunggu Verifikasi Perbaikan'));
      expect(targetAfter.revisionSubmitted, isTrue);
      expect(targetAfter.diperbarui, equals('Diperbarui 2 hari lalu'));

      // Other submissions remain intact and not altered
      final reg84 =
          itemsAfter.firstWhere((p) => p.id == 'REG-2026-0084');
      expect(reg84.status, equals('Dalam Proses'));

      final reg38 =
          itemsAfter.firstWhere((p) => p.id == 'REG-2026-0038');
      expect(reg38.status, equals('Disetujui'));

      // Check UI renders status badge and text
      expect(find.text('Menunggu Verifikasi Perbaikan'), findsWidgets);
      expect(find.text('REG-2026-0142'), findsOneWidget);
      expect(find.text('Perumahan Green Tasik'), findsOneWidget);
      expect(find.text('Diperbarui 2 hari lalu'), findsOneWidget);
    },
  );
}
