import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/report_photo.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_repository.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_store.dart';

MonitoringModel _draft({String id = 'draf-uji'}) => MonitoringModel(
  id: id,
  pengajuanId: 'SR-2025-0148',
  tanggalMonitoring: DateTime(2026, 10, 20),
  namaPerumahan: 'Perumahan Uji',
  temuanLapangan: const ['Temuan satu'],
  rencanaTindakLanjut: const ['RTL satu'],
  statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
  pelaksana: const [MonitoringPerson(id: 'p1', nama: 'Rian', jabatan: 'Ketua')],
  isDraft: true,
);

void main() {
  group('JSON model', () {
    test('laporan lengkap bolak-balik tanpa kehilangan isian', () {
      final model = _draft();
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
    });

    test('data rusak diabaikan, bukan membuat aplikasi gagal', () {
      expect(MonitoringModel.fromJson(null), isNull);
      expect(MonitoringModel.fromJson({'id': 'x'}), isNull);
    });
  });

  group('MonitoringRepository dengan penyimpanan', () {
    test('draf dipulihkan oleh repository baru', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      repo.saveDraft(_draft());
      await repo.flush();

      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();

      final restored = reopened.getMonitoringById('draf-uji')!;
      expect(restored.isDraft, isTrue);
      expect(restored.namaPerumahan, 'Perumahan Uji');
      expect(restored.temuanLapangan, ['Temuan satu']);
    });

    test('memperbarui draf tidak menggandakan', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      repo.saveDraft(_draft());
      repo.saveDraft(_draft().copyWith(namaPerumahan: 'Diubah'));
      await repo.flush();

      expect(store.reports, hasLength(1));
      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();
      expect(reopened.getMonitoringById('draf-uji')!.namaPerumahan, 'Diubah');
    });

    test('hanya laporan yang berbeda dari data contoh yang disimpan', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
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

  group('Foto bergeotag pada draf', () {
    ReportPhoto photo() => ReportPhoto.create(
      source: PhotoSource.camera,
      stamp: GeoStamp(
        latitude: -7.3274,
        longitude: 108.2207,
        capturedAt: DateTime.utc(2026, 10, 20, 2, 30),
        address: 'Jl. Contoh',
        note: 'Drainase',
      ),
    );

    test('foto dan geotag-nya dipulihkan bersama draf', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      final p = photo();
      PhotoBytesCache.put(p.id, Uint8List.fromList([1, 2, 3]));
      repo.saveDraft(_draft().copyWith(photos: [p]));
      await repo.flush();

      PhotoBytesCache.clear();
      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();

      final restored = reopened.getMonitoringById('draf-uji')!;
      expect(restored.photos.single.stamp, p.stamp);
      expect(restored.photos.single.needsReselect, isFalse);
      expect(PhotoBytesCache.get(p.id), [1, 2, 3]);
    });

    test('foto yang berkasnya hilang ditandai perlu dipilih ulang', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      final p = photo();
      PhotoBytesCache.put(p.id, Uint8List.fromList([1, 2, 3]));
      repo.saveDraft(_draft().copyWith(photos: [p]));
      await repo.flush();
      store.photos.clear();

      PhotoBytesCache.clear();
      final reopened = MonitoringRepository(store: store);
      await reopened.hydrate();
      expect(
        reopened.getMonitoringById('draf-uji')!.photos.single.needsReselect,
        isTrue,
      );
    });

    test('foto yang dihapus dari draf juga dihapus dari penyimpanan', () async {
      final store = MemoryMonitoringStore();
      final repo = MonitoringRepository(store: store);
      final p = photo();
      PhotoBytesCache.put(p.id, Uint8List.fromList([1, 2, 3]));
      repo.saveDraft(_draft().copyWith(photos: [p]));
      await repo.flush();
      expect(store.photos, isNotEmpty);

      repo.saveDraft(_draft());
      await repo.flush();
      expect(store.photos, isEmpty);
    });
  });
}
