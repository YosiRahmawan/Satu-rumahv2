import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/dashboard_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'tab_beranda.dart';
import '../../../pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';
import '../../../notifikasi/presentation/screens/notifikasi_list_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Tab yang sudah pernah dibuka. Hanya tab ini yang dibangun dan
  /// dipertahankan, supaya frame pertama setelah login tidak berat.
  final Set<int> _builtTabs = {};

  /// Ilustrasi SVG yang dipakai halaman sukses, empty state, dan notifikasi.
  static const _illustrations = [
    'assets/images/pengajuan_sukses_saved.svg',
    'assets/images/pengajuan_empty_search.svg',
    'assets/images/pengajuan_empty_onboarding.svg',
    'assets/images/notifikasi_unread_empty.svg',
  ];

  @override
  void initState() {
    super.initState();
    // Setelah frame pertama, supaya tidak menunda tampilnya Beranda.
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheIllustrations());
  }

  /// Memuat dan mem-parse SVG lebih awal agar sudah ada di cache flutter_svg
  /// saat ilustrasinya ditampilkan, jadi tidak muncul tiba-tiba.
  Future<void> _precacheIllustrations() async {
    for (final asset in _illustrations) {
      try {
        await SvgAssetLoader(asset).loadBytes(null);
      } catch (_) {
        // Gagal precache tidak boleh mengganggu dashboard.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardTabProvider);
    _builtTabs.add(currentIndex);
    final unreadCount = ref.watch(unreadCountProvider);
    final fabSize = MediaQuery.textScalerOf(
      context,
    ).scale(40).clamp(62.0, 96.0);

    const tabs = [
      TabBeranda(),
      PengajuanSayaListScreen(),
      NotifikasiListScreen(),
      ProfilScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: IndexedStack(
        index: currentIndex,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _builtTabs.contains(i) ? tabs[i] : const SizedBox.shrink(),
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
            elevation: 2,
            backgroundColor: AppColors.primaryRed,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.cardSurface, width: 3),
            ),
            onPressed: () {
              ref.read(pengajuanFormProvider.notifier).reset();
              context.push('/pengajuan/step1');
            },
            child: const Icon(
              Icons.add_rounded,
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
              // Sisi Kiri: Beranda & Pengajuan
              Expanded(
                child: Row(
                  children: [
                    _buildNavItem(
                      context: context,
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      isActive: currentIndex == 0,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 0,
                    ),
                    _buildNavItem(
                      context: context,
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
                      isActive: currentIndex == 2,
                      badgeCount: unreadCount,
                      onTap: () =>
                          ref.read(dashboardTabProvider.notifier).state = 2,
                    ),
                    _buildNavItem(
                      context: context,
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
                    right: 0,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textOnRed,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
              textScaler: MediaQuery.textScalerOf(context).clamp(
                maxScaleFactor: 1.0,
              ),
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
