import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/data/slot_catalog.dart';
import '../models/ba_signature.dart';
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
  final String? namaDirektur;
  final String? noHpDirektur;
  final String? npwp;
  final double luasLahan;
  final int jumlahUnit;
  final String? tipePerumahan;

  /// Tim pelaksana yang ditetapkan Admin (petugas utama lebih dulu).
  final List<MonitoringPerson> team;

  const OfficerAssignment({
    required this.id,
    required this.status,
    this.scheduledDate,
    this.note,
    this.submissionNumber,
    required this.namaPerumahan,
    this.namaPt,
    this.alamatProyek,
    this.namaDirektur,
    this.noHpDirektur,
    this.npwp,
    this.luasLahan = 0,
    this.jumlahUnit = 0,
    this.tipePerumahan,
    this.team = const [],
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
      namaDirektur: s['nama_direktur'] as String?,
      noHpDirektur: s['no_hp_direktur'] as String?,
      npwp: s['npwp'] as String?,
      luasLahan: (s['luas_lahan'] as num?)?.toDouble() ?? 0,
      jumlahUnit: (s['jumlah_unit'] as num?)?.toInt() ?? 0,
      tipePerumahan: s['tipe_perumahan'] as String?,
      team: [
        for (final m in ((json['team'] as List?) ?? const []))
          MonitoringPerson.create(
            nama: '${(m as Map)['nama'] ?? ''}',
            jabatan: '${m['jabatan'] ?? ''}',
          ),
      ],
    );
  }

  /// Bentuk yang dipahami layar Beranda, kamera, dan form (`Pengajuan`).
  /// `id` memakai nomor pengajuan karena itulah yang disimpan di laporan.
  Pengajuan asPengajuan() => Pengajuan(
    id: submissionNumber ?? 'TUGAS-$id',
    namaPerumahan: namaPerumahan,
    namaPt: namaPt ?? '-',
    namaDirektur: namaDirektur ?? '-',
    npwpPerusahaan: npwp ?? '-',
    luasLahan: luasLahan,
    jumlahUnit: jumlahUnit,
    tipePerumahan: SlotCatalog.tipePerumahanFromApi(tipePerumahan),
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

  /// Status persetujuan Ketua dan Admin untuk BA bernomor [reportNumber].
  Future<BaSignatureStatus> signatureStatus(String reportNumber);

  /// Ketua Pengawas menyetujui BA dengan gambar tanda tangan dan konfirmasi sandi.
  /// [idempotencyKey] harus sama pada percobaan ulang agar tidak tersimpan ganda.
  Future<BaSignatureStatus> signReport({
    required String reportNumber,
    required SignatureImage image,
    required String password,
    required String idempotencyKey,
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

  /// Id dan versi laporan di server dari nomor BA (daftar laporan milik petugas).
  Future<({int id, int version})> _resolveReport(String number) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'officer/reports',
      queryParameters: {'per_page': 50},
    );
    for (final item in (response.data!['data'] as List).cast<Map<String, dynamic>>()) {
      if ('${item['report_number']}' == number) {
        return (id: item['id'] as int, version: item['version'] as int);
      }
    }
    throw const ApiException(
      code: 'NOT_FOUND',
      status: 404,
      message: 'Laporan tidak ditemukan di server. Muat ulang lalu coba lagi.',
    );
  }

  @override
  Future<BaSignatureStatus> signatureStatus(String reportNumber) async {
    try {
      final ref = await _resolveReport(reportNumber);
      final detail = await _dio.get<Map<String, dynamic>>('officer/reports/${ref.id}');
      return BaSignatureStatus.fromReport(detail.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<BaSignatureStatus> signReport({
    required String reportNumber,
    required SignatureImage image,
    required String password,
    required String idempotencyKey,
  }) async {
    try {
      final ref = await _resolveReport(reportNumber);
      final response = await _dio.post<Map<String, dynamic>>(
        'officer/reports/${ref.id}/sign',
        data: FormData.fromMap({
          'method': image.method,
          'password': password,
          'version': ref.version,
          'signature': MultipartFile.fromBytes(
            image.bytes,
            filename: image.filename,
            contentType: DioMediaType.parse(image.contentType),
          ),
        }),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return BaSignatureStatus.fromReport(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
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
      try {
        await _dio.post<Map<String, dynamic>>(
          'officer/reports/$reportId/photos',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: 'foto-$done.jpg'),
            'source': photo.source == PhotoSource.gallery
                ? 'gallery'
                : 'camera',
          }),
        );
      } on DioException catch (e) {
        throw ApiException.fromDio(e).withPrefix('Foto $done gagal diunggah.');
      }
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

/// Status persetujuan BA dari server; null di mode lokal (tanpa API).
final baSignatureStatusProvider = FutureProvider.autoDispose
    .family<BaSignatureStatus?, String>((ref, number) async {
      if (!ref.watch(apiEnabledProvider)) return null;
      return ref.watch(officerRemoteProvider).signatureStatus(number);
    });
