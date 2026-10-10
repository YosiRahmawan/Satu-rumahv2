import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/prototype_data_banner.dart';

enum ProfileHeroVariant { light, authority, enterpriseAuthority }

class ProfileStatData {
  final String value;
  final String label;
  final Color? color;

  const ProfileStatData(this.value, this.label, {this.color});
}

class ProfileAccountItem {
  final IconData icon;
  final String label;
  final String value;

  const ProfileAccountItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class ProfileAssignmentData {
  final String projectName;
  final String developerName;
  final String scheduleText;
  final String instructionText;

  const ProfileAssignmentData({
    required this.projectName,
    required this.developerName,
    required this.scheduleText,
    required this.instructionText,
  });
}

/// Shared profile composition for every role.
/// Role-specific data and actions are supplied by wrappers.
class RoleProfileView extends StatelessWidget {
  final String profileTitle;
  final String? heroOrganizationLabel;
  final String displayName;
  final String roleLabel;
  final String initials;
  final String? identifier;
  final ProfileHeroVariant heroVariant;
  final List<ProfileStatData> stats;
  final String? assignmentSectionTitle;
  final ProfileAssignmentData? assignment;
  final String assignmentEmptyText;
  final String accountSectionTitle;
  final List<ProfileAccountItem> accountItems;
  final List<ProfileMenuItem> menuItems;
  final VoidCallback onLogout;
  final VoidCallback? onNotifications;
  final String logoutLabel;
  final String footerText;
  final Widget banner;

  const RoleProfileView({
    super.key,
    required this.profileTitle,
    required this.displayName,
    required this.roleLabel,
    required this.initials,
    required this.heroVariant,
    required this.accountItems,
    required this.menuItems,
    required this.onLogout,
    required this.footerText,
    this.identifier,
    this.heroOrganizationLabel,
    this.stats = const [],
    this.assignmentSectionTitle,
    this.assignment,
    this.assignmentEmptyText = 'Belum ada penugasan lapangan aktif.',
    this.accountSectionTitle = 'Data akun',
    this.onNotifications,
    this.logoutLabel = 'Keluar Akun',
    this.banner = const PrototypeDataBanner(),
  });

  bool get _isAuthority => heroVariant != ProfileHeroVariant.light;
  bool get _isEnterpriseAuthority =>
      heroVariant == ProfileHeroVariant.enterpriseAuthority;

  Color get _canvasColor => _isEnterpriseAuthority
      ? AppColors.enterpriseCanvas
      : AppColors.background;
  Color get _surfaceColor =>
      _isEnterpriseAuthority ? AppColors.enterpriseSurface : AppColors.surface;
  Color get _borderColor => _isEnterpriseAuthority
      ? AppColors.enterpriseBorder
      : AppColors.borderSubtle;
  Color get _textColor => _isEnterpriseAuthority
      ? AppColors.enterpriseTextMain
      : AppColors.textPrimary;
  Color get _mutedTextColor => _isEnterpriseAuthority
      ? AppColors.enterpriseTextMuted
      : AppColors.textMuted;
  Color get _primaryColor => _isEnterpriseAuthority
      ? AppColors.enterprisePrimary
      : AppColors.actionPrimary;

  TextStyle _style(
    TextStyle style, {
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    return style.copyWith(
      fontFamily: _isEnterpriseAuthority
          ? AppTextStyles.enterpriseFontFamily
          : style.fontFamily,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStats = stats.isNotEmpty;

    return Scaffold(
      backgroundColor: _canvasColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isEnterpriseAuthority && hasStats) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHero(context),
                  Positioned(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    bottom: -60,
                    child: _buildStats(),
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ] else ...[
              _buildHero(context),
              if (hasStats) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildStats(),
              ],
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(
                _isEnterpriseAuthority ? AppSpacing.xl : AppSpacing.lg,
                _isEnterpriseAuthority ? 0 : AppSpacing.lg,
                _isEnterpriseAuthority ? AppSpacing.xl : AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  banner,
                  if (assignmentSectionTitle != null) ...[
                    SizedBox(
                      height: _isEnterpriseAuthority
                          ? AppSpacing.md
                          : AppSpacing.xl,
                    ),
                    if (!_isEnterpriseAuthority) ...[
                      _buildSectionHeader(assignmentSectionTitle!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildAssignmentPanel(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(accountSectionTitle),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPanel(
                    children: [
                      for (var i = 0; i < accountItems.length; i++) ...[
                        _buildAccountItem(accountItems[i]),
                        if (i < accountItems.length - 1)
                          Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: _borderColor,
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Pengaturan & bantuan'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPanel(
                    children: [
                      for (var i = 0; i < menuItems.length; i++) ...[
                        _buildMenuItem(menuItems[i]),
                        if (i < menuItems.length - 1)
                          Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: _borderColor,
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLogoutButton(),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      footerText,
                      textAlign: TextAlign.center,
                      style: _style(
                        AppTextStyles.labelSmall,
                        color: _mutedTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    if (_isEnterpriseAuthority) {
      return _buildEnterpriseHero(context);
    }

    final foreground = _isAuthority ? Colors.white : _textColor;
    final secondary = _isAuthority
        ? Colors.white.withValues(alpha: 0.76)
        : _mutedTextColor;
    final rolePillColor = _isAuthority
        ? Colors.white.withValues(alpha: 0.18)
        : _primaryColor.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: _isEnterpriseAuthority
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.enterprisePrimary,
                  AppColors.enterprisePrimaryDark,
                ],
              )
            : null,
        color: _isEnterpriseAuthority
            ? null
            : (_isAuthority ? AppColors.brandPrimary : _surfaceColor),
        borderRadius: AppRadii.hero,
        border: _isAuthority
            ? null
            : Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AKUN SAYA',
                style: _style(
                  AppTextStyles.labelSmall,
                  color: secondary,
                  fontWeight: FontWeight.bold,
                ).copyWith(letterSpacing: 1.2),
              ),
              if (onNotifications != null)
                IconButton(
                  onPressed: onNotifications,
                  tooltip: 'Buka notifikasi',
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isAuthority
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.surfaceWarm,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.bell,
                      color: foreground,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            profileTitle,
            style: _style(
              AppTextStyles.headlineLarge,
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: foreground, width: 2),
                  color: _isEnterpriseAuthority
                      ? AppColors.enterpriseSurface
                      : AppColors.champagneToast,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: _style(
                    AppTextStyles.titleLarge,
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      softWrap: true,
                      style: _style(
                        AppTextStyles.headlineMedium,
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (identifier != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        identifier!,
                        style: _style(
                          AppTextStyles.labelMedium,
                          color: secondary,
                        ).copyWith(fontFamily: 'monospace'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: rolePillColor,
                        borderRadius: AppRadii.control,
                      ),
                      child: Text(
                        roleLabel,
                        style: _style(
                          AppTextStyles.labelSmall,
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseHero(BuildContext context) {
    const foreground = Colors.white;
    final secondary = Colors.white.withValues(alpha: 0.78);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.enterprisePrimary,
            AppColors.enterprisePrimaryDark,
          ],
        ),
        borderRadius: AppRadii.hero,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (heroOrganizationLabel != null)
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.buildings,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            heroOrganizationLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _style(
                              AppTextStyles.labelSmall,
                              color: foreground,
                              fontWeight: FontWeight.bold,
                            ).copyWith(letterSpacing: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (onNotifications != null)
                IconButton(
                  onPressed: onNotifications,
                  tooltip: 'Buka notifikasi',
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.bell,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: _style(
                AppTextStyles.headlineMedium,
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayName,
            textAlign: TextAlign.center,
            softWrap: true,
            style: _style(
              AppTextStyles.headlineMedium,
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (identifier != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              identifier!,
              textAlign: TextAlign.center,
              style: _style(AppTextStyles.labelMedium, color: secondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: AppRadii.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  PhosphorIconsRegular.identificationBadge,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  roleLabel,
                  style: _style(
                    AppTextStyles.labelSmall,
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.enterpriseTextMain.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              Expanded(child: _buildStatCard(stats[i])),
              if (i < stats.length - 1)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: _borderColor,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ProfileStatData stat) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Text(
            stat.value,
            style: _style(
              AppTextStyles.headlineMedium,
              color: stat.color ?? _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: _style(
              AppTextStyles.labelSmall,
              color: _mutedTextColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentPanel() {
    final value = assignment;
    if (_isEnterpriseAuthority) {
      return _buildEnterpriseAssignmentPanel(value);
    }

    return _buildPanel(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: value == null
              ? Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: _mutedTextColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        assignmentEmptyText,
                        style: _style(
                          AppTextStyles.bodyMedium,
                          color: _mutedTextColor,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.projectName,
                      style: _style(
                        AppTextStyles.titleLarge,
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (value.developerName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value.developerName,
                        style: _style(
                          AppTextStyles.bodyMedium,
                          color: _mutedTextColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _assignmentLine(
                      Icons.calendar_today_outlined,
                      value.scheduleText,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _assignmentLine(
                      Icons.notes_outlined,
                      value.instructionText,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEnterpriseAssignmentPanel(ProfileAssignmentData? value) {
    return _buildPanel(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: AppRadii.tight,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (assignmentSectionTitle ?? 'Penugasan Lapangan')
                                .toUpperCase(),
                            style: _style(
                              AppTextStyles.labelSmall,
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ).copyWith(letterSpacing: 0.35),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (value == null)
                      Text(
                        assignmentEmptyText,
                        style: _style(
                          AppTextStyles.bodyMedium,
                          color: _mutedTextColor,
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              value.projectName,
                              softWrap: true,
                              style: _style(
                                AppTextStyles.titleMedium,
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              PhosphorIconsRegular.paperPlaneTilt,
                              color: _primaryColor,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assignmentLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: _style(AppTextStyles.bodyMedium, color: _textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    if (_isEnterpriseAuthority) {
      return Text(
        title.toUpperCase(),
        style: _style(
          AppTextStyles.labelMedium,
          color: _textColor,
          fontWeight: FontWeight.bold,
        ).copyWith(letterSpacing: 0.35),
      );
    }

    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: AppRadii.tight,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            softWrap: true,
            style: _style(
              AppTextStyles.titleMedium,
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: _borderColor),
        boxShadow: _isEnterpriseAuthority
            ? [
                BoxShadow(
                  color: AppColors.enterpriseTextMain.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAccountItem(ProfileAccountItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: _isEnterpriseAuthority ? 40 : null,
            height: _isEnterpriseAuthority ? 40 : null,
            padding: _isEnterpriseAuthority
                ? EdgeInsets.zero
                : const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _isEnterpriseAuthority
                  ? AppColors.enterprisePrimarySurface
                  : _primaryColor.withValues(alpha: 0.08),
              borderRadius: AppRadii.control,
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: _primaryColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: _style(
                    AppTextStyles.labelSmall,
                    color: _mutedTextColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.value,
                  maxLines: _isEnterpriseAuthority ? 3 : 2,
                  overflow: _isEnterpriseAuthority
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: _style(
                    AppTextStyles.titleSmall,
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(ProfileMenuItem item) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: _isEnterpriseAuthority ? 40 : null,
          height: _isEnterpriseAuthority ? 40 : null,
          padding: _isEnterpriseAuthority
              ? EdgeInsets.zero
              : const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: _isEnterpriseAuthority
                ? AppColors.enterprisePrimarySurface
                : AppColors.surfaceSubtle,
            borderRadius: AppRadii.control,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, color: _primaryColor, size: 18),
        ),
        title: Text(
          item.title,
          softWrap: true,
          style: _style(
            AppTextStyles.titleMedium,
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          PhosphorIconsRegular.caretRight,
          color: _mutedTextColor,
          size: 18,
        ),
        onTap: item.onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    if (_isEnterpriseAuthority) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onLogout,
          style: FilledButton.styleFrom(
            foregroundColor: _primaryColor,
            backgroundColor: AppColors.enterprisePrimarySurface,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
          ),
          icon: const Icon(PhosphorIconsRegular.signOut, size: 18),
          label: Text(
            logoutLabel,
            style: _style(
              AppTextStyles.labelLarge,
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: BorderSide(color: _primaryColor, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
        ),
        icon: const Icon(PhosphorIconsRegular.signOut, size: 18),
        label: Text(
          logoutLabel,
          style: _style(
            AppTextStyles.labelLarge,
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
