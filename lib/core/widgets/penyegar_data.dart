import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/monitoring/data/repositories/officer_api_repository.dart';
import '../../features/monitoring/presentation/providers/monitoring_list_provider.dart';
import '../../features/notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../api/api_client.dart';
import '../auth/role_session.dart';

/// Menyegarkan data dari server tanpa menunggu pengguna: saat aplikasi dibuka kembali dari
/// latar belakang dan tiap [interval] selama aplikasi tampil. Belum ada push, jadi tanpa ini
/// notifikasi, badge, tugas petugas, dan status pengajuan baru terlihat setelah pengguna
/// membuka layarnya atau masuk ulang. Diam-diam: tidak memunculkan indikator memuat atau galat.
class PenyegarData extends ConsumerStatefulWidget {
  const PenyegarData({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 20),
    this.intervalLatar = const Duration(seconds: 60),
  });

  final Widget child;
  final Duration interval;

  /// Jarak pemeriksaan saat aplikasi di latar belakang (notifikasi sistem HP bergantung padanya).
  final Duration intervalLatar;

  @override
  ConsumerState<PenyegarData> createState() => _PenyegarDataState();
}

class _PenyegarDataState extends ConsumerState<PenyegarData>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start(widget.interval);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start(widget.interval);
      unawaited(segarkan());
    } else if (state == AppLifecycleState.paused) {
      // Di latar belakang tetap memeriksa pelan supaya notifikasi sistem HP bisa muncul; OS dapat
      // menghentikan proses kapan saja, jadi ini upaya terbaik, bukan push dari server.
      _start(widget.intervalLatar);
    } else if (state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  void _start(Duration jarak) {
    _timer?.cancel();
    _timer = Timer.periodic(jarak, (_) => unawaited(segarkan()));
  }

  /// Memuat ulang data milik role yang masuk. Aman dipanggil kapan saja.
  Future<void> segarkan() async {
    if (!ref.read(apiEnabledProvider)) return;
    final role = ref.read(roleSessionProvider).role;
    try {
      switch (role) {
        case AppRole.developer:
          await Future.wait([
            ref.read(notifikasiProvider.notifier).refresh(),
            ref.read(pengajuanListProvider.notifier).refresh(silent: true),
          ]);
        case AppRole.perwaskim:
          await Future.wait([
            ref.read(notifikasiProvider.notifier).refresh(),
            ref.read(officerAssignmentsProvider.notifier).refresh(silent: true),
            ref.read(officerReportsProvider.notifier).refresh(),
          ]);
        case AppRole.admin:
        case AppRole.guest:
          break;
      }
    } catch (_) {
      // Dicoba lagi pada putaran berikutnya.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
