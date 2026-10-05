import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_list_view_provider.dart';
import '../widgets/pengajuan_list_card.dart';
import '../widgets/pengajuan_list_filters.dart';
import '../widgets/pengajuan_list_header.dart';
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
    final groupCounts = <int?, int>{};
    for (final item in filtered) {
      final year = pengajuanYear(item);
      groupCounts[year] = (groupCounts[year] ?? 0) + 1;
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: CustomScrollView(
        key: const PageStorageKey('developer-submissions'),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const PengajuanListHeader(),
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
                  final year = pengajuanYear(item);
                  final firstInGroup =
                      index == 0 || pengajuanYear(visible[index - 1]) != year;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (firstInGroup)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Builder(
                            builder: (context) {
                              final groupItems = filtered
                                  .where((e) => pengajuanYear(e) == year)
                                  .toList();
                              final isAllCompleted =
                                  groupItems.isNotEmpty &&
                                  groupItems.every(
                                    (e) =>
                                        e.statusTahap ==
                                        StatusTahapPengajuan.selesai,
                                  );
                              final hasDecember = groupItems.every(
                                (e) => e.tanggal.toLowerCase().contains('des'),
                              );
                              final groupTitle = year == null
                                  ? 'TANGGAL BELUM TERSEDIA'
                                  : (isAllCompleted && hasDecember
                                      ? 'DESEMBER $year'
                                      : 'TAHUN $year');
                              final dotColor = isAllCompleted
                                  ? AppColors.statusSuccessText
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        groupTitle,
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${groupCounts[year]}$countSuffix',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl * 2,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (visible.length < filtered.length)
                    OutlinedButton.icon(
                      onPressed: ref
                          .read(pengajuanListQueryProvider.notifier)
                          .loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Muat Lebih Banyak'),
                    ),
                  Text(
                    'Menampilkan ${visible.length} dari ${filtered.length} pengajuan perumahan',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
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
