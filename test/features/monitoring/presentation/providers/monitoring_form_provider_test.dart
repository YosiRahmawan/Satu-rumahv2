import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/admin_dashboard_provider.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/status_tahap_pengajuan.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_verifikasi_controller.dart';

MonitoringModel _draft({
  String id = 'monitoring-submit-1',
  String? pengajuanId = 'SR-2025-0148',
  StatusHasilEvaluasi status = StatusHasilEvaluasi.sesuaiSiteplan,
  List<String> rtl = const [],
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

  group('foto dokumentasi dan adaptor photoPaths', () {
    OfficerLocation pin() => OfficerLocation(
      latitude: -7.3274,
      longitude: 108.2207,
      method: LocationMethod.manualPin,
      selectedAt: DateTime(2026, 10, 20, 9),
    );

    test(
      'updatePhotos mempertahankan metadata saat foto ditambah atau dibuang',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(monitoringFormProvider.notifier);
        final withLocation = EvidencePhotoItem.fromPath(
          'a.jpg',
          origin: PhotoOrigin.camera,
        ).copyWith(location: pin());
        notifier.updatePhotoItems([withLocation]);

        notifier.updatePhotos(['a.jpg', 'b.jpg']);
        var state = container.read(monitoringFormProvider);
        expect(state.photoPaths, ['a.jpg', 'b.jpg']);
        expect(state.photos[0], same(withLocation));
        expect(state.photos[1].location, isNull);

        notifier.updatePhotos(['b.jpg']);
        state = container.read(monitoringFormProvider);
        expect(state.photoPaths, ['b.jpg']);
      },
    );

    test(
      'menampilkan ulang daftar yang sama tidak mengubah ID maupun sidik form',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(monitoringFormProvider.notifier);
        notifier.updatePhotos(['a.jpg', 'b.jpg']);
        final before = container.read(monitoringFormProvider);

        notifier.updatePhotos(['a.jpg', 'b.jpg']);
        final after = container.read(monitoringFormProvider);

        expect(after.photos.map((p) => p.id), before.photos.map((p) => p.id));
        expect(
          MonitoringFormNotifier.signature(after),
          MonitoringFormNotifier.signature(before),
        );
      },
    );

    test(
      'menentukan lokasi foto mengubah sidik form (perubahan belum tersimpan)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(monitoringFormProvider.notifier);
        notifier.updatePhotos(['a.jpg']);
        final before = MonitoringFormNotifier.signature(
          container.read(monitoringFormProvider),
        );

        final photo = container.read(monitoringFormProvider).photos.single;
        notifier.updatePhotoItems([photo.copyWith(location: pin())]);

        expect(
          MonitoringFormNotifier.signature(
            container.read(monitoringFormProvider),
          ),
          isNot(before),
        );
      },
    );

    test('draf menyimpan dan memuat kembali metadata foto', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(monitoringFormProvider.notifier);
      notifier.updateNamaPerumahan('Griya Foto');
      final photo =
          EvidencePhotoItem.fromPath(
            'a.jpg',
            origin: PhotoOrigin.gallery,
          ).copyWith(
            exif: const ExifGeo(latitude: -7.3, longitude: 108.2),
            location: pin(),
          );
      notifier.updatePhotoItems([
        photo,
        EvidencePhotoItem.fromPath('lama.jpg'),
      ]);

      final saved = notifier.saveDraft()!;
      expect(saved.photos.first, photo);

      notifier.resetForm();
      expect(container.read(monitoringFormProvider).photos, isEmpty);
      notifier.loadDraft(repository.getMonitoringById(saved.id)!);

      final loaded = container.read(monitoringFormProvider).photos;
      expect(loaded.length, 2);
      expect(loaded.first, photo);
      expect(loaded.first.exif, isNotNull);
      expect(loaded.first.location!.method, LocationMethod.manualPin);
      expect(loaded.last.location, isNull);
    });

    test('draf lama tanpa metadata dimuat tanpa koordinat palsu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(monitoringFormProvider.notifier);
      final legacy = MonitoringModel(
        id: 'draft-lama',
        tanggalMonitoring: DateTime(2026, 5, 1),
        namaPerumahan: 'Perumahan Lama',
        photoPaths: ['x.jpg', 'y.jpg'],
        isDraft: true,
      );

      notifier.loadDraft(legacy);

      final state = container.read(monitoringFormProvider);
      expect(state.photoPaths, ['x.jpg', 'y.jpg']);
      expect(
        state.photos.every((p) => p.location == null && p.exif == null),
        isTrue,
      );
    });

    test(
      'setPhotoLocation dan clearPhotoLocation hanya menyentuh satu foto',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(monitoringFormProvider.notifier);
        notifier.updatePhotos(['a.jpg', 'b.jpg']);
        final ids = container
            .read(monitoringFormProvider)
            .photos
            .map((p) => p.id)
            .toList();

        notifier.setPhotoLocation(ids[1], pin());
        var photos = container.read(monitoringFormProvider).photos;
        expect(photos[0].location, isNull);
        expect(photos[1].location!.latitude, -7.3274);

        notifier.clearPhotoLocation(ids[1]);
        photos = container.read(monitoringFormProvider).photos;
        expect(photos[1].location, isNull);
      },
    );

    test(
      'attachPhotoMeta mengisi asal dan EXIF sekali, tanpa menyentuh lokasi',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(monitoringFormProvider.notifier);
        notifier.updatePhotos(['a.jpg']);
        final id = container.read(monitoringFormProvider).photos.single.id;
        notifier.setPhotoLocation(id, pin());

        notifier.attachPhotoMeta(
          'a.jpg',
          origin: PhotoOrigin.camera,
          exif: const ExifGeo(latitude: -7.1, longitude: 108.1),
        );
        var photo = container.read(monitoringFormProvider).photos.single;
        expect(photo.origin, PhotoOrigin.camera);
        expect(photo.exif!.latitude, -7.1);
        expect(photo.location!.latitude, -7.3274);

        // Panggilan kedua tidak menimpa nilai yang sudah ada.
        notifier.attachPhotoMeta(
          'a.jpg',
          origin: PhotoOrigin.gallery,
          exif: const ExifGeo(latitude: 1, longitude: 2),
        );
        photo = container.read(monitoringFormProvider).photos.single;
        expect(photo.origin, PhotoOrigin.camera);
        expect(photo.exif!.latitude, -7.1);
      },
    );

    test('submit final ditolak bila ada foto tanpa lokasi', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(monitoringFormProvider.notifier);
      final draft = _draft(id: 'monitoring-foto-tanpa-lokasi').copyWith(
        photos: [
          EvidencePhotoItem.fromPath('a.jpg').copyWith(location: pin()),
          EvidencePhotoItem.fromPath('b.jpg'),
        ],
      );

      final result = notifier.submitFinal(draft);

      expect(result.status, isNot(MonitoringSubmitStatus.success));
      expect(result.errorMessage, contains('1 foto belum memiliki lokasi'));
      expect(
        repository.getAllMonitoring().where(
          (item) => item.id == 'monitoring-foto-tanpa-lokasi',
        ),
        isEmpty,
      );
    });

    test('submit final tanpa foto tetap diterima (foto opsional)', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final result = container
          .read(monitoringFormProvider.notifier)
          .submitFinal(_draft(id: 'monitoring-tanpa-foto'));

      expect(result.status, MonitoringSubmitStatus.success);
    });

    test(
      'submit final mempertahankan foto beserta metadata dan photoPaths',
      () {
        final repository = MonitoringRepository();
        final container = ProviderContainer(
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final photo = EvidencePhotoItem.fromPath(
          'foto.jpg',
        ).copyWith(location: pin());
        final draft = _draft(
          id: 'monitoring-foto-final',
        ).copyWith(photos: [photo]);

        final result = container
            .read(monitoringFormProvider.notifier)
            .submitFinal(draft);

        expect(result.isSuccess, isTrue);
        final saved = repository.getMonitoringById('monitoring-foto-final')!;
        expect(saved.isDraft, isFalse);
        expect(saved.photos.single, photo);
        expect(saved.photoPaths, ['foto.jpg']);
        final hasil = container
            .read(pengajuanListProvider)
            .singleWhere((item) => item.id == draft.pengajuanId)
            .riwayatSurvey
            .singleWhere((item) => item.id == 'monitoring-foto-final');
        expect(hasil.photoPaths, ['foto.jpg']);
      },
    );
  });

  group('photoSubmitBlocker', () {
    OfficerLocation pin() => OfficerLocation(
      latitude: -7.3274,
      longitude: 108.2207,
      method: LocationMethod.manualPin,
      selectedAt: DateTime(2026, 10, 20),
    );

    test('tanpa foto atau semua foto siap: tidak ada penghalang', () {
      expect(photoSubmitBlocker(const []), isNull);
      expect(
        photoSubmitBlocker([
          EvidencePhotoItem.fromPath('a.jpg').copyWith(location: pin()),
        ]),
        isNull,
      );
    });

    test('foto yang perlu dipilih ulang didahulukan dari lokasi', () {
      final message = photoSubmitBlocker([
        EvidencePhotoItem.fromPath('a.jpg').copyWith(needsReselect: true),
        EvidencePhotoItem.fromPath('b.jpg'),
      ]);
      expect(message, contains('1 foto perlu dipilih ulang'));
    });

    test('foto tanpa lokasi menghalangi dengan jumlahnya', () {
      final message = photoSubmitBlocker([
        EvidencePhotoItem.fromPath('a.jpg'),
        EvidencePhotoItem.fromPath('b.jpg'),
      ]);
      expect(message, contains('2 foto belum memiliki lokasi'));
    });

    test('submit final ditolak bila ada foto yang perlu dipilih ulang', () {
      final repository = MonitoringRepository();
      final container = ProviderContainer(
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final result = container
          .read(monitoringFormProvider.notifier)
          .submitFinal(
            _draft(id: 'monitoring-pilih-ulang').copyWith(
              photos: [
                EvidencePhotoItem.fromPath(
                  'hilang.jpg',
                ).copyWith(location: pin(), needsReselect: true),
              ],
            ),
          );

      expect(result.status, isNot(MonitoringSubmitStatus.success));
      expect(result.errorMessage, contains('perlu dipilih ulang'));
    });
  });
}
