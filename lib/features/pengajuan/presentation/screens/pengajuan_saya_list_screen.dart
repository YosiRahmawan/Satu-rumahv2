import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_list_view_provider.dart';
import '../widgets/pengajuan_list_card.dart';
import '../widgets/pengajuan_list_filters.dart';
import '../widgets/pengajuan_list_summary.dart';

/// The dashboard owns bottom navigation and the single central AJUKAN action.
class PengajuanSayaListScreen extends ConsumerWidget {
  const PengajuanSayaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pengajuanListProvider);
    final query = ref.watch(pengajuanListQueryProvider);
    final filtered = ref.watch(filteredPengajuanProvider);
    final visible = filtered.take(query.limit).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: CustomScrollView(
        key: const PageStorageKey('developer-submissions'),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                DeveloperHeader(
                  pageTitle: 'Pengajuan',
                  badge: const StatusBadge(
                    status: 'Portal Pengembang',
                    showIcon: false,
                  ),
                  avatarLabel: 'PT',
                  showOnlineIndicator: true,
                  avatarTooltip: 'Buka profil',
                  onAvatarTap: () =>
                      ref.read(dashboardTabProvider.notifier).state = 3,
                  notificationCount: ref.watch(unreadCountProvider),
                  onNotificationTap: () =>
                      ref.read(dashboardTabProvider.notifier).state = 2,
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Transform.translate(
                      offset: const Offset(0, -AppSpacing.md),
                      child: PengajuanListSummary(items: items),
                    ),
                  ),
              ],
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(child: PengajuanListFilters()),
          ),
          if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: DataStateView.empty(
                  title: items.isEmpty
                      ? 'Belum ada pengajuan'
                      : 'Tidak ada pengajuan ditemukan',
                  message: items.isEmpty
                      ? 'Gunakan tombol AJUKAN untuk membuat pengajuan perumahan.'
                      : 'Coba kata kunci atau filter lain.',
                  actionLabel: items.isEmpty
                      ? null
                      : 'Reset pencarian dan filter',
                  onAction: items.isEmpty
                      ? null
                      : ref.read(pengajuanListQueryProvider.notifier).reset,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final item = visible[index];
                  final monthYear = pengajuanMonthYear(item);
                  final firstInGroup =
                      index == 0 ||
                      pengajuanMonthYear(visible[index - 1]) != monthYear;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (firstInGroup)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final groupItems = filtered
                                  .where(
                                    (e) => pengajuanMonthYear(e) == monthYear,
                                  )
                                  .toList();
                              final isAllCompleted =
                                  groupItems.isNotEmpty &&
                                  groupItems.every(
                                    (e) =>
                                        e.statusTahap ==
                                        StatusTahapPengajuan.selesai,
                                  );
                              final dotColor = isAllCompleted
                                  ? const Color(0xFF16A34A)
                                  : AppColors.primaryRed;
                              final countSuffix = isAllCompleted
                                  ? ' Permohonan Selesai'
                                  : ' Permohonan';

                              return Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            monthYear,
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                                  color: AppColors.slate700,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${groupItems.length}$countSuffix',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.slate500,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PengajuanListCard(
                          key: ValueKey(item.id),
                          item: item,
                          onOpen: () => context.push(
                            '/pengajuan/detail/${Uri.encodeComponent(item.id)}',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              110.0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (visible.length < filtered.length) ...[
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: ref
                            .read(pengajuanListQueryProvider.notifier)
                            .loadMore,
                        icon: const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: AppColors.slate700,
                        ),
                        label: Text(
                          'Muat Lebih Banyak',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Menampilkan ${visible.length} dari ${filtered.length} pengajuan terdaftar',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const PrototypeDataBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
