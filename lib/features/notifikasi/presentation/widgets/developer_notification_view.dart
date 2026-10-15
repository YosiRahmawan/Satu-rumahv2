import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
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
    this.onAvatarTap,
    this.avatarLabel,
    this.showOnlineIndicator = false,
  });

  final List<NotifikasiModel> items;
  final int unreadCount;
  final bool unreadOnly;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onMarkAllRead;
  final ValueChanged<NotifikasiModel> onOpen;
  final VoidCallback? onAvatarTap;
  final String? avatarLabel;
  final bool showOnlineIndicator;

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
              child: DeveloperHeader(
                showBrandBar: false,
                showNotification: false,
                pageTitle: 'Notifikasi',
                pageSubtitle: 'Pantau perkembangan pengajuan Anda',
                avatarLabel: avatarLabel,
                showOnlineIndicator: showOnlineIndicator,
                avatarTooltip: 'Buka profil',
                onAvatarTap: onAvatarTap,
                bottomPadding: 20.0,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: SizedBox(
                        height: 0,
                        child: OverflowBox(
                          minHeight: 0,
                          maxHeight: 0,
                          alignment: Alignment.topLeft,
                          child: Text(
                            unreadCount > 0
                                ? '$unreadCount notifikasi belum dibaca'
                                : 'Semua notifikasi sudah dibaca',
                            style: const TextStyle(fontSize: 0, height: 0),
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final filterChips = Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _filter('Semua', false),
                            _filter(
                              unreadCount > 0
                                  ? 'Belum dibaca ($unreadCount)'
                                  : 'Belum dibaca',
                              true,
                            ),
                          ],
                        );

                        final markAllReadButton = TextButton.icon(
                          onPressed: unreadCount > 0 ? onMarkAllRead : null,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: Icon(
                            Icons.done_all_rounded,
                            size: 15,
                            color: unreadCount > 0
                                ? AppColors.primaryRed
                                : const Color(0xFF94A3B8),
                          ),
                          label: const Text('Tandai semua dibaca'),
                        );

                        return Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [filterChips, markAllReadButton],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey<bool>(unreadOnly),
                    child: items.isEmpty
                        ? DataStateView.empty(
                            title: unreadOnly
                                ? 'Tidak ada notifikasi belum dibaca'
                                : 'Belum ada notifikasi',
                            message: unreadOnly
                                ? 'Semua notifikasi sudah dibaca. Anda dapat melihatnya kembali di daftar semua notifikasi.'
                                : 'Informasi terkait pengajuan akan ditampilkan di sini.',
                            actionLabel: unreadOnly
                                ? 'Lihat semua notifikasi'
                                : null,
                            onAction: unreadOnly
                                ? () => onFilterChanged(false)
                                : null,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final item in items)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: DeveloperNotificationTile(
                                    key: ValueKey(item.id),
                                    item: item,
                                    onTap: () => onOpen(item),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
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
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryRed,
      side: selected
          ? BorderSide.none
          : const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : const Color(0xFF475569),
        height: 1.25,
      ),
    );
  }
}
