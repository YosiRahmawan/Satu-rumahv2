import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hasil_survey_model.dart';
import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';

/// One source of truth for the current Fase 3 document form.
class PengajuanStep3DocumentConfig {
  const PengajuanStep3DocumentConfig({
    required this.number,
    required this.key,
    required this.label,
    required this.actionLabel,
    this.description,
    this.isOptional = false,
    this.allowsMultiple = false,
    this.maxBytes = 10 * 1024 * 1024,
  });

  final String number;
  final String key;
  final String label;
  final String actionLabel;
  final String? description;
  final bool isOptional;
  final bool allowsMultiple;
  final int maxBytes;
}

/// Canonical document contract shared by Step 3 rendering/validation and Review.
class PengajuanStep3DocumentContract {
  static const slots = <PengajuanStep3DocumentConfig>[
    PengajuanStep3DocumentConfig(
      number: '1',
      key: 'surat_permohonan',
      label: 'Surat Permohonan Persetujuan Site Plan',
      actionLabel: 'Unggah Dokumen Permohonan',
    ),
    PengajuanStep3DocumentConfig(
      number: '2',
      key: 'info_intensitas_ruang',
      label: 'Informasi Intensitas Pemanfaatan Ruang (IPR / KRK)',
      actionLabel: 'Unggah Dokumen IPR / KRK',
    ),
    PengajuanStep3DocumentConfig(
      number: '3',
      key: 'bukti_kepemilikan_lahan',
      label: 'Bukti Kepemilikan Lahan / Sertifikat Induk a.n. PT',
      actionLabel: 'Unggah Bukti Kepemilikan Lahan',
    ),
    PengajuanStep3DocumentConfig(
      number: '4',
      key: 'bukti_tpu',
      label: 'Bukti Penyediaan Lahan TPU Perumahan',
      actionLabel: 'Unggah Dokumen TPU (PDF)',
    ),
    PengajuanStep3DocumentConfig(
      number: '5',
      key: 'rekomendasi_lingkungan',
      label: 'Rekomendasi Teknis dari Dinas Terkait',
      actionLabel: 'Tambah File Rekomendasi',
      description:
          'Meliputi dokumen AMDAL/UKL-UPL, rekomendasi drainase dan teknis tapak.',
      allowsMultiple: true,
    ),
    PengajuanStep3DocumentConfig(
      number: '6',
      key: 'andalalin',
      label: 'Persetujuan ANDALALIN / Dishub',
      actionLabel: 'Unggah Dokumen ANDALALIN',
      description:
          'Surat pertimbangan dampak lalu lintas ruas jalan perkotaan.',
    ),
    PengajuanStep3DocumentConfig(
      number: '7',
      key: 'rekomendasi_air_bersih',
      label: 'Rekomendasi Air Bersih (PDAM / Surat Izin)',
      actionLabel: 'Unggah Berkas PDAM',
      description:
          'Kapasitas sambungan atau izin pengelolaan air tanah mandiri.',
    ),
    PengajuanStep3DocumentConfig(
      number: '8',
      key: 'rekomendasi_listrik',
      label: 'Rekomendasi Listrik PLN',
      actionLabel: 'Unggah Surat Rekomendasi PLN',
      description: 'Surat ketersediaan daya dan jaringan gardu perumahan.',
    ),
    PengajuanStep3DocumentConfig(
      number: '9',
      key: 'pernyataan_psu',
      label: 'Surat Pernyataan Kesanggupan Penyerahan PSU',
      actionLabel: 'Unggah Akta Notaris PSU',
      description:
          'Akta notariil kesanggupan penyerahan prasarana dan utilitas umum.',
    ),
    PengajuanStep3DocumentConfig(
      number: '10',
      key: 'penanggung_jawab_teknis',
      label: 'Data Penanggung Jawab Dokumen Teknis',
      actionLabel: 'Unggah Data Tenaga Ahli',
      description: 'SKA/SKK Tenaga Ahli Arsitektur/Perencana Wilayah.',
      isOptional: true,
    ),
    PengajuanStep3DocumentConfig(
      number: '11',
      key: 'proposal_pembangunan',
      label: 'Proposal Rencana Pembangunan Ditandatangani Direktur',
      actionLabel: 'Unggah Proposal Direktur (PDF)',
      description:
          'Rencana tahapan pembangunan, spesifikasi tipe, dan jadwal kerja.',
    ),
  ];

  static List<String> get allKeys =>
      slots.map((slot) => slot.key).toList(growable: false);

  static List<String> get requiredKeys => slots
      .where((slot) => !slot.isOptional)
      .map((slot) => slot.key)
      .toList(growable: false);
}

class PengajuanFormState {
  final String tipePengajuan;
  final String namaPerumahan;
  final String alamatProyek;
  final String npwpPerusahaan;
  final double luasLahan;
  final int jumlahUnit;
  final String tipePerumahan;
  final Map<String, String> uploadedDocs;

  /// File references for slots that support more than one local attachment.
  /// The legacy [uploadedDocs] map remains the first-file reference used by
  /// existing phases and downstream review screens.
  final Map<String, List<String>> multiUploadedDocs;
  final List<String> technicalFiles;
  final Set<String> selectedCakupanGambar;
  final bool isAgreed;

  PengajuanFormState({
    this.tipePengajuan = 'Pengajuan Site Plan Baru',
    this.namaPerumahan = '',
    this.alamatProyek = '',
    this.npwpPerusahaan = '',
    this.luasLahan = 0.0,
    this.jumlahUnit = 0,
    this.tipePerumahan = 'Subsidi',
    this.uploadedDocs = const {},
    this.multiUploadedDocs = const {},
    this.technicalFiles = const [],
    this.selectedCakupanGambar = const {},
    this.isAgreed = false,
  });

  bool get isStep1Valid =>
      tipePengajuan.trim().isNotEmpty &&
      namaPerumahan.trim().isNotEmpty &&
      alamatProyek.trim().isNotEmpty &&
      npwpPerusahaan.trim().isNotEmpty &&
      luasLahan.isFinite &&
      luasLahan > 0 &&
      jumlahUnit > 0;

  bool get isStep2Valid =>
      _hasDocument('ktp') &&
      _hasDocument('nib') &&
      _hasDocument('npwp_doc') &&
      _hasDocument('asosiasi') &&
      _hasDocument('legalitas');

  bool get isStep3Valid =>
      PengajuanStep3DocumentContract.requiredKeys.every(_hasDocument);

  bool get isStep4Valid =>
      _hasDocument('site_plan_dwg') ||
      technicalFiles.any((file) => file.trim().isNotEmpty);

  bool get isAllValid =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid && isAgreed;

  bool _hasDocument(String key) => uploadedDocs[key]?.trim().isNotEmpty == true;

  PengajuanFormState copyWith({
    String? tipePengajuan,
    String? namaPerumahan,
    String? alamatProyek,
    String? npwpPerusahaan,
    double? luasLahan,
    int? jumlahUnit,
    String? tipePerumahan,
    Map<String, String>? uploadedDocs,
    Map<String, List<String>>? multiUploadedDocs,
    List<String>? technicalFiles,
    Set<String>? selectedCakupanGambar,
    bool? isAgreed,
  }) {
    return PengajuanFormState(
      tipePengajuan: tipePengajuan ?? this.tipePengajuan,
      namaPerumahan: namaPerumahan ?? this.namaPerumahan,
      alamatProyek: alamatProyek ?? this.alamatProyek,
      npwpPerusahaan: npwpPerusahaan ?? this.npwpPerusahaan,
      luasLahan: luasLahan ?? this.luasLahan,
      jumlahUnit: jumlahUnit ?? this.jumlahUnit,
      tipePerumahan: tipePerumahan ?? this.tipePerumahan,
      uploadedDocs: uploadedDocs ?? Map.from(this.uploadedDocs),
      multiUploadedDocs:
          multiUploadedDocs ??
          this.multiUploadedDocs.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
      technicalFiles: technicalFiles ?? List.from(this.technicalFiles),
      selectedCakupanGambar:
          selectedCakupanGambar ?? Set.from(this.selectedCakupanGambar),
      isAgreed: isAgreed ?? this.isAgreed,
    );
  }
}

class PengajuanFormNotifier extends StateNotifier<PengajuanFormState> {
  PengajuanFormNotifier() : super(PengajuanFormState());

  void updateTipePengajuan(String value) =>
      state = state.copyWith(tipePengajuan: value);
  void updateNamaPerumahan(String value) =>
      state = state.copyWith(namaPerumahan: value);
  void updateAlamatProyek(String value) =>
      state = state.copyWith(alamatProyek: value);
  void updateNpwp(String value) =>
      state = state.copyWith(npwpPerusahaan: value);
  void updateLuasLahan(double value) =>
      state = state.copyWith(luasLahan: value);
  void updateJumlahUnit(int value) => state = state.copyWith(jumlahUnit: value);
  void updateTipe(String value) => state = state.copyWith(tipePerumahan: value);
  void toggleAgreement(bool value) => state = state.copyWith(isAgreed: value);

  void uploadDocument(String key, String fileName) {
    if (key.trim().isEmpty || fileName.trim().isEmpty) return;
    final updated = Map<String, String>.from(state.uploadedDocs);
    updated[key] = fileName;
    final multi = Map<String, List<String>>.from(state.multiUploadedDocs);
    multi[key] = [fileName];
    state = state.copyWith(uploadedDocs: updated, multiUploadedDocs: multi);
  }

  void uploadDocuments(String key, List<String> fileNames) {
    if (key.trim().isEmpty) return;
    final clean = fileNames.where((file) => file.trim().isNotEmpty).toList();
    if (clean.isEmpty) return;
    final multi = Map<String, List<String>>.from(state.multiUploadedDocs);
    final existing = List<String>.from(multi[key] ?? const <String>[]);
    for (final file in clean) {
      if (!existing.contains(file)) existing.add(file);
    }
    final updated = Map<String, String>.from(state.uploadedDocs);
    updated[key] = existing.first;
    multi[key] = existing;
    state = state.copyWith(uploadedDocs: updated, multiUploadedDocs: multi);
  }

  void deleteDocument(String key) {
    final updated = Map<String, String>.from(state.uploadedDocs);
    updated.remove(key);
    final multi = Map<String, List<String>>.from(state.multiUploadedDocs);
    multi.remove(key);
    state = state.copyWith(uploadedDocs: updated, multiUploadedDocs: multi);
  }

  void addTechnicalFiles(List<String> filePaths) {
    final current = List<String>.from(state.technicalFiles);
    for (var path in filePaths) {
      if (path.trim().isEmpty) continue;
      if (!current.contains(path)) {
        current.add(path);
      }
    }
    final updatedDocs = Map<String, String>.from(state.uploadedDocs);
    if (current.isNotEmpty && !updatedDocs.containsKey('site_plan_dwg')) {
      updatedDocs['site_plan_dwg'] = current.first;
    }
    state = state.copyWith(technicalFiles: current, uploadedDocs: updatedDocs);
  }

  void removeTechnicalFile(int index) {
    final current = List<String>.from(state.technicalFiles);
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
    }
    final updatedDocs = Map<String, String>.from(state.uploadedDocs);
    if (current.isEmpty) {
      updatedDocs.remove('site_plan_dwg');
    } else {
      updatedDocs['site_plan_dwg'] = current.first;
    }
    state = state.copyWith(technicalFiles: current, uploadedDocs: updatedDocs);
  }

  void toggleCakupanGambar(String item) {
    final current = Set<String>.from(state.selectedCakupanGambar);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    state = state.copyWith(selectedCakupanGambar: current);
  }

  void selectAllCakupanGambar(List<String> allItems) {
    state = state.copyWith(selectedCakupanGambar: Set.from(allItems));
  }

  void clearCakupanGambar() {
    state = state.copyWith(selectedCakupanGambar: {});
  }

  void reset() {
    state = PengajuanFormState();
  }

  void fillDummyData() {
    state = PengajuanFormState(
      tipePengajuan: 'Pengajuan Site Plan Baru',
      namaPerumahan: 'Green Tasik Residence',
      alamatProyek: 'Jl. Tamansari KM 4, Kota Tasikmalaya',
      npwpPerusahaan: '12.345.678.9-423.000',
      luasLahan: 15000,
      jumlahUnit: 85,
      tipePerumahan: 'Subsidi',
      uploadedDocs: {
        'ktp': 'ktp_direktur_tatang.pdf',
        'nib': 'nib_perusahaan_pembangunan.pdf',
        'npwp_doc': 'npwp_perusahaan_official.pdf',
        'asosiasi': 'bukti_anggota_rei.pdf',
        'legalitas': 'akta_pendirian_pt_tasik.pdf',
        'surat_permohonan': 'surat_permohonan_persetujuan.pdf',
        'info_intensitas_ruang': 'info_intensitas_ruang.pdf',
        'bukti_kepemilikan_lahan': 'bukti_kepemilikan_lahan.pdf',
        'bukti_tpu': 'bukti_penyediaan_lahan_tpu.pdf',
        'kkpr_doc': 'kesesuaian_tata_ruang_2026.pdf',
        'pbg_induk': 'persetujuan_imb_induk.pdf',
        'rekomendasi_lingkungan': 'rekomendasi_amdal_sppl.pdf',
        'andalalin': 'andalalin_dishub.pdf',
        'rekomendasi_air_bersih': 'rekomendasi_pdam.pdf',
        'rekomendasi_listrik': 'rekomendasi_pln.pdf',
        'pelepasan_lahan': 'rekomendasi_pelepasan_lahan.pdf',
        'pernyataan_pelepasan': 'pernyataan_pelepasan_hak.pdf',
        'pernyataan_keabsahan': 'pernyataan_keabsahan_dokumen.pdf',
        'pernyataan_psu': 'pernyataan_kesanggupan_psu.pdf',
        'proposal_pembangunan': 'proposal_pembangunan_direktur.pdf',
        'site_plan_dwg': 'design_siteplan_layout.dwg',
      },
      technicalFiles: [
        'design_siteplan_layout.dwg',
        'berkas_gambar_teknis_lengkap.pdf',
      ],
      selectedCakupanGambar: {
        '1 Cover',
        '2 Lembar Pengesahan Rencana Tapak',
        '10 Gambar Rencana Tapak (Site Plan)',
        '8 Gambar Batas Tanah yang Dikuasai',
        '9 Gambar & Hasil Penyelidikan Tanah',
        '11 Gambar RTH',
        '12 Gambar Perancangan Jaringan Jalan',
        '13 Gambar Perancangan Drainase',
        '14 Gambar Perancangan Jaringan Air Limbah',
        '15 Gambar Perancangan Jaringan Air Bersih',
        '17 Gambar Perencanaan Unit Rumah (Arsitektural)',
      },
      isAgreed: true,
    );
  }
}

final pengajuanFormProvider =
    StateNotifierProvider<PengajuanFormNotifier, PengajuanFormState>((ref) {
      return PengajuanFormNotifier();
    });

// Repository data pengajuan disinkronkan dengan database satu_rumah.sql (Admin Disperwaskim)
class PengajuanListNotifier extends StateNotifier<List<Pengajuan>> {
  PengajuanListNotifier()
    : super([
        Pengajuan(
          id: 'REG-2026-0142',
          namaPerumahan: 'Perumahan Green Tasik',
          namaPt: 'PT. Tasik Indah Sentosa',
          namaDirektur: 'H. Rahmat Hidayat, S.T.',
          nib: '9120003418291',
          npwpPerusahaan: '01.345.678.9-425.000',
          luasLahan: 18500.0,
          jumlahUnit: 120,
          tipePengajuan: 'Pengajuan Site Plan Baru',
          tipePerumahan: 'Subsidi & Komersil',
          status: 'Perlu Perbaikan',
          statusTahap: StatusTahapPengajuan.perluPerbaikan,
          tahapAsalPerbaikan: StatusTahapPengajuan.verifikasiTeknis,
          tanggal: '12 Sep 2026',
          diperbarui: 'Diperbarui 2 hari lalu',
          catatanPerbaikan:
              'Format site plan teknis belum mencantumkan koordinat UTM dan luasan RTH minimum 30%. Bukti kepemilikan tanah belum dilegalisir basah.',
          dokumenPerluRevisi: const [
            'site_plan_dwg',
            'bukti_kepemilikan_lahan',
          ],
          uploadedDocs: const {
            'ktp': 'ktp_direktur_rahmat.pdf',
            'nib': 'nib_tasik_indah_sentosa.pdf',
            'npwp_doc': 'npwp_perusahaan_tasik_indah.pdf',
            'legalitas': 'akta_pendirian_pt_tasik_indah.pdf',
            'asosiasi': 'kta_asosiasi_pengembang_rei.pdf',
            'surat_permohonan': 'surat_permohonan_pengesahan_siteplan.pdf',
            'info_intensitas_ruang': 'krk_greentasik_2024.pdf',
            'bukti_kepemilikan_lahan': 'sertifikat_shm_tanah_greentasik.pdf',
            'bukti_tpu': 'perjanjian_penyediaan_lahan_tpu.pdf',
            'kkpr_doc': 'kesesuaian_pemanfaatan_ruang_kkpr.pdf',
            'pbg_induk': 'pbg_induk_persetujuan_gedung.pdf',
            'rekomendasi_lingkungan': 'dokumen_ukl_upl_dlh_greentasik.pdf',
            'pernyataan_pelepasan': 'surat_pelepasan_hak_tanah.pdf',
            'pernyataan_keabsahan': 'surat_keabsahan_dokumen_notaris.pdf',
            'pernyataan_psu': 'surat_kesanggupan_penyerahan_psu.pdf',
            'site_plan_dwg': 'siteplan_topografi_v1.dwg',
            'pelepasan_lahan': 'surat_pelepasan_kas_desa.pdf',
            'andalalin': 'andalalin_dishub_final.pdf',
            'peta_kontur': 'peta_kontur_elevasi.pdf',
            'penyelidikan_tanah': 'laporan_soil_test_geoteknik.pdf',
          },
          verifiedDocs: const {
            'ktp': true,
            'nib': true,
            'npwp_doc': true,
            'legalitas': true,
            'asosiasi': true,
            'surat_permohonan': true,
            'info_intensitas_ruang': true,
            'bukti_tpu': true,
            'kkpr_doc': true,
            'pbg_induk': true,
            'rekomendasi_lingkungan': true,
            'pernyataan_pelepasan': true,
            'pernyataan_keabsahan': true,
            'bukti_kepemilikan_lahan': false,
            'site_plan_dwg': false,
          },
          technicalFiles: const [
            'siteplan_topografi_v1.dwg',
            'peta_kontur_elevasi.pdf',
            'andalalin_dishub_final.pdf',
            'dokumen_ukl_upl_dlh_greentasik.pdf',
          ],
          selectedCakupanGambar: const [
            '10 Gambar Rencana Tapak (Site Plan)',
            '8 Gambar Batas Tanah yang Dikuasai',
            '9 Gambar & Hasil Penyelidikan Tanah',
            '11 Gambar RTH',
          ],
        ),
        Pengajuan(
          id: 'REG-2026-0084',
          namaPerumahan: 'Mutiara Regency Tasik',
          namaPt: 'PT. Tasik Indah Sentosa',
          namaDirektur: 'H. Tatang Sutisna',
          npwpPerusahaan: '09.123.456.7-423.000',
          luasLahan: 24000.0,
          jumlahUnit: 165,
          tipePengajuan: 'Pengembangan Siteplan',
          tipePerumahan: 'Komersil',
          status: 'Dalam Proses',
          statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
          tanggal: '04 Sep 2026',
          catatanSurvey:
              'Tahap verifikasi administrasi sedang diproses oleh Tim Perwaskim.',
          uploadedDocs: {
            'ktp': 'ktp_direktur_tatang.pdf',
            'nib': 'nib_tasik_indah.pdf',
            'npwp_doc': 'npwp_tasik_indah.pdf',
          },
        ),
        Pengajuan(
          id: 'REG-2026-0038',
          namaPerumahan: 'Grand Tasik Harmoni',
          namaPt: 'PT. Tasik Indah Sentosa',
          namaDirektur: 'H. Rahmat Hidayat, S.T.',
          npwpPerusahaan: '01.345.678.9-425.000',
          luasLahan: 12000.0,
          jumlahUnit: 85,
          tipePengajuan: 'Pengajuan Site Plan Baru',
          tipePerumahan: 'Komersil',
          status: 'Disetujui',
          statusTahap: StatusTahapPengajuan.selesai,
          tanggal: '28 Agu 2026',
          nomorSk: '648/SK-SP/DPKP/2026',
          tanggalSk: '28 Agu 2026',
          skPersetujuanPath: 'SK_Persetujuan_648_SK_SP_DPKP_2026.pdf',
          catatanPerbaikan:
              'Pengesahan Site Plan telah disetujui dan SK resmi telah diterbitkan.',
          uploadedDocs: {
            'ktp': 'ktp_rahmat.pdf',
            'nib': 'nib_tasik_indah.pdf',
            'npwp_doc': 'npwp_tasik_indah.pdf',
          },
        ),
        Pengajuan(
          id: 'SR-2025-0148',
          namaPerumahan: 'Griya Mangkubumi Asri',
          namaPt: 'PT Citra Tasik Mandiri',
          namaDirektur: 'H. Asep Hendrayana, S.T.',
          npwpPerusahaan: '09.123.456.7-423.000',
          luasLahan: 34800.0,
          jumlahUnit: 148,
          tipePerumahan: 'Subsidi',
          status: 'Terjadwal',
          statusTahap: StatusTahapPengajuan.surveyLapangan,
          tanggal: '08 Mei 2025 · 09.21 WIB',
          catatanSurvey:
              'Seluruh dokumen administrasi & teknis telah diverifikasi sesuai. Survey lokasi dijadwalkan tanggal 22 Mei 2025 pukul 09.00 WIB.',
          dokumenPerluRevisi: const [],
          uploadedDocs: {
            'nib': 'nib_dan_izin_usaha.pdf',
            'npwp_doc': 'npwp_perusahaan.pdf',
            'legalitas': 'akta_pendirian_perusahaan.pdf',
            'ktp': 'ktp_direktur_utama.pdf',
            'surat_kuasa': 'surat_kuasa_penanggung_jawab.pdf',
            'site_plan_dwg': 'site_plan_yang_disahkan.pdf',
            'bukti_kepemilikan_lahan': 'bukti_kepemilikan_tanah.pdf',
            'rekomendasi_lingkungan': 'persetujuan_lingkungan.pdf',
            'pbg_induk': 'izin_pbg.pdf',
            'pernyataan_pelepasan': 'surat_pernyataan_pengembang.pdf',
          },
          technicalFiles: [
            'Paket_tekdok_GriyaMahardika.zip',
            'gambar_rencana_tapak.pdf',
            'rencana_utilitas.pdf',
            'rencana_drainase.pdf',
          ],
          selectedCakupanGambar: [
            '10 Gambar Rencana Tapak (Site Plan)',
            '12 Gambar Perancangan Jaringan Jalan',
            '13 Gambar Perancangan Drainase',
            '15 Gambar Perancangan Jaringan Air Bersih',
          ],
          tanggalSurvey: DateTime(2025, 5, 22, 9, 0),
          riwayatSurvey: [
            HasilSurveyItem(
              id: 'survey-0148',
              tanggalSurvey: DateTime(2025, 5, 22, 9, 0),
              pelaksanaNama: 'Rahmat Hidayat, S.T.',
              pelaksanaJabatan: 'Tim Pengawas Perwaskim',
              lokasiPerumahan: 'Kec. Mangkubumi, Kota Tasikmalaya',
              statusHasilEvaluasi: 'perluEvaluasi',
              temuanLapangan: [
                'Saluran drainase sisi timur belum sesuai detail rencana.',
                'Akses kendaraan pemadam perlu penegasan pada area tikungan blok C.',
              ],
              kesimpulan: [
                'Kawasan dapat dilanjutkan setelah perbaikan desain drainase dan penyampaian revisi gambar teknis.',
              ],
              kesepakatan: [
                'Pengembang akan mengunggah revisi dalam 7 hari kerja.',
              ],
              rencanaTindakLanjut: [
                'RENCANA TINDAK LANJUT WAJIB: Perbarui gambar drainase dan lengkapi simulasi manuver kendaraan pemadam sebelum persetujuan dilanjutkan.',
              ],
              photoPaths: const [],
              nomorSuratBA: 'BA/PERWASKIM/2025/05/0148',
              isDraft: true,
            ),
          ],
        ),
        Pengajuan(
          id: 'SR-2025-0147',
          namaPerumahan: 'Kencana Kawalu Regency',
          namaPt: 'PT Sukapura Mandiri Properti',
          namaDirektur: 'Dedi Setiadi, S.T.',
          npwpPerusahaan: '08.234.567.8-423.000',
          luasLahan: 18500.0,
          jumlahUnit: 85,
          tipePerumahan: 'Subsidi',
          status: 'Terjadwal',
          statusTahap: StatusTahapPengajuan.surveyLapangan,
          tanggal: '12 Mei 2025 · 15.20 WIB',
          tanggalSurvey: DateTime(2025, 5, 20, 9, 0),
          catatanSurvey:
              'Jadwal survey lokasi telah dikonfirmasi untuk tanggal 20 Mei 2025. Titik kumpul Kantor Pemasaran Kawalu.',
          uploadedDocs: {
            'ktp': 'ktp_direktur.pdf',
            'nib': 'nib_sukapura.pdf',
            'npwp_doc': 'npwp_sukapura.pdf',
            'site_plan_dwg': 'siteplan_kencana.pdf',
          },
        ),
        Pengajuan(
          id: 'SR-2025-0146',
          namaPerumahan: 'Pesona Cibeureum Pratama',
          namaPt: 'PT Priangan Griya Graha',
          namaDirektur: 'Ir. Tatan Rustandi',
          npwpPerusahaan: '07.345.678.9-423.000',
          luasLahan: 26000.0,
          jumlahUnit: 120,
          tipePerumahan: 'Subsidi',
          status: 'Menunggu verifikasi',
          statusTahap: StatusTahapPengajuan.verifikasiAdministrasi,
          tanggal: '12 Mei 2025',
          catatanPerbaikan:
              'Dokumen persyaratan lengkap dan siap diperiksa tim administratif Disperwaskim.',
          uploadedDocs: {
            'ktp': 'ktp_tatan.pdf',
            'nib': 'nib_priangan.pdf',
            'npwp_doc': 'npwp_priangan.pdf',
            'site_plan_dwg': 'siteplan_pesona.pdf',
          },
        ),
      ]);

  void addPengajuan(Pengajuan p) {
    state = [p, ...state];
  }

  bool addPengajuanIfAbsent(Pengajuan p) {
    if (state.any((item) => item.id == p.id)) return false;
    addPengajuan(p);
    return true;
  }

  void updatePengajuan(Pengajuan p) {
    state = state.map((item) => item.id == p.id ? p : item).toList();
  }

  void updatePengajuanStatus(String id, String status) {
    state = state
        .map((item) => item.id == id ? item.copyWith(status: status) : item)
        .toList();
  }
}

final pengajuanListProvider =
    StateNotifierProvider<PengajuanListNotifier, List<Pengajuan>>((ref) {
      return PengajuanListNotifier();
    });
