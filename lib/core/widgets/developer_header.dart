import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shared canonical Pengembang header component across Beranda, Pengajuan,
/// Notifikasi, and Profil.
///
/// Ensures strict visual consistency in:
/// - Brand red gradient ([AppColors.heroGradient])
/// - SATU RUMAH house icon and uppercase brand treatment
/// - Bottom corner radius ([AppRadii.hero])
/// - Standard padding and spacing tokens
/// - Accessible and responsive scaling up to 200% text scale
class DeveloperHeader extends StatelessWidget {
  const DeveloperHeader({
    super.key,
    this.pageTitle,
    this.pageSubtitle,
    this.badge,
    this.isVerified = false,
    this.showNotification = false,
    this.notificationCount,
    this.onNotificationTap,
    this.notificationTooltip,
    this.onAvatarTap,
    this.avatarLabel,
    this.avatarTooltip,
    this.showOnlineIndicator = false,
    this.showAvatar = true,
    this.onNotificationTap,
    this.notificationCount,
    this.notificationTooltip,
    this.actions = const [],
    this.bottomPadding,
    this.child,
  });

  /// Optional page title shown below the brand bar (e.g. 'Pengajuan', 'Notifikasi', 'Profil Pengembang').
  final String? pageTitle;

  /// Optional page subtitle shown below the page title.
  final String? pageSubtitle;

  /// Optional badge widget shown beside the page title (or wrapped on small/scaled screens).
  final Widget? badge;

  /// Whether to display the canonical 'Terverifikasi' badge beside the title.
  final bool isVerified;

  /// Whether to display the canonical notification icon in the header controls.
  final bool showNotification;

  /// Number of unread notifications to display on the badge.
  final int? notificationCount;

  /// Callback when the notification icon button is tapped.
  final VoidCallback? onNotificationTap;

  /// Accessibility tooltip for the notification icon button.
  final String? notificationTooltip;

  /// Callback when avatar is tapped.
  final VoidCallback? onAvatarTap;

  /// Avatar initials/text (e.g. 'YR', 'PT', 'TI'). If null, person outline icon is rendered.
  final String? avatarLabel;

  /// Accessibility tooltip for the avatar button.
  final String? avatarTooltip;

  /// Whether to show the green online indicator dot on the avatar.
  final bool showOnlineIndicator;

  /// Whether to display the avatar button in the top action controls.
  final bool showAvatar;

  /// Optional callback when the canonical notification bell icon is tapped.
  final VoidCallback? onNotificationTap;

  /// Optional unread notification count. When greater than 0, shows a warning badge.
  final int? notificationCount;

  /// Optional accessibility tooltip for the notification icon button.
  final String? notificationTooltip;

  /// Additional action buttons to show in the top right control row.
  final List<Widget> actions;

  /// Custom bottom padding for the header container. Defaults to [AppSpacing.xxl] (32dp).
  final double? bottomPadding;

  /// Optional extra widget placed at the bottom of the header.
  final Widget? child;

  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.18),
        borderRadius: AppRadii.pill,
        border: Border.all(
          color: AppColors.cardSurface.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsRegular.sealCheck,
            size: 14,
            color: AppColors.textOnRed,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Terverifikasi',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textOnRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationAction() {
    final hasUnread = (notificationCount ?? 0) > 0;
    return IconButton(
      tooltip: notificationTooltip ?? 'Buka notifikasi',
      onPressed: onNotificationTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Badge(
        isLabelVisible: hasUnread,
        backgroundColor: AppColors.statusWarningSurface,
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textOnRed,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildAvatarButton(double avatarSize) {
    return IconButton(
      tooltip: avatarTooltip ?? 'Buka profil',
      onPressed: onAvatarTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Stack(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
            ),
            child: avatarLabel == null
                ? const Icon(
                    Icons.person_outline,
                    color: AppColors.primaryRed,
                    size: 24,
                  )
                : Text(
                    avatarLabel!,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          if (showOnlineIndicator)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessText,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardSurface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.textOnRed.withValues(alpha: .16),
            borderRadius: AppRadii.control,
          ),
          child: const Icon(
            Icons.home_rounded,
            color: AppColors.textOnRed,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SATU RUMAH',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textOnRed,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                'PORTAL PENGEMBANG',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textOnRedSubtle,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final avatarSize = MediaQuery.textScalerOf(
      context,
    ).scale(22).clamp(44.0, 64.0);
    final shouldShowNotification =
        showNotification || onNotificationTap != null;
    final shouldShowAvatar =
        showAvatar && (onAvatarTap != null || avatarLabel != null);
    final shouldShowNotification = onNotificationTap != null;
    final hasControls =
        actions.isNotEmpty || shouldShowNotification || shouldShowAvatar;

    final Widget? notificationButton = shouldShowNotification
        ? IconButton(
            tooltip: notificationTooltip ?? 'Buka notifikasi',
            onPressed: onNotificationTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Badge(
              isLabelVisible: (notificationCount ?? 0) > 0,
              backgroundColor: AppColors.statusWarningSurface,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textOnRed,
                size: 24,
              ),
            ),
          )
        : null;

    final controls = hasControls
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notificationButton != null) notificationButton,
              ...actions,
              if (shouldShowAvatar) ...[
                if (notificationButton != null || actions.isNotEmpty)
                  const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: avatarTooltip,
                  onPressed: onAvatarTap,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Stack(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.cardSurface,
                          shape: BoxShape.circle,
                        ),
                        child: avatarLabel == null
                            ? const Icon(
                                Icons.person_outline,
                                color: AppColors.primaryRed,
                                size: 24,
                              )
                            : Text(
                                avatarLabel!,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      if (showOnlineIndicator)
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.statusSuccessText,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardSurface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          )
        : null;

    final isTextScaled = MediaQuery.textScalerOf(context).scale(14) > 20;
    final effectiveBadge =
        badge ?? (isVerified ? _buildVerificationBadge() : null);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg + AppSpacing.xs,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.lg + AppSpacing.xs,
        bottomPadding ?? AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Brand & Controls Row
          if (controls == null)
            brand
          else if (isTextScaled) ...[
            brand,
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerRight, child: controls),
          ] else
            Row(
              children: [
                Expanded(child: brand),
                const SizedBox(width: AppSpacing.sm),
                controls,
              ],
            ),

          // 2. Optional Page Title, Subtitle, & Badge Row
          if (pageTitle != null) ...[
            const SizedBox(height: AppSpacing.lg),
            if (effectiveBadge != null && isTextScaled) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pageTitle!,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textOnRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (pageSubtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      pageSubtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnRedSubtle,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  effectiveBadge,
                ],
              ),
            ] else if (effectiveBadge != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pageTitle!,
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.textOnRed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (pageSubtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            pageSubtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textOnRedSubtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  effectiveBadge,
                ],
              ),
            ] else ...[
              Text(
                pageTitle!,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textOnRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (pageSubtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pageSubtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnRedSubtle,
                  ),
                ),
              ],
            ],
          ],

          // 3. Optional Extra Child
          if (child != null) ...[const SizedBox(height: AppSpacing.md), child!],
        ],
      ),
    );
  }
}
