import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../presentation/providers/pengajuan_form_controller.dart';
import '../models/hasil_survey_model.dart';
import '../models/pengajuan_model.dart';
import '../models/status_tahap_pengajuan.dart';
import '../slot_catalog.dart';

/// Pengajuan di server. Dipisahkan agar layar dan tes tidak bergantung pada HTTP.
abstract class PengajuanRemote {
  /// Pengajuan milik akun yang masuk (draf yang belum dikirim tidak ikut).
  Future<List<Pengajuan>> list();

  /// Membuat (atau melanjutkan) draf di server, mengunggah berkas, lalu
  /// mengirimnya. [draftKey] harus sama pada percobaan ulang agar tidak
  /// terbentuk draf ganda.
  Future<Pengajuan> submit(
    PengajuanFormState form, {
    required String draftKey,
    void Function(String message, double fraction)? onProgress,
  });

  /// Mengganti berkas yang diminta diperbaiki (kunci Flutter → rujukan berkas
  /// baru) lalu mengirim ulang pengajuan bernomor [number].
  Future<Pengajuan> resubmit(String number, Map<String, String> revisedDocs);
}

/// UUID v4 untuk header Idempotency-Key.
String newDraftKey([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// Pembaca isi berkas lokal; null bila tidak terbaca.
typedef BytesReader = Future<Uint8List?> Function(String reference);

class PengajuanApiRepository implements PengajuanRemote {
  final Dio _dio;
  final BytesReader _readBytes;

  /// Nomor pengajuan → id server (diisi saat daftar dimuat atau dikirim).
  final Map<String, int> _idByNumber = {};

  PengajuanApiRepository(this._dio, {BytesReader? readBytes})
    : _readBytes = readBytes ?? FilePickerUtil.readBytesOrNull;

  @override
  Future<List<Pengajuan>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'submissions',
        queryParameters: {'detail': 1, 'per_page': 50},
      );
      final data = (response.data!['data'] as List)
          .cast<Map<String, dynamic>>();
      _remember(data);
      return [
        for (final item in data)
          if (item['status_tahap'] != 'draft') pengajuanFromApi(item),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Pengajuan> submit(
    PengajuanFormState form, {
    required String draftKey,
    void Function(String message, double fraction)? onProgress,
  }) async {
    void progress(String message, double fraction) =>
        onProgress?.call(message, fraction);
    try {
      progress('Memeriksa profil perusahaan…', 0.05);
      final profile = (await _dio.get<Map<String, dynamic>>(
        'developer/profile',
      )).data!['data'];
      if (profile == null) {
        throw const ApiException(
          code: 'ERR-010',
          message:
              'Profil perusahaan belum diisi. Hubungi Administrator untuk melengkapinya.',
        );
      }

      progress('Membuat pengajuan…', 0.1);
      final created =
          (await _dio.post<Map<String, dynamic>>(
                'submissions',
                options: Options(headers: {'Idempotency-Key': draftKey}),
              )).data!['data']
              as Map<String, dynamic>;
      final id = created['id'] as int;

      progress('Menyimpan data pengajuan…', 0.15);
      await _dio.patch<Map<String, dynamic>>(
        'submissions/$id',
        data: {
          'version': created['version'],
          'nama_perumahan': form.namaPerumahan.trim(),
          'alamat_proyek': form.alamatProyek.trim(),
          'tipe_pengajuan': form.tipePengajuan,
          'daya_listrik': form.dayaListrik.isEmpty ? null : form.dayaListrik,
          'npwp': form.npwpPerusahaan.trim(),
          'luas_lahan': form.luasLahan,
          'jumlah_unit': form.jumlahUnit,
          'tipe_perumahan': SlotCatalog.tipePerumahanToApi(form.tipePerumahan),
          'current_step': 5,
        },
      );

      await _uploadFiles(id, form, created, progress);

      progress('Mengirim pengajuan…', 0.95);
      final sent =
          (await _dio.post<Map<String, dynamic>>(
                'submissions/$id/submit',
              )).data!['data']
              as Map<String, dynamic>;
      progress('Selesai', 1);
      _remember([sent]);
      return pengajuanFromApi(sent);
    } on DioException catch (e) {
      throw _describe(ApiException.fromDio(e));
    }
  }

  void _remember(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final number = item['number'];
      if (number is String) _idByNumber[number] = item['id'] as int;
    }
  }

  @override
  Future<Pengajuan> resubmit(
    String number,
    Map<String, String> revisedDocs,
  ) async {
    try {
      if (!_idByNumber.containsKey(number)) await list();
      final id = _idByNumber[number];
      if (id == null) {
        throw const ApiException(
          code: 'ERR-013',
          message: 'Pengajuan tidak ditemukan di server.',
        );
      }

      final detail =
          (await _dio.get<Map<String, dynamic>>(
                'submissions/$id',
              )).data!['data']
              as Map<String, dynamic>;
      final flagged = (detail['files'] as List)
          .cast<Map<String, dynamic>>()
          .where((f) => f['status'] == 'perlu_perbaikan')
          .toList();

      for (final entry in revisedDocs.entries) {
        final code = SlotCatalog.codeByKey[entry.key];
        final target = flagged.where((f) => f['slot_code'] == code).firstOrNull;
        if (code == null || target == null) continue; // bukan yang diminta
        final name = _basename(entry.value);
        final bytes = await _readBytes(entry.value);
        if (bytes == null) {
          throw ApiException(
            code: 'FILE',
            message:
                'Berkas "$name" tidak dapat dibaca. Pilih ulang berkas pengganti lalu kirim kembali.',
          );
        }
        await _dio.post<Map<String, dynamic>>(
          'submissions/$id/files',
          data: FormData.fromMap({
            'slot_code': code,
            'replaces_file_id': target['id'],
            'file': MultipartFile.fromBytes(bytes, filename: name),
          }),
        );
      }

      final sent =
          (await _dio.post<Map<String, dynamic>>(
                'submissions/$id/resubmit',
              )).data!['data']
              as Map<String, dynamic>;
      return pengajuanFromApi(sent);
    } on DioException catch (e) {
      final err = ApiException.fromDio(e);
      final slots = err.fields['slots'];
      if (slots != null && slots.isNotEmpty) {
        throw ApiException(
          code: err.code,
          status: err.status,
          message:
              'Masih ada berkas yang belum diganti: ${slots.map(SlotCatalog.labelOfCode).join(', ')}.',
          fields: err.fields,
        );
      }
      throw err;
    }
  }

  Future<void> _uploadFiles(
    int id,
    PengajuanFormState form,
    Map<String, dynamic> created,
    void Function(String, double) progress,
  ) async {
    final wanted = SlotCatalog.filesBySlot(form);
    // Berkas yang sudah ada di server (percobaan ulang) tidak diunggah lagi.
    final existing = <String, Set<int>>{};
    for (final f in (created['files'] as List).cast<Map<String, dynamic>>()) {
      (existing[f['slot_code'] as String] ??= {}).add(f['size_bytes'] as int);
    }

    final total = wanted.values.fold<int>(0, (n, l) => n + l.length);
    var done = 0;
    for (final entry in wanted.entries) {
      for (final reference in entry.value) {
        final name = _basename(reference);
        final bytes = await _readBytes(reference);
        if (bytes == null) {
          throw ApiException(
            code: 'FILE',
            message:
                'Berkas "$name" tidak dapat dibaca. Pilih ulang berkas tersebut lalu kirim kembali.',
          );
        }
        done++;
        progress('Mengunggah $name ($done/$total)…', 0.2 + 0.7 * done / total);
        if (existing[entry.key]?.contains(bytes.length) == true) continue;
        await _dio.post<Map<String, dynamic>>(
          'submissions/$id/files',
          data: FormData.fromMap({
            'slot_code': entry.key,
            'file': MultipartFile.fromBytes(bytes, filename: name),
          }),
        );
      }
    }
  }

  /// Pesan galat yang bisa dipahami pengguna (mis. daftar berkas yang kurang).
  ApiException _describe(ApiException e) {
    final slots = e.fields['slots'];
    if (slots != null && slots.isNotEmpty) {
      final names = slots.map(SlotCatalog.labelOfCode).join(', ');
      return ApiException(
        code: e.code,
        status: e.status,
        message: 'Berkas wajib belum lengkap: $names.',
        fields: e.fields,
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

  static String _basename(String reference) {
    final parts = reference.split(RegExp(r'[\\/]'));
    return parts.isEmpty || parts.last.isEmpty ? reference : parts.last;
  }
}

final pengajuanRemoteProvider = Provider<PengajuanRemote>(
  (ref) => PengajuanApiRepository(ref.watch(apiDioProvider)),
);

// ---------------------------------------------------------------------------
// JSON server → model Flutter
// ---------------------------------------------------------------------------

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _tanggal(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  return d == null ? '-' : '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

StatusTahapPengajuan? _tahap(String? name) {
  // Pengajuan yang baru dikirim tampil sebagai Verifikasi Administrasi, sama
  // dengan alur lokal sebelumnya (enum pengajuanBaru dilewati).
  if (name == 'pengajuanBaru') {
    return StatusTahapPengajuan.verifikasiAdministrasi;
  }
  for (final v in StatusTahapPengajuan.values) {
    if (v.name == name) return v;
  }
  return null;
}

List<String> _strings(Object? v) =>
    ((v as List?) ?? const []).map((e) => '$e').toList();

/// Hasil evaluasi server → kosakata layar Pengembang.
String _evaluasi(String? v) => switch (v) {
  'tidakSesuaiSiteplan' => 'tidak_sesuai',
  'perluEvaluasiLanjutan' => 'perlu_perbaikan',
  _ => 'sesuai',
};

HasilSurveyItem _hasilSurvey(Map<String, dynamic> r) {
  final tim = ((r['tim_pelaksana'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
  return HasilSurveyItem(
    id: '${r['id']}',
    tanggalSurvey:
        DateTime.tryParse('${r['monitoring_date'] ?? ''}') ?? DateTime.now(),
    pelaksanaNama: tim.isEmpty ? '-' : '${tim.first['nama']}',
    pelaksanaJabatan: tim.isEmpty ? '-' : '${tim.first['jabatan'] ?? ''}',
    lokasiPerumahan: '${r['lokasi'] ?? ''}',
    statusHasilEvaluasi: _evaluasi(r['status_hasil_evaluasi'] as String?),
    temuanLapangan: _strings(r['temuan']),
    kesimpulan: _strings(r['kesimpulan']),
    kesepakatan: _strings(r['kesepakatan']),
    rencanaTindakLanjut: _strings(r['rtl']),
    nomorSuratBA: r['report_number'] as String?,
  );
}

/// Pengajuan dari JSON `detail` server. `id` memakai nomor pengajuan.
Pengajuan pengajuanFromApi(Map<String, dynamic> json) {
  final files = ((json['files'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
  final profile =
      (json['developer_profile'] as Map?)?.cast<String, dynamic>() ?? const {};

  final uploaded = <String, String>{};
  final verified = <String, bool>{};
  final revisi = <String>[];
  final catatan = <String>[];
  final technical = <String>[];
  for (final f in files) {
    final code = '${f['slot_code']}';
    final key = SlotCatalog.keyByCode[code];
    final name = '${f['original_name']}';
    if (code == 'S4-01' || code == 'S4-02') technical.add(name);
    if (key == null) continue;
    uploaded.putIfAbsent(key, () => name);
    final status = f['status'];
    if (status == 'lolos' || status == 'sesuai') verified[key] = true;
    if (status == 'perlu_perbaikan') {
      verified[key] = false;
      revisi.add(key);
      final note = f['review_note'];
      if (note is String && note.trim().isNotEmpty) catatan.add(note.trim());
    }
  }

  final survey = (json['survey'] as Map?)?.cast<String, dynamic>();
  final surveyTeam = ((survey?['team'] as List?) ?? const [])
      .cast<Map<String, dynamic>>();
  final riwayatSurvey = [
    for (final r
        in ((json['survey_reports'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
      _hasilSurvey(r),
  ];

  final tahap =
      _tahap(json['status_tahap'] as String?) ??
      StatusTahapPengajuan.verifikasiAdministrasi;
  final tahapNow = tahap;
  final decision = json['decision'] as Map?;
  final number = json['number'] as String?;

  return Pengajuan(
    id: number ?? 'DRAF-${json['id']}',
    tipePengajuan: json['tipe_pengajuan'] as String?,
    namaPerumahan: '${json['nama_perumahan'] ?? '-'}',
    alamatProyek: json['alamat_proyek'] as String?,
    namaPt: '${json['nama_pt'] ?? profile['nama_pt'] ?? '-'}',
    namaDirektur: '${profile['nama_direktur'] ?? '-'}',
    nib: profile['nib'] as String?,
    npwpPerusahaan: '${json['npwp'] ?? '-'}',
    luasLahan: (json['luas_lahan'] as num?)?.toDouble() ?? 0,
    jumlahUnit: (json['jumlah_unit'] as num?)?.toInt() ?? 0,
    tipePerumahan: SlotCatalog.tipePerumahanFromApi(
      json['tipe_perumahan'] as String?,
    ),
    status: tahapNow == StatusTahapPengajuan.selesai
        ? 'Selesai'
        : tahapNow == StatusTahapPengajuan.perluPerbaikan
        ? 'Perlu Perbaikan'
        : 'Dalam Proses',
    statusTahap: tahapNow,
    tanggal: _tanggal(json['submitted_at'] as String?),
    diperbarui: 'Diperbarui ${_tanggal(json['updated_at'] as String?)}',
    catatanPerbaikan: catatan.isEmpty ? null : catatan.join(' '),
    uploadedDocs: uploaded,
    verifiedDocs: verified,
    dokumenPerluRevisi: revisi,
    technicalFiles: technical,
    tahapAsalPerbaikan: _tahap(json['tahap_asal_perbaikan'] as String?),
    revisionSubmitted: json['sub_status'] == 'perbaikan_terkirim',
    tanggalSurvey: DateTime.tryParse('${survey?['scheduled_date'] ?? ''}'),
    // Catatan Admin untuk survei; bila kosong, daftar tim yang ditugaskan.
    catatanSurvey: (survey?['note'] as String?)?.trim().isNotEmpty == true
        ? survey!['note'] as String
        : (surveyTeam.isEmpty
              ? null
              : 'Tim: ${surveyTeam.map((m) => m['nama']).join(', ')}'),
    riwayatSurvey: riwayatSurvey,
    nomorSk: decision?['number'] as String?,
    tanggalSk: decision == null ? null : _tanggal(decision['date'] as String?),
  );
}
