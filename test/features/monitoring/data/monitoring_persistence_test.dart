import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/evidence_photo_item.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_store.dart';

Uint8List _jpeg(int size, [int seed = 1]) {
  final data = Uint8List(size)..fillRange(0, size, seed);
  data.setRange(0, 3, [0xFF, 0xD8, 0xFF]);
  return data;
}

OfficerLocation _pin() => OfficerLocation(
  latitude: -7.3274,
  longitude: 108.2207,
  method: LocationMethod.manualPin,
  selectedAt: DateTime(2026, 10, 20, 9),
  clarificationNote: 'Dari jalan akses',
);

MonitoringModel _draft({
  String id = 'draf-uji',
  List<EvidencePhotoItem> photos = const [],
}) => MonitoringModel(
  id: id,
  pengajuanId: 'SR-2025-0148',
  tanggalMonitoring: DateTime(2026, 10, 20),
  namaPerumahan: 'Perumahan Uji',
  temuanLapangan: const ['Temuan satu'],
  rencanaTindakLanjut: const ['RTL satu'],
  statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
  pelaksana: const [MonitoringPerson(id: 'p1', nama: 'Rian', jabatan: 'Ketua')],
  photos: photos,
  isDraft: true,
);

void main() {
  setUp(PhotoBytesCache.clear);

  group('JSON model', () {
    test('foto beserta EXIF, lokasi, dan penanda pilih ulang bolak-balik', () {
      final photo =
          EvidencePhotoItem.fromPath(
            'a.jpg',
            origin: PhotoOrigin.camera,
          ).copyWith(
            exif: ExifGeo(
              latitude: -7.3,
              longitude: 108.2,
              altitude: 12,
              capturedAt: DateTime(2026, 10, 19, 8),
            ),
            location: _pin(),
            needsReselect: true,
          );
      final decoded = EvidencePhotoItem.fromJson(
        jsonDecode(jsonEncode(photo.toJson())),
      );
      expect(decoded, photo);
    });

    test('laporan lengkap bolak-balik tanpa kehilangan isian', () {
      final model = _draft(
        photos: [
          EvidencePhotoItem.fromPath('a.jpg').copyWith(location: _pin()),
        ],
      );
      final decoded = MonitoringModel.fromJson(
        jsonDecode(jsonEncode(model.toJson())),
      )!;
      expect(decoded.id, model.id);
      expect(decoded.pengajuanId, 'SR-2025-0148');
      expect(decoded.temuanLapangan, ['Temuan satu']);
      expect(decoded.rencanaTindakLanjut, ['RTL satu']);
      expect(
        decoded.statusHasilEvaluasi,
        StatusHasilEvaluasi.perluEvaluasiLanjutan,
      );
      expect(decoded.pelaksana.single.nama, 'Rian');
      expect(decoded.isDraft, isTrue);
      expect(decoded.nomorSuratBA, model.nomorSuratBA);
      expect(decoded.photos.single, model.photos.single);
    });

    test('data rusak diabaikan, bukan membuat aplikasi gagal', () {
      expect(MonitoringModel.fromJson(null), isNull);
      expect(MonitoringModel.fromJson({'id': 'x'}), isNull);
      expect(EvidencePhotoItem.fromJson({'id': ''}), isNull);
      final withBadPhoto = MonitoringModel.fromJson({
        'id': 'x',
        'tanggalMonitoring': '2026-10-20T00:00:00.000',
        'namaPerumahan': 'A',
        'photos': [
          {'bukan': 'foto'},
          EvidencePhotoItem.fromPath('ok.jpg').toJson(),
        ],
      })!;
      expect(withBadPhoto.photos.map((p) => p.localRef), ['ok.jpg']);
    });
  });

  group('MonitoringRepository dengan penyimpanan', () {
    test('draf dan foto dipulihkan oleh repository baru', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      final photo = EvidencePhotoItem.fromPath(
        'blob:foto-1',
      ).copyWith(location: _pin());
      PhotoBytesCache.put('blob:foto-1', _jpeg(2000));
      repo.saveDraft(_draft(photos: [photo]));
      await repo.flush();

      // Simulasi aplikasi dibuka kembali: memori kosong, repository baru.
      PhotoBytesCache.clear();
      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();

      final restored = reopened.getMonitoringById('draf-uji')!;
      expect(restored.isDraft, isTrue);
      expect(restored.namaPerumahan, 'Perumahan Uji');
      final restoredPhoto = restored.photos.single;
      expect(restoredPhoto.location, photo.location);
      expect(restoredPhoto.needsReselect, isFalse);
      expect(PhotoBytesCache.get('blob:foto-1'), _jpeg(2000));
    });

    test(
      'foto di atas batas penyimpanan ditandai perlu dipilih ulang',
      () async {
        final store = MemoryMonitoringStore(photoBudgetBytes: 3000);
        final repo = MonitoringRepository(store: store);
        final small = EvidencePhotoItem.fromPath('kecil.jpg');
        final big = EvidencePhotoItem.fromPath('besar.jpg');
        PhotoBytesCache.put('kecil.jpg', _jpeg(2000));
        PhotoBytesCache.put('besar.jpg', _jpeg(2000, 2));
        repo.saveDraft(_draft(photos: [small, big]));
        await repo.flush();

        PhotoBytesCache.clear();
        final reopened = MonitoringRepository(store: store);
        await reopened.hydrate();

        final photos = reopened.getMonitoringById('draf-uji')!.photos;
        expect(photos[0].needsReselect, isFalse);
        expect(photos[1].needsReselect, isTrue);
        expect(PhotoBytesCache.contains('kecil.jpg'), isTrue);
        expect(PhotoBytesCache.contains('besar.jpg'), isFalse);
      },
    );

    test(
      'foto yang tidak pernah punya isi di memori juga perlu dipilih ulang',
      () async {
        final store = MemoryMonitoringStore();
        final repo = MonitoringRepository(store: store);
        repo.saveDraft(_draft(photos: [EvidencePhotoItem.fromPath('x.jpg')]));
        await repo.flush();

        final reopened = MonitoringRepository(store: store);
        await reopened.hydrate();
        expect(
          reopened.getMonitoringById('draf-uji')!.photos.single.needsReselect,
          isTrue,
        );
      },
    );

    test(
      'memperbarui draf tidak menggandakan dan foto yang dihapus dibersihkan',
      () async {
        final store = MemoryMonitoringStore();
        final repo = MonitoringRepository(store: store);
        final a = EvidencePhotoItem.fromPath('a.jpg');
        final b = EvidencePhotoItem.fromPath('b.jpg');
        PhotoBytesCache.put('a.jpg', _jpeg(1000));
        PhotoBytesCache.put('b.jpg', _jpeg(1000, 3));
        repo.saveDraft(_draft(photos: [a, b]));
        await repo.flush();
        expect(store.photos.keys, containsAll([a.id, b.id]));

        repo.saveDraft(_draft(photos: [a]));
        await repo.flush();
        expect(store.reports, hasLength(1));
        expect(store.photos.keys, [a.id]);
      },
    );

    test('hanya laporan yang berbeda dari data contoh yang disimpan', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      // Tidak ada perubahan apa pun: tidak ada yang perlu disimpan.
      repo.saveDraft(repo.getMonitoringById('1')!);
      await repo.flush();
      expect(store.reports, isEmpty);

      repo.saveDraft(
        repo.getMonitoringById('1')!.copyWith(namaPerumahan: 'Diubah'),
      );
      await repo.flush();
      expect(store.reports.single['id'], '1');

      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();
      expect(reopened.getMonitoringById('1')!.namaPerumahan, 'Diubah');
      expect(
        reopened.getAllMonitoring().where((m) => m.id == '1'),
        hasLength(1),
      );
    });

    test('laporan final juga bertahan', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      repo.addMonitoring(_draft(id: 'final-1').copyWith(isDraft: false));
      await repo.flush();

      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();
      expect(reopened.getMonitoringById('final-1')!.isDraft, isFalse);
    });

    test('tanpa store, perilaku lama tidak berubah', () async {
      final repo = MonitoringRepository();
      await repo.hydrate();
      repo.saveDraft(_draft());
      await repo.flush();
      expect(repo.getMonitoringById('draf-uji'), isNotNull);
    });
  });
}
