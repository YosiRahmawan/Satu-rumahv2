import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
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
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavigationItem> items;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? backgroundColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final double iconSize;
  final bool showTopBorder;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.backgroundColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.iconSize = 24.0,
    this.showTopBorder = false,
  });

  /// Factory constructor configured for Enterprise Figma styling
  const AppBottomNavigation.enterprise({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor = AppColors.enterprisePrimary,
    this.unselectedItemColor = AppColors.enterpriseTextMuted,
    this.backgroundColor = AppColors.enterpriseSurface,
    this.selectedLabelStyle = const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    this.unselectedLabelStyle = const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    this.iconSize = 24.0,
    this.showTopBorder = true,
  });

  Widget _icon(AppBottomNavigationItem item, {required bool active}) {
    final icon = Icon(
      active ? (item.activeIcon ?? item.icon) : item.icon,
      size: iconSize,
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
            decoration: const BoxDecoration(
              color: AppColors.notificationUnread,
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
                child: _icon(item, active: active),
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
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surface;
    final effectiveSelectedColor = selectedItemColor ?? AppColors.actionPrimary;
    final effectiveUnselectedColor = unselectedItemColor ?? AppColors.textMuted;

    final navBar = BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: effectiveSelectedColor,
      unselectedItemColor: effectiveUnselectedColor,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconSize: iconSize,
      selectedFontSize: selectedLabelStyle?.fontSize ?? 12,
      unselectedFontSize: unselectedLabelStyle?.fontSize ?? 12,
      selectedLabelStyle: selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      items: [
        for (final item in items)
          BottomNavigationBarItem(
            icon: _icon(item, active: false),
            activeIcon: _icon(item, active: true),
            label: item.label,
          ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: showTopBorder
            ? const Border(
                top: BorderSide(color: AppColors.enterpriseBorder, width: 1.0),
              )
            : null,
        boxShadow: showTopBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: showTopBorder
            ? SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _enterpriseItem(context, i),
                  ],
                ),
              )
            : navBar,
      ),
    );
  }
}
