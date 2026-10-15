import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_draft_store.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = PengajuanDraftStore();

  PengajuanFormNotifier notifier([String owner = 'a']) =>
      PengajuanFormNotifier(store: store, owner: owner);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('simpan otomatis', () {
    test('setiap perubahan form tersimpan sebagai draf', () async {
      final n = notifier();
      addTearDown(n.dispose);

      n.updateNamaPerumahan('Taman Asri Tasik');
      n.updateJumlahUnit(120);
      await pumpEventQueue();

      final json = await store.load('a');
      expect(json?['namaPerumahan'], 'Taman Asri Tasik');
      expect(json?['jumlahUnit'], 120);
      expect(n.lastSavedAt.value, isNotNull);
    });

    test('form kosong tidak menulis draf', () async {
      final n = notifier();
      addTearDown(n.dispose);
      n.updateTipe('Komersil');
      await pumpEventQueue();

      expect(await n.hasDraft(), isFalse);
    });

    test('draf dipisah per akun', () async {
      final a = notifier('a');
      final b = notifier('b');
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      a.updateNamaPerumahan('Milik A');
      await pumpEventQueue();

      expect(await a.hasDraft(), isTrue);
      expect(await b.hasDraft(), isFalse);
    });

    test('tanpa store tidak menyimpan apa pun', () async {
      final n = PengajuanFormNotifier();
      addTearDown(n.dispose);
      n.updateNamaPerumahan('Tanpa store');
      await pumpEventQueue();

      expect(await n.hasDraft(), isFalse);
      expect(await n.saveDraft(), DraftSaveResult.empty);
    });
  });

  group('lanjutkan draf', () {
    test('memulihkan isian, dokumen, dan cakupan gambar', () async {
      final first = notifier();
      addTearDown(first.dispose);
      first
        ..updateNamaPerumahan('Taman Asri Tasik')
        ..updateAlamatProyek('Jl. Contoh No. 1')
        ..updateNpwp('012345678411000')
        ..setNpwpVerified(true)
        ..updateLuasLahan(1250.5)
        ..updateJumlahUnit(80)
        ..updateTipe('Komersil')
        ..updateDayaListrik('900 VA')
        ..uploadDocument('ktp', 'ktp.pdf')
        ..uploadDocuments('kajian_teknis', ['a.pdf', 'b.pdf'])
        ..addTechnicalFiles(['denah.dwg']);
      await pumpEventQueue();

      final second = notifier();
      addTearDown(second.dispose);
      expect(await second.restoreDraft(), isTrue);

      final s = second.state;
      expect(s.namaPerumahan, 'Taman Asri Tasik');
      expect(s.alamatProyek, 'Jl. Contoh No. 1');
      expect(s.npwpVerified, isTrue);
      expect(s.luasLahan, 1250.5);
      expect(s.jumlahUnit, 80);
      expect(s.tipePerumahan, 'Komersil');
      expect(s.dayaListrik, '900 VA');
      expect(s.uploadedDocs['ktp'], 'ktp.pdf');
      expect(s.multiUploadedDocs['kajian_teknis'], ['a.pdf', 'b.pdf']);
      expect(s.technicalFiles, ['denah.dwg']);
    });

    test('pernyataan persetujuan tidak ikut dipulihkan', () async {
      final first = notifier();
      addTearDown(first.dispose);
      first
        ..updateNamaPerumahan('Taman Asri')
        ..toggleAgreement(true);
      await pumpEventQueue();

      final second = notifier();
      addTearDown(second.dispose);
      await second.restoreDraft();
      expect(second.state.isAgreed, isFalse);
    });

    test('draf rusak ditolak tanpa melempar', () async {
      SharedPreferences.setMockInitialValues({
        'pengajuan_draft_v1_a': 'bukan json',
      });
      final n = notifier();
      addTearDown(n.dispose);

      expect(await n.hasDraft(), isTrue);
      expect(await n.restoreDraft(), isFalse);
      expect(n.state.hasContent, isFalse);
    });

    test('reset menghapus draf', () async {
      final n = notifier();
      addTearDown(n.dispose);
      n.updateNamaPerumahan('Akan dihapus');
      await pumpEventQueue();
      expect(await n.hasDraft(), isTrue);

      n.reset();
      await pumpEventQueue();
      expect(await n.hasDraft(), isFalse);
      expect(n.state.hasContent, isFalse);
    });
  });

  group('info draf untuk kartu', () {
    test('tersedia setelah simpan dan hilang setelah reset', () async {
      final n = notifier();
      addTearDown(n.dispose);
      expect(n.draftInfo.value, isNull);

      n.updateNamaPerumahan('Taman Asri');
      await pumpEventQueue();
      expect(n.draftInfo.value?.nama, 'Taman Asri');
      expect(n.draftInfo.value?.savedAt, isNotNull);

      n.reset();
      expect(n.draftInfo.value, isNull);
    });

    test('draf dari sesi sebelumnya terbaca saat notifier dibuat', () async {
      final first = notifier();
      addTearDown(first.dispose);
      first.updateNamaPerumahan('Draf Lama');
      await pumpEventQueue();

      final second = notifier();
      addTearDown(second.dispose);
      await pumpEventQueue();
      expect(second.draftInfo.value?.nama, 'Draf Lama');
      expect(second.state.hasContent, isFalse);
    });

    test('nilai yang sama tidak mengubah state (kursor bergerak)', () async {
      final n = notifier();
      addTearDown(n.dispose);
      n.updateNamaPerumahan('Taman Asri');
      final sebelum = n.state;

      n
        ..updateNamaPerumahan('Taman Asri')
        ..updateJumlahUnit(0)
        ..updateTipe('Subsidi');
      expect(identical(n.state, sebelum), isTrue);
    });
  });

  group('saveDraft dan resumeRoute', () {
    test('saveDraft melaporkan hasil sebenarnya', () async {
      final n = notifier();
      addTearDown(n.dispose);
      expect(await n.saveDraft(), DraftSaveResult.empty);

      n.updateNamaPerumahan('Ada isi');
      expect(await n.saveDraft(), DraftSaveResult.saved);
    });

    test('resumeRoute menuju langkah pertama yang belum lengkap', () {
      final n = PengajuanFormNotifier();
      addTearDown(n.dispose);
      expect(n.state.resumeRoute, '/pengajuan/step1');

      n
        ..updateNamaPerumahan('Taman Asri')
        ..updateAlamatProyek('Jl. Contoh')
        ..updateNpwp('012345678411000')
        ..updateLuasLahan(100)
        ..updateJumlahUnit(10);
      // NPWP belum diverifikasi: tetap di langkah 1.
      expect(n.state.resumeRoute, '/pengajuan/step1');

      n.setNpwpVerified(true);
      expect(n.state.resumeRoute, '/pengajuan/step2');
    });
  });
}
