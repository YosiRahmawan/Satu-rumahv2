import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/presentation/screens/notifikasi_list_screen.dart';

NotifikasiModel _notification({
  String? targetRoute,
  String description = 'Pengingat lokal',
}) {
  return NotifikasiModel(
    id: 'test-notification',
    jenis: JenisNotifikasi.deadlineVerifikasi,
    judul: 'Notifikasi uji',
    deskripsi: description,
    waktu: DateTime(2026, 8, 19),
    targetRoute: targetRoute,
  );
}

void main() {
  test('notification targets are rewritten to a valid role route', () {
    final item = _notification(
      targetRoute: '/pengajuan/detail/SR-20260720-586',
      description: 'Pengajuan SR-20260720-586 membutuhkan perhatian.',
    );

    expect(
      notificationTargetForRole(item, AppRole.admin),
      '/admin/pengajuan/detail/SR-20260720-586',
    );
    expect(
      notificationTargetForRole(item, AppRole.developer),
      '/pengajuan/detail/SR-20260720-586',
    );
    expect(
      notificationTargetForRole(item, AppRole.perwaskim),
      '/monitoring/lapangan',
    );
  });

  test(
    'missing or informational notification targets are explicit unavailable outcomes',
    () {
      expect(notificationTargetForRole(_notification(), AppRole.admin), isNull);
      expect(
        notificationTargetForRole(
          _notification(targetRoute: '/monitoring'),
          AppRole.developer,
        ),
        isNull,
      );
      expect(
        notificationTargetForRole(
          _notification(targetRoute: '/unknown'),
          AppRole.admin,
        ),
        isNull,
      );
    },
  );

  test('Perwaskim diarahkan ke /monitoring/lapangan dan riwayat untuk BA', () {
    final notifAdminRoute = _notification(targetRoute: '/monitoring');
    expect(
      notificationTargetForRole(notifAdminRoute, AppRole.perwaskim),
      '/monitoring/lapangan',
    );

    final notifBA = NotifikasiModel(
      id: 'ba-1',
      jenis: JenisNotifikasi.baDiterbitkan,
      judul: 'BA Terbit',
      deskripsi: 'BA selesai',
      waktu: DateTime(2026),
      targetRoute: '/monitoring/lapangan',
    );
    expect(
      notificationTargetForRole(notifBA, AppRole.perwaskim),
      '/monitoring/lapangan/riwayat',
    );
  });

  test('developerNotificationTarget tetap membuka detail saat daftar pengajuan kosong / loading', () {
    final serverItem = NotifikasiModel(
      id: 'srv-10',
      jenis: JenisNotifikasi.pengajuanBaru,
      judul: 'Update',
      deskripsi: 'Update pengajuan',
      waktu: DateTime(2026),
      pengajuanId: 'SR-2026-9999',
      isSimulasi: false,
    );

    // Saat daftar pengajuan kosong (masih loading / belum selesai fetch)
    final target = developerNotificationTarget(
      serverItem,
      [],
      revisiAktif: false,
    );
    expect(target, '/pengajuan/detail/SR-2026-9999');
  });
}
