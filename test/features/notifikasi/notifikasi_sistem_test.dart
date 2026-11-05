import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/notifications/notifikasi_sistem.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/data/notifikasi_api_repository.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';

class _Remote implements NotifikasiRemote {
  List<NotifikasiModel> isi = [];

  @override
  Future<List<NotifikasiModel>> list(AppRole role) async => isi;

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}

class _Sistem implements NotifikasiSistem {
  final tampil = <({int id, String judul, String isi})>[];

  @override
  Future<void> siapkan() async {}

  @override
  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
  }) async => tampil.add((id: id, judul: judul, isi: isi));
}

NotifikasiModel _n(int id, {bool dibaca = false}) => NotifikasiModel(
  id: '$serverNotifPrefix$id',
  jenis: JenisNotifikasi.penugasanSurvei,
  judul: 'Tugas $id',
  deskripsi: 'Isi $id',
  waktu: DateTime(2026, 11, 5),
  isRead: dibaca,
  penerima: AppRole.perwaskim,
);

void main() {
  late _Remote remote;
  late _Sistem sistem;
  var dilayar = false;

  NotifikasiNotifier buat() => NotifikasiNotifier(
    remote: remote,
    role: AppRole.perwaskim,
    sistem: sistem,
    sedangDiLayar: () => dilayar,
  );

  setUp(() {
    remote = _Remote()..isi = [_n(1)];
    sistem = _Sistem();
    dilayar = false;
  });

  test(
    'pemuatan pertama hanya acuan; yang baru sesudahnya muncul di bilah sistem',
    () async {
      final n = buat();
      await n.refresh();
      expect(sistem.tampil, isEmpty);

      remote.isi = [_n(2), _n(1)];
      await n.refresh();
      expect(sistem.tampil.map((e) => e.judul), ['Tugas 2']);

      // Sudah pernah diberitahukan: tidak diulang.
      await n.refresh();
      expect(sistem.tampil, hasLength(1));
    },
  );

  test(
    'saat aplikasi sedang dilihat tidak ada notifikasi sistem (badge sudah cukup)',
    () async {
      final n = buat();
      await n.refresh();
      dilayar = true;
      remote.isi = [_n(2), _n(1)];
      await n.refresh();
      expect(sistem.tampil, isEmpty);
    },
  );

  test(
    'yang sudah dibaca tidak diberitahukan; banyak sekaligus diringkas',
    () async {
      final n = buat();
      await n.refresh();

      remote.isi = [_n(2, dibaca: true), _n(1)];
      await n.refresh();
      expect(sistem.tampil, isEmpty);

      remote.isi = [_n(6), _n(5), _n(4), _n(3), _n(2, dibaca: true), _n(1)];
      await n.refresh();
      expect(sistem.tampil, hasLength(1));
      expect(sistem.tampil.single.isi, '4 notifikasi baru');
    },
  );
}
