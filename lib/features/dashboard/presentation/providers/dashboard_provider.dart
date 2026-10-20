import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/role_session.dart';

/// Provider untuk menyimpan index tab dashboard yang sedang aktif.
/// Bisa diubah dari mana saja untuk navigasi ke tab tertentu.
///
/// Mengikuti peran sesi: setiap login atau logout provider dibuat ulang, jadi
/// tab kembali ke Beranda dan tidak mewarisi tab terakhir sesi sebelumnya.
final dashboardTabProvider = StateProvider<int>((ref) {
  ref.watch(roleSessionProvider.select((session) => session.role));
  return 0;
});
