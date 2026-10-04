import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'tab_beranda.dart';
import '../../../pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';
import '../../../notifikasi/presentation/screens/notifikasi_list_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardTabProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    const tabs = [
      TabBeranda(),
      PengajuanSayaListScreen(),
      NotifikasiListScreen(),
      ProfilScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: currentIndex, children: tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 62,
        height: 62,
        margin: const EdgeInsets.only(top: 14),
        child: FloatingActionButton(
          elevation: 4,
          backgroundColor: AppColors.primaryRed,
          shape: const CircleBorder(),
          onPressed: () {
            ref.read(pengajuanFormProvider.notifier).reset();
            context.push('/pengajuan/step1');
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(height: 1),
              Text(
                'AJUKAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          elevation: 10,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          padding: EdgeInsets.zero,
          height: 64,
          child: Row(
            children: [
              // Sisi Kiri: Beranda & Pengajuan
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      isActive: currentIndex == 0,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 0,
                    ),
                    _buildNavItem(
                      label: 'Pengajuan',
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment_rounded,
                      isActive: currentIndex == 1,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 1,
                    ),
                  ],
                ),
              ),

              // Ruang tengah untuk Docked FAB
              const SizedBox(width: 72),

              // Sisi Kanan: Notifikasi & Profil
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      label: 'Notifikasi',
                      icon: Icons.notifications_none_rounded,
                      activeIcon: Icons.notifications_rounded,
                      isActive: currentIndex == 2,
                      badgeCount: unreadCount,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 2,
                    ),
                    _buildNavItem(
                      label: 'Profil',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      isActive: currentIndex == 3,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final color = isActive ? AppColors.primaryRed : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
