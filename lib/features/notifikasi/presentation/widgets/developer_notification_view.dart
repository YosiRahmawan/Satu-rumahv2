import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../data/models/notifikasi_model.dart';
import 'developer_notification_tile.dart';

/// Filter daftar notifikasi Pengembang.
enum NotifikasiFilter { semua, belumDibaca, perluRevisi }

/// Content of the existing Pengembang tab; navigation belongs to its dashboard.
class DeveloperNotificationView extends StatelessWidget {
  const DeveloperNotificationView({
    super.key,
    required this.items,
    required this.unreadCount,
    required this.filter,
    required this.onFilterChanged,
    this.activeRevisionIds = const {},
    required this.onMarkAllRead,
    required this.onOpen,
    this.onAvatarTap,
    this.avatarLabel,
    this.showOnlineIndicator = false,
  });

  final List<NotifikasiModel> items;
  final int unreadCount;
  final NotifikasiFilter filter;
  final ValueChanged<NotifikasiFilter> onFilterChanged;

  /// Id notifikasi revisi yang masih aktif (kartu dengan aksen perhatian).
  final Set<String> activeRevisionIds;
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
                bottomPadding: 24.0,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg + AppSpacing.xs,
                AppSpacing.sm,
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
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _filter('Semua', NotifikasiFilter.semua),
                        _filter(
                          unreadCount > 0
                              ? 'Belum dibaca ($unreadCount)'
                              : 'Belum dibaca',
                          NotifikasiFilter.belumDibaca,
                        ),
                        _filter('Perlu Revisi', NotifikasiFilter.perluRevisi),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: unreadCount > 0 ? onMarkAllRead : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: const Size(44, 44),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg + AppSpacing.xs,
              ),
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
                    key: ValueKey<NotifikasiFilter>(filter),
                    child: items.isEmpty
                        ? _emptyState()
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
                                    actionRequired: activeRevisionIds.contains(
                                      item.id,
                                    ),
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
                height: 96.0 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ilustrasi kosong yang sama untuk semua filter notifikasi.
  Widget _emptyIllustration() => SvgPicture.asset(
    'assets/images/notifikasi_unread_empty.svg',
    width: 180,
    height: 135,
    fit: BoxFit.contain,
  );

  Widget _emptyState() {
    switch (filter) {
      case NotifikasiFilter.belumDibaca:
        return DataStateView.empty(
          illustration: _emptyIllustration(),
          title: 'Tidak ada notifikasi belum dibaca',
          message:
              'Semua notifikasi sudah dibaca. Anda dapat melihatnya kembali di daftar semua notifikasi.',
          actionLabel: 'Lihat semua notifikasi',
          onAction: () => onFilterChanged(NotifikasiFilter.semua),
        );
      case NotifikasiFilter.perluRevisi:
        return DataStateView.empty(
          illustration: _emptyIllustration(),
          title: 'Tidak ada revisi aktif',
          message:
              'Pengajuan Anda belum memiliki permintaan perbaikan yang perlu ditindaklanjuti.',
          actionLabel: 'Lihat semua notifikasi',
          onAction: () => onFilterChanged(NotifikasiFilter.semua),
        );
      case NotifikasiFilter.semua:
        return DataStateView.empty(
          illustration: _emptyIllustration(),
          title: 'Belum ada notifikasi',
          message: 'Informasi terkait pengajuan akan ditampilkan di sini.',
        );
    }
  }

  Widget _filter(String label, NotifikasiFilter value) {
    final selected = filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onFilterChanged(value),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
