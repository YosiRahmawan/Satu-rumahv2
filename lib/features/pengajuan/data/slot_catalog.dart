import '../presentation/providers/pengajuan_form_controller.dart';

/// Pemetaan kunci berkas Flutter ↔ kode slot server (KONTRAK_INTEGRASI.md bagian 5)
/// dan nilai-nilai pengajuan yang namanya berbeda antara Flutter dan server.
class SlotCatalog {
  SlotCatalog._();

  /// Kunci Flutter → kode slot. `S4-01` (site plan) berasal dari
  /// `technicalFiles`, `S4-02` dari `kajian_teknis`.
  static const Map<String, String> codeByKey = {
    'ktp': 'S2-01',
    'nib': 'S2-02',
    'npwp_doc': 'S2-03',
    'asosiasi': 'S2-04',
    'legalitas': 'S2-05',
    'surat_permohonan': 'S3-01',
    'info_intensitas_ruang': 'S3-02',
    'bukti_kepemilikan_lahan': 'S3-03',
    'bukti_tpu': 'S3-04',
    'rekomendasi_lingkungan': 'S3-05',
    'andalalin': 'S3-06',
    'rekomendasi_air_bersih': 'S3-07',
    'rekomendasi_listrik': 'S3-08',
    'pernyataan_psu': 'S3-09',
    'penanggung_jawab_teknis': 'S3-10',
    'proposal_pembangunan': 'S3-11',
    'site_plan_dwg': 'S4-01',
    'kajian_teknis': 'S4-02',
  };

  static final Map<String, String> keyByCode = {
    for (final e in codeByKey.entries) e.value: e.key,
  };

  /// Nama berkas yang dipakai di pesan galat.
  static String labelOfCode(String code) {
    final key = keyByCode[code];
    for (final s in PengajuanStep2DocumentContract.slots) {
      if (s.key == key) return s.label;
    }
    for (final s in PengajuanStep3DocumentContract.slots) {
      if (s.key == key) return s.label;
    }
    return switch (code) {
      'S4-01' => 'Dokumen Site Plan',
      'S4-02' => 'Dokumen Kajian Teknis',
      _ => code,
    };
  }

  /// Rujukan berkas lokal per kode slot, dari isian form.
  static Map<String, List<String>> filesBySlot(PengajuanFormState s) {
    final out = <String, List<String>>{};
    void add(String code, Iterable<String> refs) {
      final clean = refs.where((r) => r.trim().isNotEmpty).toList();
      if (clean.isNotEmpty) out[code] = clean;
    }

    for (final e in codeByKey.entries) {
      if (e.value == 'S4-01' || e.value == 'S4-02') continue;
      final multi = s.multiUploadedDocs[e.key];
      add(
        e.value,
        multi != null && multi.isNotEmpty
            ? multi
            : [s.uploadedDocs[e.key] ?? ''],
      );
    }
    add('S4-01', s.technicalFiles);
    add('S4-02', s.technicalOtherFiles);
    return out;
  }

  static const _tipePerumahan = {
    'Subsidi': 'subsidi',
    'Komersil': 'komersil',
    'Campuran': 'subsidi_komersil',
  };

  static String tipePerumahanToApi(String label) =>
      _tipePerumahan[label] ?? 'subsidi';

  static String tipePerumahanFromApi(String? value) => _tipePerumahan.entries
      .firstWhere(
        (e) => e.value == value,
        orElse: () => const MapEntry('Subsidi', 'subsidi'),
      )
      .key;
}
