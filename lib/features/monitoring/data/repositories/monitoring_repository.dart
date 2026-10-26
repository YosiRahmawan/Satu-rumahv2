import 'dart:async';
import 'dart:convert';

import '../models/monitoring_model.dart';
import '../models/report_photo.dart';
import '../models/status_hasil_evaluasi.dart';
import '../photo_bytes_cache.dart';
import 'monitoring_store.dart';

class MonitoringRepository {
  /// [store] menyimpan draf dan laporan buatan pengguna di perangkat. Tanpa
  /// store, data hanya hidup selama aplikasi berjalan (perilaku tes).
  ///
  /// [seed] false (mode API) membuang laporan contoh bawaan agar riwayat hanya
  /// berisi laporan nyata.
  MonitoringRepository({MonitoringStore? store, bool seed = true})
    : _store = store {
    if (!seed) _items.clear();
    _seedJson = {for (final item in _items) item.id: jsonEncode(item.toJson())};
  }

  final MonitoringStore? _store;

  /// Isi data contoh bawaan; hanya laporan yang berbeda darinya yang disimpan.
  late final Map<String, String> _seedJson;
  Future<void> _persistQueue = Future.value();

  final List<MonitoringModel> _items = [
    MonitoringModel(
      id: 'm1',
      tanggalMonitoring: DateTime(2024, 5, 20),
      namaPerumahan: 'Permata Hijau Residence',
      namaDeveloper: 'PT ABC Property',
      lokasiPerumahan: 'Jl. Ir. H. Juanda No. 45, Tasikmalaya',
      statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
      temuanLapangan: [
        'Drainase utama sudah terbangun 80%',
        'Penerangan jalan umum belum terpasang di Blok C',
      ],
      kesimpulan: [
        'Progres pembangunan PSU sesuai jadwal namun perlu percepatan PJU.',
      ],
      kesepakatan: [
        'Pengembang bersedia menyelesaikan PJU sebelum akhir bulan.',
      ],
      rencanaTindakLanjut: [
        'Pemeriksaan ulang fisik PJU pada tanggal 5 Juni 2024.',
      ],
      pelaksanaNama: 'Ir. Ahmad Subagja',
      pelaksanaJabatan: 'Ketua Tim Evaluasi Disperwaskim',
      ditemuiNama: 'H. Endang',
      ditemuiJabatan: 'Perwakilan PT ABC Property',
    ),
    MonitoringModel(
      id: '1',
      nomorSuratBA: 'BA/PERWASKIM/2025/05/0148',
      tanggalMonitoring: DateTime(2025, 5, 22),
      namaPerumahan: 'Griya Mangkubumi Asri',
      namaDeveloper: 'PT Citra Tasik Mandiri',
      lokasiPerumahan: 'Kec. Mangkubumi, Kota Tasikmalaya',
      statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
      temuanLapangan: [
        'Saluran drainase sisi timur belum sesuai detail rencana.',
        'Akses kendaraan pemadam perlu penegasan pada area tikungan blok C.',
      ],
      kesimpulan: [
        'Kawasan dapat dilanjutkan setelah perbaikan desain drainase dan penyampaian revisi gambar teknis.',
      ],
      kesepakatan: ['Pengembang akan mengunggah revisi dalam 7 hari kerja.'],
      rencanaTindakLanjut: [
        'RENCANA TINDAK LANJUT WAJIB: Perbarui gambar drainase dan lengkapi simulasi manuver kendaraan pemadam sebelum persetujuan dilanjutkan.',
      ],
      pelaksanaNama: 'Rahmat Hidayat, S.T.',
      pelaksanaJabatan: 'Petugas Pengawas Perwaskim',
      ditemuiNama: 'H. Asep Hendrayana, S.T.',
      ditemuiJabatan: 'Penanggung Jawab Pengembang',
      isDraft: true,
    ),
    MonitoringModel(
      id: '2',
      nomorSuratBA: 'BA/PERWASKIM/2025/05/0145',
      tanggalMonitoring: DateTime(2025, 5, 11),
      namaPerumahan: 'Bungursari Harmoni Indah',
      namaDeveloper: 'PT Galunggung Asri Propertindo',
      lokasiPerumahan: 'Kec. Bungursari, Kota Tasikmalaya',
      statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
      temuanLapangan: [
        'Jaringan jalan paving block telah terpasang 100%.',
        'PJU dan saluran drainase tertutup berfungsi baik.',
      ],
      kesimpulan: [
        'Seluruh prasarana sarana dan utilitas sesuai spesifikasi teknis.',
      ],
      kesepakatan: [
        'Proses penyerahan PSU siap dilanjutkan ke penandatanganan Berita Acara Final.',
      ],
      rencanaTindakLanjut: [
        'Penerbitan SK Persetujuan Penyerahan PSU oleh Kepala Dinas.',
      ],
      pelaksanaNama: 'Rahmat Hidayat, S.T.',
      pelaksanaJabatan: 'Petugas Pengawas Perwaskim',
      ditemuiNama: 'Yudi Permana, S.T.',
      ditemuiJabatan: 'Direktur Pengembang',
      isDraft: false,
    ),
  ];

  /// Memuat draf dan laporan tersimpan, lalu memulihkan isi fotonya ke
  /// [PhotoBytesCache]. Foto yang isinya tidak lagi tersimpan ditandai
  /// `needsReselect` agar petugas memotret ulang sebelum mengirim laporan.
  Future<void> hydrate() async {
    final store = _store;
    if (store == null) return;
    final storedIds = await store.storedPhotoIds();
    for (final json in await store.loadReports()) {
      final model = MonitoringModel.fromJson(json);
      if (model == null) continue;
      final photos = <ReportPhoto>[];
      for (final photo in model.photos) {
        final bytes = storedIds.contains(photo.id)
            ? await store.loadPhoto(photo.id)
            : null;
        if (bytes != null) {
          PhotoBytesCache.put(photo.id, bytes);
          photos.add(photo.copyWith(needsReselect: false));
        } else {
          photos.add(photo.copyWith(needsReselect: true));
        }
      }
      final restored = model.copyWith(photos: photos);
      final index = _items.indexWhere((e) => e.id == restored.id);
      if (index == -1) {
        _items.insert(0, restored);
      } else {
        _items[index] = restored;
      }
    }
  }

  /// Menunggu penyimpanan yang sedang berjalan selesai (untuk tes).
  Future<void> flush() => _persistQueue;

  void _schedulePersist() {
    final store = _store;
    if (store == null) return;
    _persistQueue = _persistQueue
        .then((_) => _persistNow(store))
        .catchError((Object _) {});
  }

  Future<void> _persistNow(MonitoringStore store) async {
    // Hanya laporan yang berbeda dari data contoh bawaan yang disimpan.
    final changed = [
      for (final item in _items)
        if (_seedJson[item.id] != jsonEncode(item.toJson())) item,
    ];
    final stored = await store.storedPhotoIds();
    final needed = <String>{};
    final reports = <Map<String, dynamic>>[];
    for (final item in changed) {
      final photos = <ReportPhoto>[];
      for (final photo in item.photos) {
        needed.add(photo.id);
        final bytes = PhotoBytesCache.get(photo.id);
        var keep = !photo.needsReselect;
        if (bytes == null) {
          keep = false;
        } else if (!stored.contains(photo.id)) {
          keep = await store.savePhoto(photo.id, bytes);
        }
        photos.add(
          photo.needsReselect == !keep
              ? photo
              : photo.copyWith(needsReselect: !keep),
        );
      }
      reports.add(item.copyWith(photos: photos).toJson());
    }
    await store.saveReports(reports);
    for (final id in stored.difference(needed)) {
      await store.deletePhoto(id);
    }
  }

  /// Nomor BA berikutnya untuk bulan pada [tanggal].
  ///
  /// Urutan dihitung dari nomor yang sudah dipakai pada bulan dan tahun yang
  /// sama. Nomor lama tanpa urutan dianggap urutan 1, jadi laporan lama tidak
  /// perlu diubah. [exceptId] mengabaikan satu laporan (mis. laporan itu
  /// sendiri saat nomornya dihitung ulang).
  String nextNomorSuratBA(DateTime tanggal, {String? exceptId}) {
    final base = MonitoringModel.generateNomorSuratBA(tanggal);
    var highest = 0;
    for (final item in _items) {
      if (item.id == exceptId) continue;
      final nomor = item.nomorSuratBA;
      if (nomor == base) {
        if (highest < 1) highest = 1;
      } else if (nomor.startsWith('$base/')) {
        final urutan = int.tryParse(nomor.substring(base.length + 1));
        if (urutan != null && urutan > highest) highest = urutan;
      }
    }
    return MonitoringModel.generateNomorSuratBA(tanggal, urutan: highest + 1);
  }

  /// Apakah [nomor] sudah dipakai laporan lain selain [exceptId].
  bool isNomorSuratBATaken(String nomor, {String? exceptId}) =>
      _items.any((item) => item.id != exceptId && item.nomorSuratBA == nomor);

  List<MonitoringModel> getAllMonitoring() {
    return List.unmodifiable(
      _items..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  MonitoringModel? getMonitoringById(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void addMonitoring(MonitoringModel item) {
    final existingIndex = _items.indexWhere(
      (existing) => existing.id == item.id,
    );
    if (existingIndex != -1) {
      // A report ID is the local idempotency key. A retry may upgrade a draft,
      // but must never append a second record for the same submission.
      if (_items[existingIndex].isDraft && !item.isDraft) {
        _items[existingIndex] = item;
        _schedulePersist();
      }
      return;
    }
    _items.insert(0, item);
    _schedulePersist();
  }

  /// Menyimpan draf: menimpa draf dengan ID yang sama, atau menambahkannya di
  /// paling atas. Laporan final tidak pernah ditimpa oleh draf.
  void saveDraft(MonitoringModel item) {
    if (!item.isDraft) return;
    final existingIndex = _items.indexWhere(
      (existing) => existing.id == item.id,
    );
    if (existingIndex == -1) {
      _items.insert(0, item);
    } else if (_items[existingIndex].isDraft) {
      _items[existingIndex] = item;
    } else {
      return;
    }
    _schedulePersist();
  }

  List<MonitoringModel> searchMonitoring({
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _items.where((item) {
      bool matchesQuery = true;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        matchesQuery =
            item.namaPerumahan.toLowerCase().contains(q) ||
            item.namaDeveloper.toLowerCase().contains(q) ||
            item.lokasiPerumahan.toLowerCase().contains(q);
      }

      bool matchesFromDate = true;
      if (fromDate != null) {
        matchesFromDate = item.tanggalMonitoring.isAfter(
          fromDate.subtract(const Duration(days: 1)),
        );
      }

      bool matchesToDate = true;
      if (toDate != null) {
        matchesToDate = item.tanggalMonitoring.isBefore(
          toDate.add(const Duration(days: 1)),
        );
      }

      return matchesQuery && matchesFromDate && matchesToDate;
    }).toList();
  }
}
