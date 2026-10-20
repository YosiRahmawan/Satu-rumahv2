import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../notifikasi/presentation/screens/notifikasi_list_screen.dart';
import '../providers/monitoring_list_provider.dart';
import '../widgets/kamera_flow.dart';
import '../widgets/tab_beranda_monitoring.dart';
import '../widgets/tab_profil_monitoring.dart';
import 'monitoring_list_screen.dart';

class MonitoringMainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  final VoidCallback? onCameraPressed;

  const MonitoringMainScreen({
    super.key,
    this.initialIndex = 0,
    this.onCameraPressed,
  });

  @override
  ConsumerState<MonitoringMainScreen> createState() =>
      _MonitoringMainScreenState();
}

class _MonitoringMainScreenState extends ConsumerState<MonitoringMainScreen> {
  late int _currentIndex;
  final Set<int> _builtTabs = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _builtTabs.add(_currentIndex);
    // Selaraskan provider dengan tab awal dari rute, di luar fase build.
    Future.microtask(() {
      if (mounted) {
        ref.read(monitoringTabProvider.notifier).state = _currentIndex;
      }
    });
  }

  @override
  void didUpdateWidget(covariant MonitoringMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      _currentIndex = widget.initialIndex;
      _builtTabs.add(_currentIndex);
    }
  }

  void _onTabSelected(int index) {
    ref.read(monitoringTabProvider.notifier).state = index;
    setState(() {
      _currentIndex = index;
      _builtTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotifikasiCountProvider);
    final fabSize = MediaQuery.textScalerOf(
      context,
    ).scale(40).clamp(62.0, 96.0);

    const pages = [
      TabBerandaMonitoring(),
      MonitoringListScreen(showBottomNav: false),
      NotifikasiListScreen(),
      TabProfilMonitoring(),
    ];

    // Layar lain (mis. "Kembali ke Beranda") mengubah tab lewat provider.
    ref.listen<int>(monitoringTabProvider, (previous, next) {
      if (next != _currentIndex && next >= 0 && next < pages.length) {
        setState(() {
          _currentIndex = next;
          _builtTabs.add(next);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < pages.length; i++)
            _builtTabs.contains(i) ? pages[i] : const SizedBox.shrink(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: fabSize,
        height: fabSize,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x38B91C1C),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'perwaskim_camera_fab',
            elevation: 2,
            backgroundColor: AppColors.primaryRed,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.cardSurface, width: 3),
            ),
            tooltip: 'Kamera Lapangan',
            onPressed:
                widget.onCameraPressed ??
                () => openKameraLapangan(context, ref),
            child: const Icon(
              Icons.photo_camera_rounded,
              color: AppColors.textOnRed,
              size: 28,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.cardSurface,
          elevation: 10,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          padding: EdgeInsets.zero,
          height: 64.0,
          child: Row(
            children: [
              // Sisi Kiri: Beranda & Riwayat
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      context: context,
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      isActive: _currentIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Riwayat',
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment_rounded,
                      isActive: _currentIndex == 1,
                      onTap: () => _onTabSelected(1),
                    ),
                  ],
                ),
              ),

              // Ruang tengah untuk Docked FAB
              SizedBox(width: fabSize + 10),

              // Sisi Kanan: Notifikasi & Profil
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      context: context,
                      label: 'Notifikasi',
                      icon: Icons.notifications_none_rounded,
                      activeIcon: Icons.notifications_rounded,
                      isActive: _currentIndex == 2,
                      badgeCount: unreadCount,
                      onTap: () => _onTabSelected(2),
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Profil',
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      isActive: _currentIndex == 3,
                      onTap: () => _onTabSelected(3),
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
    required BuildContext context,
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
        borderRadius: AppRadii.control,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFEF2F2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.notificationUnread,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.cardSurface,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.0),
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
