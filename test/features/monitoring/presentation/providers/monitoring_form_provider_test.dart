import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_verifikasi_controller.dart';

ReportPhoto _testPhoto(String id, {bool needsReselect = false}) => ReportPhoto(
  id: id,
  source: PhotoSource.camera,
  needsReselect: needsReselect,
  stamp: GeoStamp(
    latitude: -7.3274,
    longitude: 108.2207,
    capturedAt: DateTime(2025, 5, 22),
  ),
);

MonitoringModel _draft({
  String id = 'monitoring-submit-1',
  String? pengajuanId = 'SR-2025-0148',
  StatusHasilEvaluasi status = StatusHasilEvaluasi.sesuaiSiteplan,
  List<String> rtl = const [],
  List<ReportPhoto>? photos,
}) {
  return MonitoringModel(
    id: id,
    pengajuanId: pengajuanId,
    tanggalMonitoring: DateTime(2025, 5, 22),
    namaPerumahan: 'Griya Mangkubumi Asri',
    namaDeveloper: 'PT Citra Tasik Mandiri',
    lokasiPerumahan: 'Kec. Mangkubumi, Kota Tasikmalaya',
    statusHasilEvaluasi: status,
    rencanaTindakLanjut: rtl,
    photos: photos ?? [_testPhoto('photo-default')],
    isDraft: true,
  );
}

void main() {
  test(
    'final submission synchronizes one report, BA history, and notification',
    () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final result = notifier.submitFinal(_draft());

      expect(result.status, MonitoringSubmitStatus.success);
      expect(result.model?.isDraft, isFalse);
      expect(
        repository.getAllMonitoring().where(
          (item) => item.id == 'monitoring-submit-1',
        ),
        hasLength(1),
      );

      final pengajuan = container
          .read(pengajuanListProvider)
          .singleWhere((item) => item.id == 'SR-2025-0148');
      expect(pengajuan.beritaAcaraPath, isNotEmpty);
      final submittedHistory = pengajuan.riwayatSurvey.where(
        (item) => item.id == 'monitoring-submit-1',
      );
      expect(submittedHistory, hasLength(1));
      expect(submittedHistory.single.statusHasilEvaluasi, 'sesuai');
      expect(
        container
            .read(notifikasiProvider)
            .where((item) => item.id == 'ba-notif-monitoring-submit-1'),
        hasLength(1),
      );
      expect(container.read(monitoringFormProvider).namaPerumahan, isEmpty);
    },
  );

  test('repeated token returns duplicate without repeating side effects', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(monitoringFormProvider.notifier);
    final draft = _draft(id: 'monitoring-submit-duplicate');
    final first = notifier.submitFinal(draft);
    final reportCount = repository
        .getAllMonitoring()
        .where((item) => item.id == draft.id)
        .length;
    final historyCount = container
        .read(pengajuanListProvider)
        .singleWhere((item) => item.id == draft.pengajuanId)
        .riwayatSurvey
        .where((item) => item.id == draft.id)
        .length;
    final notificationCount = container
        .read(notifikasiProvider)
        .where((item) => item.id == 'ba-notif-${draft.id}')
        .length;

    final second = notifier.submitFinal(draft);

    expect(first.isSuccess, isTrue);
    expect(second.status, MonitoringSubmitStatus.duplicate);
    expect(
      repository.getAllMonitoring().where((item) => item.id == draft.id),
      hasLength(reportCount),
    );
    expect(
      container
          .read(pengajuanListProvider)
          .singleWhere((item) => item.id == draft.pengajuanId)
          .riwayatSurvey
          .where((item) => item.id == draft.id),
      hasLength(historyCount),
    );
    expect(
      container
          .read(notifikasiProvider)
          .where((item) => item.id == 'ba-notif-${draft.id}'),
      hasLength(notificationCount),
    );
  });

  test('missing matching pengajuan fails and retains form state', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Unlinked housing');
    final result = notifier.submitFinal(
      _draft(id: 'monitoring-submit-missing', pengajuanId: 'missing'),
    );

    expect(result.status, MonitoringSubmitStatus.failure);
    expect(result.errorMessage, contains('tidak ditemukan'));
    expect(notifier.state.namaPerumahan, 'Unlinked housing');
    expect(notifier.state.isSubmitting, isFalse);
    expect(
      repository.getAllMonitoring().where(
        (item) => item.id == 'monitoring-submit-missing',
      ),
      isEmpty,
    );
  });

  test('BA-link rejection is atomic and leaves every store unchanged', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [
        monitoringRepositoryProvider.overrideWithValue(repository),
        monitoringFormProvider.overrideWith(
          (ref) => MonitoringFormNotifier(
            repository,
            ref,
            uploadBa: (_, __, {hasilSurvey}) =>
                const PengajuanOperationResult.blocked(
                  'BA ditolak oleh pengajuan.',
                ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(monitoringFormProvider.notifier);
    notifier.updateNamaPerumahan('Draft retained after BA rejection');
    final beforePengajuan = container
        .read(pengajuanListProvider)
        .singleWhere((item) => item.id == 'SR-2025-0148');
    final result = notifier.submitFinal(
      _draft(id: 'monitoring-submit-ba-rejected'),
    );

    expect(result.status, MonitoringSubmitStatus.failure);
    expect(result.errorMessage, contains('BA ditolak'));
    expect(notifier.state.namaPerumahan, 'Draft retained after BA rejection');
    expect(
      repository.getAllMonitoring().where(
        (item) => item.id == 'monitoring-submit-ba-rejected',
      ),
      isEmpty,
    );
    final afterPengajuan = container
        .read(pengajuanListProvider)
        .singleWhere((item) => item.id == 'SR-2025-0148');
    expect(afterPengajuan.beritaAcaraPath, beforePengajuan.beritaAcaraPath);
    expect(afterPengajuan.riwayatSurvey, beforePengajuan.riwayatSurvey);
    expect(
      container
          .read(notifikasiProvider)
          .where((item) => item.id == 'ba-notif-monitoring-submit-ba-rejected'),
      isEmpty,
    );
  });

  test('name matching never selects a non-survey pengajuan', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final target = container
        .read(pengajuanListProvider)
        .singleWhere((item) => item.id == 'SR-2025-0148');
    container
        .read(pengajuanListProvider.notifier)
        .updatePengajuan(
          target.copyWith(statusTahap: StatusTahapPengajuan.verifikasiTeknis),
        );
    final result = container
        .read(monitoringFormProvider.notifier)
        .submitFinal(
          _draft(id: 'monitoring-submit-non-survey', pengajuanId: null),
        );

    expect(result.status, MonitoringSubmitStatus.failure);
    expect(
      repository.getAllMonitoring().where(
        (item) => item.id == 'monitoring-submit-non-survey',
      ),
      isEmpty,
    );
    expect(
      container
          .read(pengajuanListProvider)
          .singleWhere((item) => item.id == target.id)
          .riwayatSurvey,
      target.riwayatSurvey,
    );
  });

  test('rejected evaluation without RTL fails before any side effect', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = container
        .read(monitoringFormProvider.notifier)
        .submitFinal(
          _draft(
            id: 'monitoring-submit-rejected',
            status: StatusHasilEvaluasi.tidakSesuaiSiteplan,
          ),
        );

    expect(result.status, MonitoringSubmitStatus.failure);
    expect(result.errorMessage, contains('wajib'));
    expect(
      repository.getAllMonitoring().where(
        (item) => item.id == 'monitoring-submit-rejected',
      ),
      isEmpty,
    );
    expect(
      container
          .read(pengajuanListProvider)
          .singleWhere((item) => item.id == 'SR-2025-0148')
          .riwayatSurvey
          .where((item) => item.id == 'monitoring-submit-rejected'),
      isEmpty,
    );
  });

  test('follow-up evaluation keeps its distinct history status', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = container
        .read(monitoringFormProvider.notifier)
        .submitFinal(
          _draft(
            id: 'monitoring-submit-follow-up',
            status: StatusHasilEvaluasi.perluEvaluasiLanjutan,
            rtl: const ['Pemeriksaan ulang dalam 7 hari.'],
          ),
        );

    final pengajuan = container
        .read(pengajuanListProvider)
        .singleWhere((item) => item.id == 'SR-2025-0148');
    expect(result.isSuccess, isTrue);
    expect(
      pengajuan.riwayatSurvey
          .singleWhere((item) => item.id == 'monitoring-submit-follow-up')
          .statusHasilEvaluasi,
      'perlu_perbaikan',
    );
  });

  test('successful finalization refreshes dashboard monitoring metrics', () {
    final repository = MonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final before = container
        .read(adminDashboardMetricsProvider)
        .monitoringTerbaru
        .length;
    final result = container
        .read(monitoringFormProvider.notifier)
        .submitFinal(_draft(id: 'monitoring-submit-metrics'));

    expect(result.isSuccess, isTrue);
    expect(
      container.read(adminDashboardMetricsProvider).monitoringTerbaru.length,
      before + 1,
    );
  });

  group('validasi foto dokumentasi', () {
    test('submitFinal gagal jika jumlah foto 0 dan mempertahankan draf', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final draft = _draft(id: 'monitoring-0-foto', photos: const []);
      final result = notifier.submitFinal(draft);

      expect(result.status, MonitoringSubmitStatus.failure);
      expect(
        result.errorMessage,
        'Laporan wajib memiliki minimal 1 foto dokumentasi sebelum submit.',
      );
      expect(
        container.read(monitoringFormProvider).errorMessage,
        'Laporan wajib memiliki minimal 1 foto dokumentasi sebelum submit.',
      );
      expect(
        repository.getAllMonitoring().where((e) => e.id == 'monitoring-0-foto'),
        isEmpty,
      );
    });

    test('submitFinal berhasil jika memiliki 1 foto dokumentasi', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final draft = _draft(
        id: 'monitoring-1-foto',
        photos: [_testPhoto('photo-1')],
      );
      final result = notifier.submitFinal(draft);

      expect(result.status, MonitoringSubmitStatus.success);
      expect(result.model?.photos, hasLength(1));
    });

    test('submitFinal berhasil jika memiliki 10 foto dokumentasi (batas maksimal)', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final tenPhotos = List.generate(
        10,
        (i) => _testPhoto('photo-$i'),
      );
      final draft = _draft(
        id: 'monitoring-10-foto',
        photos: tenPhotos,
      );
      final result = notifier.submitFinal(draft);

      expect(result.status, MonitoringSubmitStatus.success);
      expect(result.model?.photos, hasLength(10));
    });

    test('submitFinal gagal jika foto melebihi batas maksimal (11 foto)', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final elevenPhotos = List.generate(
        11,
        (i) => _testPhoto('photo-$i'),
      );
      final draft = _draft(
        id: 'monitoring-11-foto',
        photos: elevenPhotos,
      );
      final result = notifier.submitFinal(draft);

      expect(result.status, MonitoringSubmitStatus.failure);
      expect(result.errorMessage, 'Maksimal 10 foto per laporan.');
    });

    test('submitFinal gagal jika ada foto yang perlu dipilih ulang (needsReselect)', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      final draft = _draft(
        id: 'monitoring-reselect',
        photos: [
          _testPhoto('p1'),
          _testPhoto('p2', needsReselect: true),
        ],
      );
      final result = notifier.submitFinal(draft);

      expect(result.status, MonitoringSubmitStatus.failure);
      expect(
        result.errorMessage,
        '1 foto perlu diambil ulang karena berkasnya tidak tersimpan. Hapus lalu potret kembali.',
      );
    });

    test('buildPreviewModel menolak form dengan 0 foto dan menyimpan pesan galat', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Griya Test');

      final preview = notifier.buildPreviewModel();
      expect(preview, isNull);
      expect(
        container.read(monitoringFormProvider).errorMessage,
        'Laporan wajib memiliki minimal 1 foto dokumentasi sebelum submit.',
      );
      // Data form tetap utuh
      expect(container.read(monitoringFormProvider).namaPerumahan, 'Griya Test');
    });

    test('saveDraft tetap berhasil tanpa foto untuk mendukung pengisian bertahap', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Griya Draft Bertahap');

      final draft = notifier.saveDraft();
      expect(draft, isNotNull);
      expect(draft!.photos, isEmpty);
      expect(repository.getMonitoringById(draft.id), isNotNull);
      expect(container.read(monitoringFormProvider).errorMessage, isNull);
    });
  });
}
