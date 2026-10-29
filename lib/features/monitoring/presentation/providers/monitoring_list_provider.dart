import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/role_session.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/repositories/officer_api_repository.dart';
import 'monitoring_form_provider.dart';
import '../../../../core/api/remote_load.dart';

final monitoringListProvider =
    StateNotifierProvider<MonitoringListNotifier, List<MonitoringModel>>((ref) {
      final repo = ref.watch(monitoringRepositoryProvider);
      return MonitoringListNotifier(repo);
    });

/// Tab aktif pada halaman utama Tim Monitoring (0 Beranda, 1 Riwayat, 2 Notifikasi, 3 Profil).
/// Dipegang di provider agar layar lain bisa mengembalikan pengguna ke Beranda.
final monitoringTabProvider = StateProvider<int>((ref) => 0);

/// Daftar laporan sebagai `AsyncValue` agar layar tetap memakai `.when`.
///
/// Datanya sudah ada di memori (repository lokal), jadi nilainya langsung
/// tersedia. Tidak ada status loading sehingga Beranda dan Riwayat tidak
/// berkedip menampilkan kartu "Memuat data" sesaat setelah login. Bila sumber
/// data berubah menjadi jaringan, ganti kembali dengan `FutureProvider`.
final monitoringListAsyncProvider = Provider<AsyncValue<List<MonitoringModel>>>(
  (ref) => AsyncValue.data(ref.watch(monitoringListProvider)),
);

/// Provider penugasan survey aktif yang dikirim dari Admin ke Tim Perwaskim
final surveyAktifProvider = Provider<List<Pengajuan>>((ref) {
  // Mode API: tugas berasal dari server (penugasan petugas ini).
  if (ref.watch(apiEnabledProvider)) {
    return [
      for (final a in ref.watch(officerAssignmentsProvider)) a.asPengajuan(),
    ];
  }
  final pengajuanList = ref.watch(pengajuanListProvider);
  return pengajuanList.where((p) {
    return p.statusTahap == StatusTahapPengajuan.surveyLapangan ||
        p.tanggalSurvey != null;
  }).toList();
});

/// Tim pelaksana yang ditetapkan Admin untuk tugas dengan nomor pengajuan [id].
/// Null di mode contoh atau bila tugasnya tidak ada.
final assignmentTeamProvider = Provider.family<List<MonitoringPerson>?, String>(
  (ref, id) {
    if (!ref.watch(apiEnabledProvider)) return null;
    for (final a in ref.watch(officerAssignmentsProvider)) {
      if ((a.submissionNumber ?? 'TUGAS-${a.id}') == id && a.team.isNotEmpty) {
        return a.team;
      }
    }
    return null;
  },
);

/// Tugas survei terbuka milik petugas yang masuk. Kosong sampai dimuat dari
/// server; berganti akun membuat daftar baru.
class OfficerAssignmentsNotifier
    extends StateNotifier<List<OfficerAssignment>> {
  OfficerAssignmentsNotifier(this.remote) : super(const []);

  final OfficerRemote? remote;

  /// Status pemuatan dari server: layar membedakan memuat, kosong, dan gagal.
  final ValueNotifier<RemoteLoad> load = ValueNotifier(RemoteLoad.idle);

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }

  /// Memuat ulang; mengembalikan galatnya (bila ada) dan mempertahankan daftar lama.
  /// [silent] untuk penyegaran latar belakang: tanpa indikator memuat dan tanpa menandai gagal.
  Future<ApiException?> refresh({bool silent = false}) async {
    final source = remote;
    if (source == null) return null;
    if (!silent) load.value = RemoteLoad.loading;
    try {
      final items = await source.assignments();
      if (mounted) {
        state = items;
        load.value = RemoteLoad.loaded;
      }
      return null;
    } on ApiException catch (e) {
      if (mounted && !silent) load.value = RemoteLoad(LoadState.failed, e);
      return e;
    }
  }
}

final officerAssignmentsProvider =
    StateNotifierProvider<OfficerAssignmentsNotifier, List<OfficerAssignment>>((
      ref,
    ) {
      final session = ref.watch(
        roleSessionProvider.select((s) => (s.role, s.username)),
      );
      final remote = ref.watch(apiEnabledProvider)
          ? ref.watch(officerRemoteProvider)
          : null;
      final notifier = OfficerAssignmentsNotifier(remote);
      if (remote != null && session.$1 == AppRole.perwaskim) {
        unawaited(notifier.refresh());
      }
      return notifier;
    });

class MonitoringListNotifier extends StateNotifier<List<MonitoringModel>> {
  final dynamic _repository;

  MonitoringListNotifier(this._repository) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repository.getAllMonitoring();
  }

  void search(String query, {DateTime? fromDate, DateTime? toDate}) {
    state = _repository.searchMonitoring(
      query: query,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
