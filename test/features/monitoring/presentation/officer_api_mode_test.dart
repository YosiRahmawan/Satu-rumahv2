import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/camera_providers.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_form_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/services/location_service.dart';

import '../../../support/camera_fakes.dart';

class FakeOfficerRemote implements OfficerRemote {
  List<OfficerAssignment> items = [];
  ApiException? error;

  /// Galat non-API (mis. kesalahan tak terduga) yang dilempar saat kirim.
  Object? crash;
  int lists = 0;
  final List<String> keys = [];
  final List<({double lat, double lng})> positions = [];
  MonitoringModel? lastDraft;

  @override
  Future<List<OfficerAssignment>> assignments() async {
    lists++;
    return items;
  }

  @override
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  }) async {
    keys.add(draftKey);
    positions.add((lat: latitude, lng: longitude));
    lastDraft = draft;
    onProgress?.call('Mengunggah…', 0.5);
    if (crash != null) throw crash!;
    if (error != null) throw error!;
    return '600.2.5/BA-MON/X/2026/007';
  }
}

OfficerAssignment _task(int id, String nama) => OfficerAssignment(
  id: id,
  status: 'dijadwalkan',
  scheduledDate: DateTime(2026, 11, 2),
  submissionNumber: 'SR-2026-000$id',
  namaPerumahan: nama,
  namaPt: 'PT Uji',
);

ReportPhoto photo(String id, {double lat = -7.3, double lng = 108.2}) {
  PhotoBytesCache.put(id, Uint8List.fromList([1, 2, 3]));
  return ReportPhoto(
    id: id,
    source: PhotoSource.camera,
    stamp: GeoStamp(
      latitude: lat,
      longitude: lng,
      capturedAt: DateTime.utc(2026, 10, 26),
    ),
  );
}

MonitoringModel _draft({
  String id = 'draf-1',
  StatusHasilEvaluasi status = StatusHasilEvaluasi.sesuaiSiteplan,
  List<String> rtl = const [],
  List<ReportPhoto>? photos,
}) => MonitoringModel(
  id: id,
  pengajuanId: 'SR-2026-0001',
  tanggalMonitoring: DateTime(2026, 10, 26),
  namaPerumahan: 'Griya Mangkubumi',
  statusHasilEvaluasi: status,
  rencanaTindakLanjut: rtl,
  photos: photos ?? [photo('p-default', lat: -7.3274, lng: 108.2207)],
  isDraft: true,
);

ProviderContainer _container(
  FakeOfficerRemote remote, {
  FakeLocationService? location,
  bool api = true,
}) {
  final c = ProviderContainer(
    overrides: [
      if (api) apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
      officerRemoteProvider.overrideWithValue(remote),
      locationServiceProvider.overrideWithValue(
        location ?? FakeLocationService(),
      ),
      monitoringRepositoryProvider.overrideWithValue(
        MonitoringRepository(seed: false),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(PhotoBytesCache.clear);

  group('tugas survei (surveyAktif)', () {
    test('mode API: berasal dari server untuk petugas', () async {
      final remote = FakeOfficerRemote()
        ..items = [_task(1, 'Griya A'), _task(2, 'Griya B')];
      final c = _container(remote);
      c
          .read(roleSessionProvider.notifier)
          .signIn(AppRole.perwaskim, username: 'tim_lapangan');

      expect(c.read(surveyAktifProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);

      final tasks = c.read(surveyAktifProvider);
      expect(remote.lists, 1);
      expect(tasks.map((p) => p.id), ['SR-2026-0001', 'SR-2026-0002']);
      expect(tasks.first.namaPerumahan, 'Griya A');
    });

    test('mode API: peran lain tidak memanggil server', () async {
      final remote = FakeOfficerRemote()..items = [_task(1, 'A')];
      final c = _container(remote);
      c
          .read(roleSessionProvider.notifier)
          .signIn(AppRole.developer, username: 'dev');

      expect(c.read(surveyAktifProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(remote.lists, 0);
    });

    test('mode API: berganti akun memuat ulang', () async {
      final remote = FakeOfficerRemote()..items = [_task(1, 'A')];
      final c = _container(remote);
      c.listen(officerAssignmentsProvider, (_, __) {});
      final session = c.read(roleSessionProvider.notifier);
      session.signIn(AppRole.perwaskim, username: 'a');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(surveyAktifProvider), hasLength(1));

      remote.items = [];
      session.signIn(AppRole.perwaskim, username: 'b');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(surveyAktifProvider), isEmpty);
      expect(remote.lists, 2);
    });

    test('refresh gagal mengembalikan galat dan menjaga daftar lama', () async {
      final remote = FakeOfficerRemote()..items = [_task(1, 'A')];
      final c = _container(remote);
      c
          .read(roleSessionProvider.notifier)
          .signIn(AppRole.perwaskim, username: 'a');
      final n = c.read(officerAssignmentsProvider.notifier);
      await n.refresh();

      final failing = OfficerAssignmentsNotifier(_FailingRemote());
      expect((await failing.refresh())?.isNetwork, isTrue);
      expect(c.read(officerAssignmentsProvider), hasLength(1));
    });
  });

  group('kirim laporan lewat server', () {
    test(
      'galat tak terduga: gagal dengan pesan, tombol tidak terkunci',
      () async {
        final remote = FakeOfficerRemote()..crash = StateError('boom');
        final c = _container(remote, location: FakeLocationService());
        c
            .read(roleSessionProvider.notifier)
            .signIn(AppRole.perwaskim, username: 'a');
        final notifier = c.read(monitoringFormProvider.notifier);

        final result = await notifier.submitFinalViaApi(
          _draft(photos: [photo('p1')]),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('kendala tak terduga'));
        expect(c.read(monitoringFormProvider).isSubmitting, isFalse);

        // Percobaan ulang setelah galat berjalan normal.
        remote.crash = null;
        final retry = await notifier.submitFinalViaApi(
          _draft(photos: [photo('p1')]),
        );
        expect(retry.isSuccess, isTrue);
      },
    );

    test(
      'berhasil: nomor server, riwayat lokal, tugas dimuat ulang, form dikosongkan',
      () async {
        final remote = FakeOfficerRemote();
        final c = _container(remote, location: FakeLocationService());
        c
            .read(roleSessionProvider.notifier)
            .signIn(AppRole.perwaskim, username: 'a');
        final notifier = c.read(monitoringFormProvider.notifier);
        notifier.updateNamaPerumahan('Sisa Form');

        final progress = <String>[];
        final result = await notifier.submitFinalViaApi(
          _draft(photos: [photo('p1')]),
          onProgress: (m, f) => progress.add(m),
        );

        expect(result.isSuccess, isTrue);
        expect(result.model!.nomorSuratBA, '600.2.5/BA-MON/X/2026/007');
        expect(result.model!.isDraft, isFalse);
        expect(remote.positions.single, (
          lat: -7.3274,
          lng: 108.2207,
        )); // posisi GPS saat kirim
        expect(
          c
              .read(monitoringRepositoryProvider)
              .getMonitoringById('draf-1')!
              .nomorSuratBA,
          '600.2.5/BA-MON/X/2026/007',
        );
        expect(c.read(monitoringFormProvider).namaPerumahan, isEmpty);
        expect(c.read(monitoringFormProvider).isSubmitting, isFalse);
        expect(progress, isNotEmpty);
        await Future<void>.delayed(Duration.zero);
        expect(
          remote.lists,
          greaterThanOrEqualTo(1),
        ); // daftar tugas dimuat ulang
      },
    );

    test(
      'GPS tidak tersedia: memakai posisi foto terakhir; jika 0 foto ditolak validasi',
      () async {
        final noGps = FakeLocationService(
          const LocationResult.failure(LocationFailure.timeout),
        );

        final remote = FakeOfficerRemote();
        var c = _container(remote, location: noGps);
        var result = await c
            .read(monitoringFormProvider.notifier)
            .submitFinalViaApi(
              _draft(photos: [photo('a', lat: -7.1), photo('b', lat: -7.9)]),
            );
        expect(result.isSuccess, isTrue);
        expect(remote.positions.single.lat, -7.9);

        final remote2 = FakeOfficerRemote();
        c = _container(remote2, location: noGps);
        result = await c
            .read(monitoringFormProvider.notifier)
            .submitFinalViaApi(_draft(photos: const []));
        expect(result.isFailure, isTrue);
        expect(
          result.errorMessage,
          'Laporan wajib memiliki minimal 1 foto dokumentasi sebelum submit.',
        );
        expect(remote2.keys, isEmpty);
      },
    );

    test(
      'validasi lokal tetap berlaku (minimal 1 foto, RTL wajib, foto perlu diambil ulang)',
      () async {
        final remote = FakeOfficerRemote();
        final c = _container(remote);
        final notifier = c.read(monitoringFormProvider.notifier);

        var result = await notifier.submitFinalViaApi(
          _draft(photos: const []),
        );
        expect(
          result.errorMessage,
          'Laporan wajib memiliki minimal 1 foto dokumentasi sebelum submit.',
        );

        result = await notifier.submitFinalViaApi(
          _draft(status: StatusHasilEvaluasi.tidakSesuaiSiteplan),
        );
        expect(result.errorMessage, contains('Rencana Tindak Lanjut'));

        final stale = photo('x').copyWith(needsReselect: true);
        result = await notifier.submitFinalViaApi(_draft(photos: [stale]));
        expect(result.errorMessage, contains('diambil ulang'));
        expect(remote.keys, isEmpty);
      },
    );

    test(
      'gagal: pesan server, draf tidak menjadi final, kunci sama saat dicoba ulang',
      () async {
        final remote = FakeOfficerRemote()
          ..error = const ApiException(
            code: 'ERR-012',
            message: 'Foto ditolak.',
          );
        final c = _container(remote);
        final notifier = c.read(monitoringFormProvider.notifier);
        final draft = _draft(photos: [photo('p1')]);

        var result = await notifier.submitFinalViaApi(draft);
        expect(result.errorMessage, 'Foto ditolak.');
        expect(
          c.read(monitoringRepositoryProvider).getMonitoringById('draf-1'),
          isNull,
        );
        expect(c.read(monitoringFormProvider).isSubmitting, isFalse);

        remote.error = null;
        result = await notifier.submitFinalViaApi(draft);
        expect(result.isSuccess, isTrue);
        expect(remote.keys, hasLength(2));
        expect(remote.keys[0], remote.keys[1]);

        // Kirim ulang setelah sukses: dikenali sebagai duplikat, tidak memanggil server lagi.
        result = await notifier.submitFinalViaApi(draft);
        expect(result.isDuplicate, isTrue);
        expect(remote.keys, hasLength(2));
      },
    );
  });
}

class _FailingRemote implements OfficerRemote {
  @override
  Future<List<OfficerAssignment>> assignments() async =>
      throw const ApiException(code: 'NETWORK', message: 'x');

  @override
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  }) => throw UnimplementedError();
}
