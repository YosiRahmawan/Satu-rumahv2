import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../models/monitoring_model.dart';
import '../models/report_photo.dart';
import '../photo_bytes_cache.dart';

/// Tugas survei untuk petugas yang masuk (dari server).
class OfficerAssignment {
  final int id;
  final String status;
  final DateTime? scheduledDate;
  final String? note;
  final String? submissionNumber;
  final String namaPerumahan;
  final String? namaPt;
  final String? alamatProyek;

  const OfficerAssignment({
    required this.id,
    required this.status,
    this.scheduledDate,
    this.note,
    this.submissionNumber,
    required this.namaPerumahan,
    this.namaPt,
    this.alamatProyek,
  });

  factory OfficerAssignment.fromJson(Map<String, dynamic> json) {
    final s = (json['submission'] as Map?)?.cast<String, dynamic>() ?? const {};
    return OfficerAssignment(
      id: json['id'] as int,
      status: '${json['status']}',
      scheduledDate: DateTime.tryParse('${json['scheduled_date'] ?? ''}'),
      note: json['note'] as String?,
      submissionNumber: s['number'] as String?,
      namaPerumahan: '${s['nama_perumahan'] ?? '-'}',
      namaPt: s['nama_pt'] as String?,
      alamatProyek: s['alamat_proyek'] as String?,
    );
  }

  /// Bentuk yang dipahami layar Beranda, kamera, dan form (`Pengajuan`).
  /// `id` memakai nomor pengajuan karena itulah yang disimpan di laporan.
  Pengajuan asPengajuan() => Pengajuan(
    id: submissionNumber ?? 'TUGAS-$id',
    namaPerumahan: namaPerumahan,
    namaPt: namaPt ?? '-',
    namaDirektur: '-',
    npwpPerusahaan: '-',
    luasLahan: 0,
    jumlahUnit: 0,
    tipePerumahan: 'Subsidi',
    alamatProyek: alamatProyek,
    status: 'Survey Dijadwalkan',
    statusTahap: StatusTahapPengajuan.surveyLapangan,
    tanggal: '-',
    uploadedDocs: const {},
    tanggalSurvey: scheduledDate,
    catatanSurvey: note,
  );
}

/// Sisi server untuk Pengawas, dipisahkan agar layar dan tes tidak bergantung pada HTTP.
abstract class OfficerRemote {
  Future<List<OfficerAssignment>> assignments();

  /// Membuat (atau melanjutkan) draf di server, mengunggah foto, lalu
  /// mengirim laporan. Mengembalikan nomor BA yang diterbitkan server.
  /// [draftKey] harus sama pada percobaan ulang agar tidak terbentuk draf ganda.
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  });
}

class OfficerApiRepository implements OfficerRemote {
  final Dio _dio;
  final Uint8List? Function(String photoId) _photoBytes;

  OfficerApiRepository(this._dio, {Uint8List? Function(String)? photoBytes})
    : _photoBytes = photoBytes ?? PhotoBytesCache.get;

  @override
  Future<List<OfficerAssignment>> assignments() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'officer/assignments',
      );
      return [
        for (final item in (response.data!['data'] as List))
          OfficerAssignment.fromJson((item as Map).cast<String, dynamic>()),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  }) async {
    void progress(String message, double fraction) =>
        onProgress?.call(message, fraction);
    try {
      progress('Menyiapkan laporan…', 0.05);
      final created =
          (await _dio.post<Map<String, dynamic>>(
                'officer/reports',
                data:
                    draft.pengajuanId != null &&
                        draft.pengajuanId!.trim().isNotEmpty
                    ? {'submission_number': draft.pengajuanId}
                    : {'nama_perumahan': draft.namaPerumahan},
                options: Options(headers: {'Idempotency-Key': draftKey}),
              )).data!['data']
              as Map<String, dynamic>;
      final id = created['id'] as int;

      progress('Menyimpan isi laporan…', 0.15);
      await _dio.put<Map<String, dynamic>>(
        'officer/reports/$id',
        data: _fields(draft, created['version'] as int),
      );

      await _uploadPhotos(id, draft, created, progress);

      progress('Mengirim laporan…', 0.95);
      final sent =
          (await _dio.post<Map<String, dynamic>>(
                'officer/reports/$id/submit',
                data: {'latitude': latitude, 'longitude': longitude},
              )).data!['data']
              as Map<String, dynamic>;
      progress('Selesai', 1);
      return '${sent['report_number']}';
    } on DioException catch (e) {
      throw _describe(ApiException.fromDio(e));
    }
  }

  Future<void> _uploadPhotos(
    int reportId,
    MonitoringModel draft,
    Map<String, dynamic> created,
    void Function(String, double) progress,
  ) async {
    // Foto yang sudah ada di server (percobaan ulang) tidak diunggah lagi.
    final onServer = {
      for (final p in (created['photos'] as List).cast<Map<String, dynamic>>())
        p['checksum'] as String,
    };
    var done = 0;
    for (final photo in draft.photos) {
      final bytes = _photoBytes(photo.id);
      done++;
      if (bytes == null) {
        throw ApiException(
          code: 'FILE',
          message:
              'Foto $done tidak dapat dibaca. Hapus lalu potret ulang foto tersebut.',
        );
      }
      progress(
        'Mengunggah foto $done dari ${draft.photos.length}…',
        0.2 + 0.7 * done / draft.photos.length,
      );
      if (onServer.contains(sha256.convert(bytes).toString())) continue;
      await _dio.post<Map<String, dynamic>>(
        'officer/reports/$reportId/photos',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: 'foto-$done.jpg'),
          'source': photo.source == PhotoSource.gallery ? 'gallery' : 'camera',
        }),
      );
    }
  }

  static Map<String, dynamic> _fields(MonitoringModel d, int version) {
    List<String> clean(List<String> items) => [
      for (final i in items)
        if (i.trim().isNotEmpty) i.trim(),
    ];
    List<Map<String, String>> people(List<MonitoringPerson> list) => [
      for (final p in list)
        if (p.nama.trim().isNotEmpty)
          {'nama': p.nama.trim(), 'jabatan': p.jabatan.trim()},
    ];
    final tanggal = d.tanggalMonitoring;
    String two(int v) => v.toString().padLeft(2, '0');

    return {
      'version': version,
      'monitoring_date':
          '${tanggal.year}-${two(tanggal.month)}-${two(tanggal.day)}',
      'nama_perumahan': d.namaPerumahan.trim(),
      'lokasi': d.lokasiPerumahan.trim(),
      'maksud_tujuan': d.maksudTujuan.trim(),
      'temuan': clean(d.temuanLapangan),
      'kesimpulan': clean(d.kesimpulan),
      'kesepakatan': clean(d.kesepakatan),
      'rtl': clean(d.rencanaTindakLanjut),
      'status_hasil_evaluasi': d.statusHasilEvaluasi.name,
      'tim_pelaksana': people(
        d.pelaksana.isNotEmpty
            ? d.pelaksana
            : [
                MonitoringPerson(
                  nama: d.pelaksanaNama,
                  jabatan: d.pelaksanaJabatan,
                ),
              ],
      ),
      'pihak_ditemui': people(
        d.ditemui.isNotEmpty
            ? d.ditemui
            : [
                MonitoringPerson(
                  nama: d.ditemuiNama,
                  jabatan: d.ditemuiJabatan,
                ),
              ],
      ),
    };
  }

  ApiException _describe(ApiException e) {
    if (e.status == 404 && e.code == 'ERR-013') {
      return ApiException(
        code: e.code,
        status: e.status,
        message:
            'Tugas survei untuk laporan ini tidak ditemukan atau sudah selesai. Muat ulang daftar tugas.',
      );
    }
    if (e.code == 'ERR-010' && e.fields.isNotEmpty) {
      return ApiException(
        code: e.code,
        status: e.status,
        message: e.fields.values.expand((v) => v).first,
        fields: e.fields,
      );
    }
    return e;
  }
}

final officerRemoteProvider = Provider<OfficerRemote>(
  (ref) => OfficerApiRepository(ref.watch(apiDioProvider)),
);
