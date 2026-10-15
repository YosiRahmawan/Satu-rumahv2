import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/dashboard/presentation/providers/dashboard_provider.dart';

void main() {
  test('tab dashboard kembali ke Beranda setiap login dan logout', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = container.read(roleSessionProvider.notifier);

    session.signIn(AppRole.developer, username: 'pt_tasik_indah');
    expect(container.read(dashboardTabProvider), 0);

    // Keluar saat berada di tab Notifikasi, lalu masuk lagi.
    container.read(dashboardTabProvider.notifier).state = 2;
    session.signOut();
    expect(container.read(dashboardTabProvider), 0);

    session.signIn(AppRole.developer, username: 'pt_tasik_indah');
    expect(container.read(dashboardTabProvider), 0);
  });

  test('tab tetap selama sesi yang sama berjalan', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.developer, username: 'pt_tasik_indah');

    container.read(dashboardTabProvider.notifier).state = 3;
    expect(container.read(dashboardTabProvider), 3);
  });
}
