import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/role_session.dart';
import '../../data/models/notifikasi_model.dart';

class NotifikasiNotifier extends StateNotifier<List<NotifikasiModel>> {
  NotifikasiNotifier()
    : super([
        NotifikasiModel(
          id: '1',
          jenis: JenisNotifikasi.pengajuanBaru,
          judul: 'Pengajuan baru',
          deskripsi:
              'Griya Mangkubumi Asri (SR-2025-0148) telah diajukan dan menunggu verifikasi teknis.',
          waktu: DateTime(2025, 5, 8, 9, 21),
          isRead: false,
          targetRoute: '/admin/pengajuan/detail/SR-2025-0148',
          pengajuanId: 'SR-2025-0148',
          penerima: AppRole.admin,
        ),
        NotifikasiModel(
          id: '2',
          jenis: JenisNotifikasi.dokumenDiunggahUlang,
          judul: 'Permintaan perbaikan telah terkirim',
          deskripsi:
              'Tamansari Asri Residence (SR-2025-0144) telah melengkapi verifikasi teknis.',
          waktu: DateTime(2025, 5, 10, 10, 0),
          isRead: false,
          targetRoute: '/admin/pengajuan/detail/SR-2025-0144',
          penerima: AppRole.admin,
        ),
        NotifikasiModel(
          id: '3',
          jenis: JenisNotifikasi.reminderSurvey,
          judul: 'Survey ditugaskan',
          deskripsi:
              'Pesona Cibeureum Pratama (SR-2025-0146) telah diagendakan survey lokasi.',
          waktu: DateTime(2025, 5, 12, 14, 0),
          isRead: false,
          targetRoute: '/monitoring',
          pengajuanId: 'SR-2025-0146',
          penerima: AppRole.perwaskim,
        ),
        NotifikasiModel(
          id: '4',
          jenis: JenisNotifikasi.deadlineVerifikasi,
          judul: 'Monitoring final tersedia',
          deskripsi:
              'Hasil monitoring Bungursari Harmoni Indah (SR-2025-0145) telah disahkan Final.',
          waktu: DateTime(2025, 5, 11, 16, 0),
          isRead: true,
          targetRoute: '/monitoring',
          penerima: AppRole.admin,
        ),
        NotifikasiModel(
          id: '5',
          jenis: JenisNotifikasi.deadlineVerifikasi,
          judul: 'Dokumen persetujuan akhir tersedia',
          deskripsi:
              'Kencana Kawalu Regency (SR-2025-0147) siap untuk survey lokasi perwaskim.',
          waktu: DateTime(2025, 5, 13, 8, 30),
          isRead: true,
          penerima: AppRole.admin,
        ),
        // Contoh Pengembang memakai seed pengajuan yang ada. Bertanda simulasi;
        // bukan hasil alur kerja nyata.
        NotifikasiModel(
          id: 'sim-dev-revisi-0142',
          jenis: JenisNotifikasi.perluRevisi,
          judul: 'Dokumen perlu diperbaiki',
          deskripsi:
              'Verifikator meminta perbaikan berkas pada Perumahan Green Tasik (REG-2026-0142). Buka Perbarui Berkas untuk melihat catatan dan mengunggah berkas pengganti.',
          waktu: DateTime(2026, 9, 15, 16, 20),
          targetRoute: '/pengajuan/detail/REG-2026-0142',
          pengajuanId: 'REG-2026-0142',
          penerima: AppRole.developer,
          isSimulasi: true,
        ),
        NotifikasiModel(
          id: 'sim-dev-terkirim-0142',
          jenis: JenisNotifikasi.pengajuanBaru,
          judul: 'Pengajuan diterima',
          deskripsi:
              'Pengajuan Perumahan Green Tasik (REG-2026-0142) telah diterima dan masuk verifikasi.',
          waktu: DateTime(2026, 9, 12, 14, 15),
          isRead: true,
          targetRoute: '/pengajuan/detail/REG-2026-0142',
          pengajuanId: 'REG-2026-0142',
          penerima: AppRole.developer,
          isSimulasi: true,
        ),
        NotifikasiModel(
          id: 'sim-dev-terkirim-0084',
          jenis: JenisNotifikasi.pengajuanBaru,
          judul: 'Pengajuan diterima',
          deskripsi:
              'Pengajuan Mutiara Regency Tasik (REG-2026-0084) telah diterima dan sedang dalam verifikasi administrasi.',
          waktu: DateTime(2026, 9, 4, 9, 0),
          isRead: true,
          targetRoute: '/pengajuan/detail/REG-2026-0084',
          pengajuanId: 'REG-2026-0084',
          penerima: AppRole.developer,
          isSimulasi: true,
        ),
      ]);

  void addNotification(NotifikasiModel item) {
    state = [item, ...state];
  }

  void markAsRead(String id) {
    state = state
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
  }

  /// Menandai dibaca. Dengan [untuk], hanya notifikasi yang tampil bagi role
  /// itu yang berubah; tanpa argumen, semua (perilaku lama).
  void markAllAsRead({AppRole? untuk}) {
    state = state
        .map(
          (item) => untuk == null || item.untukRole(untuk)
              ? item.copyWith(isRead: true)
              : item,
        )
        .toList();
  }

  int get unreadCount => state.where((e) => !e.isRead).length;
}

final notifikasiProvider =
    StateNotifierProvider<NotifikasiNotifier, List<NotifikasiModel>>((ref) {
      return NotifikasiNotifier();
    });

/// Belum dibaca yang relevan bagi role aktif (badge navigasi dan header).
final unreadNotifikasiCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notifikasiProvider);
  final role = ref.watch(roleSessionProvider.select((s) => s.role));
  return notifs.where((e) => !e.isRead && e.untukRole(role)).length;
});

final unreadCountProvider = unreadNotifikasiCountProvider;
