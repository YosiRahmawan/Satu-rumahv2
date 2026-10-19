import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/role_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_role_theme.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badgeCount;

  const AppBottomNavigationItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badgeCount = 0,
  });
}

/// Shared navigation chrome. Destination lists remain role-specific.
class AppBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavigationItem> items;
  final bool _enterprise;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : _enterprise = false;

  /// Gaya Pengembang kanonik: ikon 22dp dalam pil lembut saat aktif, satu
  /// warna merah untuk semua peran.
  const AppBottomNavigation.enterprise({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : _enterprise = true;

  Widget _icon(
    AppBottomNavigationItem item, {
    required bool active,
    required Color badgeColor,
  }) {
    final icon = Icon(
      active ? (item.activeIcon ?? item.icon) : item.icon,
      size: 24,
    );
    if (item.badgeCount <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -9,
          top: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
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
    );
  }

  /// Canonical Pengembang item: 22dp icon in a soft pill when active.
  Widget _enterpriseItem(BuildContext context, int index) {
    final item = items[index];
    final active = index == currentIndex;
    final color = active ? AppColors.primaryRed : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: AppRadii.control,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFEF2F2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: _icon(
                  item,
                  active: active,
                  badgeColor: AppColors.notificationUnread,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.0),
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_enterprise) return _buildEnterprise(context);
    final currentRole = ref.watch(roleSessionProvider).role;
    final selectedColor = AppRoleTheme.getPrimaryColor(currentRole);

    return Container(
      decoration: const BoxDecoration(
        color: AppRoleTheme.navBackgroundColor,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: AppRoleTheme.unselectedNavColor,
          backgroundColor: AppRoleTheme.navBackgroundColor,
          elevation: 0,
          iconSize: 24,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: [
            for (final item in items)
              BottomNavigationBarItem(
                icon: _icon(item, active: false, badgeColor: selectedColor),
                activeIcon: _icon(
                  item,
                  active: true,
                  badgeColor: selectedColor,
                ),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterprise(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: const Border(
          top: BorderSide(color: AppColors.enterpriseBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                _enterpriseItem(context, i),
            ],
          ),
        ),
      ),
    );
  }
}
