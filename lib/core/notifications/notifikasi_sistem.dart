import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifikasi di bilah sistem HP (muncul walau aplikasi tidak sedang dilihat).
/// Ini notifikasi lokal yang dipicu pemeriksaan server oleh aplikasi sendiri, bukan push dari server:
/// hanya muncul selama aplikasi masih berjalan di latar belakang. Push sungguhan butuh proyek Firebase.
abstract class NotifikasiSistem {
  /// Menyiapkan saluran dan meminta izin tampil (Android 13+). Aman dipanggil berulang.
  Future<void> siapkan();

  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
  });
}

class NotifikasiSistemPerangkat implements NotifikasiSistem {
  NotifikasiSistemPerangkat();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _siap = false;
  Future<void>? _persiapan;

  bool get _didukung =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> siapkan() => _persiapan ??= _siapkan();

  Future<void> _siapkan() async {
    if (!_didukung) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _siap = true;
    } catch (_) {
      // Tanpa izin atau plugin: aplikasi tetap berjalan, hanya tanpa notifikasi sistem.
    }
  }

  @override
  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
  }) async {
    await siapkan();
    if (!_siap) return;
    try {
      await _plugin.show(
        id: id,
        title: judul,
        body: isi,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'satu_rumah_notifikasi',
            'Notifikasi Satu Rumah',
            channelDescription: 'Tugas, perbaikan, dan keputusan pengajuan',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Gagal menampilkan tidak boleh mengganggu alur aplikasi.
    }
  }
}

final notifikasiSistemProvider = Provider<NotifikasiSistem>(
  (ref) => NotifikasiSistemPerangkat(),
);
