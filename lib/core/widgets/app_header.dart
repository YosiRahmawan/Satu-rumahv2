import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/role_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/notifikasi/presentation/providers/notifikasi_provider.dart';

enum AppHeaderVariant { light, authority }

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final AppHeaderVariant variant;
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showNotifications;
  final List<Widget> actions;
  final bool showAuthorityIcon;
  final bool authorityGradient;
  final bool uppercaseAuthoritySubtitle;
  final double height;
  final BorderRadius? bottomRadius;

  const AppHeader({
    super.key,
    this.variant = AppHeaderVariant.light,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.showNotifications = true,
    this.actions = const [],
    this.showAuthorityIcon = true,
    this.authorityGradient = false,
    this.uppercaseAuthoritySubtitle = true,
    this.height = 70,
    this.bottomRadius,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  void _goToNotifications(BuildContext context, WidgetRef ref) {
    switch (ref.read(roleSessionProvider).role) {
      case AppRole.admin:
        context.go('/admin/notifikasi');
      case AppRole.developer:
        ref.read(dashboardTabProvider.notifier).state = 2;
        context.go('/dashboard');
      case AppRole.perwaskim:
        context.go('/monitoring/lapangan/notifikasi');
      case AppRole.guest:
        context.go('/login');
    }
  }

  void _goBack(BuildContext context, WidgetRef ref) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    switch (ref.read(roleSessionProvider).role) {
      case AppRole.admin:
        context.go('/admin');
      case AppRole.developer:
        context.go('/dashboard');
      case AppRole.perwaskim:
        context.go('/monitoring/lapangan');
      case AppRole.guest:
        context.go('/login');
    }
  }

  Widget _notificationAction(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
  ) {
    return Semantics(
      button: true,
      label: 'Buka notifikasi',
      child: IconButton(
        tooltip: 'Buka notifikasi',
        onPressed: () => _goToNotifications(context, ref),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              variant == AppHeaderVariant.authority
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_none,
              color: variant == AppHeaderVariant.authority
                  ? Colors.white
                  : AppColors.textPrimary,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.notificationUnread,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: variant == AppHeaderVariant.authority
                          ? AppColors.brandPrimary
                          : AppColors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotifikasiCountProvider);
    final authority = variant == AppHeaderVariant.authority;

    final radius = bottomRadius ?? BorderRadius.zero;
    final authorityDecoration = authorityGradient
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.enterprisePrimary,
                AppColors.enterprisePrimaryDark,
              ],
            ),
            borderRadius: radius,
          )
        : BoxDecoration(
            color: authority ? AppColors.brandPrimary : AppColors.surface,
            borderRadius: radius,
          );

    return Material(
      color: Colors.transparent,
      elevation: authority ? 0 : 0.5,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: authorityDecoration,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      onPressed: () => _goBack(context, ref),
                      tooltip: 'Kembali',
                      icon: Icon(
                        Icons.arrow_back,
                        color: authority ? Colors.white : AppColors.textPrimary,
                      ),
                    )
                  else if (authority && showAuthorityIcon)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: AppRadii.pill,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  if ((authority && showAuthorityIcon) || showBackButton)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            authority && uppercaseAuthoritySubtitle
                                ? subtitle!.toUpperCase()
                                : subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: authority
                                ? AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    letterSpacing: 0.2,
                                    fontFamily:
                                        AppTextStyles.enterpriseFontFamily,
                                  )
                                : AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                          ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: authority
                              ? AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily:
                                      AppTextStyles.enterpriseFontFamily,
                                )
                              : AppTextStyles.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                  if (showNotifications)
                    _notificationAction(context, ref, unreadCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
