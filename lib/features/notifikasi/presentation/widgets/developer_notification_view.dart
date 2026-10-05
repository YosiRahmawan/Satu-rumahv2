import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../data/models/notifikasi_model.dart';
import 'developer_notification_tile.dart';

/// Content of the existing Pengembang tab; navigation belongs to its dashboard.
class DeveloperNotificationView extends StatelessWidget {
  const DeveloperNotificationView({
    super.key,
    required this.items,
    required this.unreadCount,
    required this.unreadOnly,
    required this.onFilterChanged,
    required this.onMarkAllRead,
    required this.onOpen,
  });

  final List<NotifikasiModel> items;
  final int unreadCount;
  final bool unreadOnly;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onMarkAllRead;
  final ValueChanged<NotifikasiModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('developer-notifications'),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg + AppSpacing.xs,
                  MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  AppSpacing.lg + AppSpacing.xs,
                  AppSpacing.xl,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: AppRadii.hero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.textOnRed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pantau informasi dan perkembangan pengajuan Anda',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnRedSubtle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        unreadCount > 0
                            ? '$unreadCount notifikasi belum dibaca'
                            : 'Semua notifikasi sudah dibaca',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textOnRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PrototypeDataBanner(),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _filter('Semua', false),
                        _filter('Belum dibaca', true),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: unreadCount > 0 ? onMarkAllRead : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          disabledForegroundColor: AppColors.textSecondary,
                          minimumSize: const Size(48, 48),
                          textStyle: AppTextStyles.labelMedium,
                        ),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Tandai semua dibaca'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: DataStateView.empty(
                    title: unreadOnly
                        ? 'Tidak ada notifikasi belum dibaca'
                        : 'Belum ada notifikasi',
                    message: unreadOnly
                        ? 'Semua notifikasi sudah dibaca. Anda dapat melihatnya kembali di daftar semua notifikasi.'
                        : 'Informasi terkait pengajuan akan ditampilkan di sini.',
                    actionLabel: unreadOnly ? 'Lihat semua notifikasi' : null,
                    onAction: unreadOnly ? () => onFilterChanged(false) : null,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DeveloperNotificationTile(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => onOpen(item),
                      ),
                    );
                  },
                ),
              ),
            // Keep the final item clear of the dashboard's docked FAB.
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filter(String label, bool value) {
    final selected = unreadOnly == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onFilterChanged(value),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: AppColors.cardSurface,
      selectedColor: AppColors.primarySurface,
      side: BorderSide(
        color: selected
            ? AppColors.primarySurfaceBorder
            : AppColors.borderSubtle,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: selected ? AppColors.primaryRed : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
