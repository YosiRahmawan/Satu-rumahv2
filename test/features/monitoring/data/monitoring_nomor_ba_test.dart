import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';

MonitoringModel _report(
  String id, {
  String? nomor,
  DateTime? tanggal,
  bool isDraft = true,
}) => MonitoringModel(
  id: id,
  tanggalMonitoring: tanggal ?? DateTime(2026, 10, 19),
  namaPerumahan: 'Perumahan $id',
  nomorSuratBA: nomor,
  pengajuanId: 'SR-2025-0148',
  isDraft: isDraft,
);

void main() {
  group('format nomor', () {
    test('tanpa urutan sama dengan format lama', () {
      expect(
        MonitoringModel.generateNomorSuratBA(DateTime(2026, 10, 19)),
        '600.2.5/BA-MON/X/2026',
      );
    });

    test('dengan urutan ditambah tiga digit', () {
      expect(
        MonitoringModel.generateNomorSuratBA(DateTime(2026, 10, 19), urutan: 2),
        '600.2.5/BA-MON/X/2026/002',
      );
      expect(
        MonitoringModel.generateNomorSuratBA(DateTime(2026, 1, 3), urutan: 12),
        '600.2.5/BA-MON/I/2026/012',
      );
    });
  });

  group('urutan per bulan di repository', () {
    test('bulan tanpa laporan: mulai dari 001', () {
      final repo = MonitoringRepository();
      expect(
        repo.nextNomorSuratBA(DateTime(2027, 3, 5)),
        '600.2.5/BA-MON/III/2027/001',
      );
    });

    test('nomor lama tanpa urutan dihitung 1, berikutnya 002', () {
      final repo = MonitoringRepository()
        ..addMonitoring(_report('lama', nomor: '600.2.5/BA-MON/X/2026'));
      expect(
        repo.nextNomorSuratBA(DateTime(2026, 10, 20)),
        '600.2.5/BA-MON/X/2026/002',
      );
    });

    test('mengambil urutan tertinggi + 1 dan mengabaikan bulan lain', () {
      final repo = MonitoringRepository()
        ..addMonitoring(_report('a', nomor: '600.2.5/BA-MON/X/2026/002'))
        ..addMonitoring(_report('b', nomor: '600.2.5/BA-MON/X/2026/007'))
        ..addMonitoring(_report('c', nomor: '600.2.5/BA-MON/XI/2026/009'));
      expect(
        repo.nextNomorSuratBA(DateTime(2026, 10, 1)),
        '600.2.5/BA-MON/X/2026/008',
      );
      expect(
        repo.nextNomorSuratBA(DateTime(2026, 10, 1), exceptId: 'b'),
        '600.2.5/BA-MON/X/2026/003',
      );
    });

    test('nomor yang sudah dipakai laporan lain dikenali', () {
      final repo = MonitoringRepository()
        ..addMonitoring(_report('a', nomor: '600.2.5/BA-MON/X/2026/001'));
      expect(repo.isNomorSuratBATaken('600.2.5/BA-MON/X/2026/001'), isTrue);
      expect(
        repo.isNomorSuratBATaken('600.2.5/BA-MON/X/2026/001', exceptId: 'a'),
        isFalse,
      );
      expect(repo.isNomorSuratBATaken('600.2.5/BA-MON/X/2026/002'), isFalse);
    });

    test('seed bawaan tidak berubah', () {
      final repo = MonitoringRepository();
      expect(
        repo.getMonitoringById('1')!.nomorSuratBA,
        'BA/PERWASKIM/2025/05/0148',
      );
      expect(
        repo.getMonitoringById('m1')!.nomorSuratBA,
        '600.2.5/BA-MON/V/2024',
      );
    });
  });

  group('form: nomor unik per laporan', () {
    ProviderContainer makeContainer(MonitoringRepository repo) {
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('dua draf baru di bulan yang sama mendapat nomor berbeda', () {
      final repo = MonitoringRepository();
      final container = makeContainer(repo);
      final notifier = container.read(monitoringFormProvider.notifier);

      notifier.updateNamaPerumahan('Perumahan Satu');
      final first = notifier.saveDraft()!;
      notifier.resetForm();
      notifier.updateNamaPerumahan('Perumahan Dua');
      final second = notifier.saveDraft()!;

      expect(first.nomorSuratBA, isNot(second.nomorSuratBA));
      expect(second.nomorSuratBA.compareTo(first.nomorSuratBA), greaterThan(0));
    });

    test('draf yang disimpan ulang mempertahankan nomornya', () {
      final repo = MonitoringRepository();
      final container = makeContainer(repo);
      final notifier = container.read(monitoringFormProvider.notifier);

      notifier.updateNamaPerumahan('Perumahan Satu');
      final first = notifier.saveDraft()!;
      notifier.updateNamaPerumahan('Perumahan Satu Revisi');
      final again = notifier.saveDraft()!;

      expect(again.id, first.id);
      expect(again.nomorSuratBA, first.nomorSuratBA);
    });

    test('submit final mengganti nomor bila sudah dipakai laporan lain', () {
      final repo = MonitoringRepository()
        ..addMonitoring(
          _report('orang-lain', nomor: '600.2.5/BA-MON/X/2026/001'),
        );
      final container = makeContainer(repo);
      final notifier = container.read(monitoringFormProvider.notifier);

      final result = notifier.submitFinal(
        _report('saya', nomor: '600.2.5/BA-MON/X/2026/001'),
      );

      expect(result.status, MonitoringSubmitStatus.success);
      expect(result.model!.nomorSuratBA, '600.2.5/BA-MON/X/2026/002');
      expect(
        repo.getMonitoringById('orang-lain')!.nomorSuratBA,
        '600.2.5/BA-MON/X/2026/001',
      );
    });

    test('submit final mempertahankan nomor yang masih bebas', () {
      final repo = MonitoringRepository();
      final container = makeContainer(repo);
      final notifier = container.read(monitoringFormProvider.notifier);

      final result = notifier.submitFinal(
        _report('saya', nomor: '600.2.5/BA-MON/X/2026/005'),
      );

      expect(result.model!.nomorSuratBA, '600.2.5/BA-MON/X/2026/005');
    });
  });
}
