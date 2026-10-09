import 'package:flutter_test/flutter_test.dart';

import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';

void main() {
  test('Fase 3 canonical document contract is exact and shared by review', () {
    expect(PengajuanStep3DocumentContract.allKeys, <String>[
      'surat_permohonan',
      'info_intensitas_ruang',
      'bukti_kepemilikan_lahan',
      'bukti_tpu',
      'rekomendasi_lingkungan',
      'andalalin',
      'rekomendasi_air_bersih',
      'rekomendasi_listrik',
      'pernyataan_psu',
      'penanggung_jawab_teknis',
      'proposal_pembangunan',
    ]);
    expect(
      PengajuanStep3DocumentContract.requiredKeys,
      isNot(contains('penanggung_jawab_teknis')),
    );
    expect(
      PengajuanStep3DocumentContract.slots.map((slot) => slot.key).toList(),
      PengajuanStep3DocumentContract.allKeys,
    );
  });

  group('PengajuanFormState validation', () {
    test('requires positive finite step 1 values', () {
      final valid = PengajuanFormState(
        tipePengajuan: 'Pengajuan Site Plan Baru',
        namaPerumahan: 'Perumahan A',
        alamatProyek: 'Jl. Tamansari No. 1',
        npwpPerusahaan: '01.234',
        luasLahan: 1,
        jumlahUnit: 1,
      );

      expect(valid.isStep1Valid, isTrue);
      expect(valid.copyWith(luasLahan: 0).isStep1Valid, isFalse);
      expect(valid.copyWith(luasLahan: -1).isStep1Valid, isFalse);
      expect(valid.copyWith(luasLahan: double.nan).isStep1Valid, isFalse);
      expect(valid.copyWith(jumlahUnit: 0).isStep1Valid, isFalse);
      expect(valid.copyWith(namaPerumahan: '').isStep1Valid, isFalse);
      expect(valid.copyWith(alamatProyek: '').isStep1Valid, isFalse);
      expect(valid.copyWith(tipePengajuan: '').isStep1Valid, isFalse);
      expect(valid.copyWith(npwpPerusahaan: '').isStep1Valid, isFalse);
    });

    test('requires every named document for steps 2 and 3', () {
      final notifier = PengajuanFormNotifier();
      final required = <String, String>{
        'ktp': 'ktp.pdf',
        'nib': 'nib.pdf',
        'npwp_doc': 'npwp.pdf',
        'asosiasi': 'asosiasi.pdf',
        'legalitas': 'legalitas.pdf',
        'surat_permohonan': 'permohonan.pdf',
        'info_intensitas_ruang': 'intensitas.pdf',
        'bukti_kepemilikan_lahan': 'lahan.pdf',
        'bukti_tpu': 'tpu.pdf',
        'rekomendasi_lingkungan': 'lingkungan.pdf',
        'andalalin': 'andalalin.pdf',
        'rekomendasi_air_bersih': 'air.pdf',
        'rekomendasi_listrik': 'listrik.pdf',
        'pernyataan_psu': 'psu.pdf',
        'proposal_pembangunan': 'proposal.pdf',
      };

      for (final entry in required.entries) {
        notifier.uploadDocument(entry.key, entry.value);
      }

      expect(notifier.state.isStep2Valid, isTrue);
      expect(notifier.state.isStep3Valid, isTrue);
      notifier.deleteDocument('legalitas');
      expect(notifier.state.isStep2Valid, isFalse);
    });

    test('appends multi-file selections without dropping prior files', () {
      final notifier = PengajuanFormNotifier();

      notifier.uploadDocuments('rekomendasi_lingkungan', ['a.pdf', 'b.pdf']);
      notifier.uploadDocuments('rekomendasi_lingkungan', ['c.pdf']);

      expect(notifier.state.multiUploadedDocs['rekomendasi_lingkungan'], [
        'a.pdf',
        'b.pdf',
        'c.pdf',
      ]);
      expect(notifier.state.uploadedDocs['rekomendasi_lingkungan'], 'a.pdf');
    });

    test('step 3 and aggregate validation use only current required keys', () {
      final notifier = PengajuanFormNotifier();
      for (final key in PengajuanStep3DocumentContract.requiredKeys) {
        notifier.uploadDocument(key, '$key.pdf');
      }

      expect(notifier.state.isStep3Valid, isTrue);
      expect(notifier.state.isAllValid, isFalse);
      notifier.fillDummyData();
      expect(notifier.state.isStep3Valid, isTrue);
      expect(notifier.state.isAllValid, isTrue);
      notifier.deleteDocument('proposal_pembangunan');
      expect(notifier.state.isStep3Valid, isFalse);
      expect(notifier.state.isAllValid, isFalse);
    });

    test('technical files satisfy step 4 and empty names do not', () {
      final notifier = PengajuanFormNotifier();

      notifier.uploadDocument('site_plan_dwg', '');
      expect(notifier.state.uploadedDocs, isEmpty);
      notifier.addTechnicalFiles(['', '  ', 'siteplan.dwg']);
      expect(notifier.state.isStep4Valid, isTrue);
      expect(notifier.state.technicalFiles, ['siteplan.dwg']);
      notifier.removeTechnicalFile(0);
      expect(notifier.state.isStep4Valid, isFalse);
      expect(notifier.state.uploadedDocs.containsKey('site_plan_dwg'), isFalse);
    });

    test('list notifier rejects duplicate IDs', () {
      final notifier = PengajuanListNotifier();
      final original = notifier.state.first;

      final added = notifier.addPengajuanIfAbsent(original.copyWith());

      expect(added, isFalse);
      expect(
        notifier.state.where((item) => item.id == original.id),
        hasLength(1),
      );
    });
  });
}
