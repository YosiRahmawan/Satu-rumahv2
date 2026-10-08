import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/pengajuan_form_controller.dart';
import '../providers/pengajuan_list_view_provider.dart';

class PengajuanListFilters extends ConsumerStatefulWidget {
  const PengajuanListFilters({super.key});

  @override
  ConsumerState<PengajuanListFilters> createState() =>
      _PengajuanListFiltersState();
}

class _PengajuanListFiltersState extends ConsumerState<PengajuanListFilters> {
  late final _search = TextEditingController(
    text: ref.read(pengajuanListQueryProvider).search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(pengajuanListQueryProvider);
    final items = ref.watch(pengajuanListProvider);
    final notifier = ref.read(pengajuanListQueryProvider.notifier);
    ref.listen(pengajuanListQueryProvider.select((value) => value.search), (
      _,
      next,
    ) {
      if (_search.text != next) _search.text = next;
    });
    final hasMenunggu = items.any(PengajuanFilter.menungguVerifikasi.matches) ||
        query.filter == PengajuanFilter.menungguVerifikasi;
    final displayFilters = [
      PengajuanFilter.semua,
      if (hasMenunggu) PengajuanFilter.menungguVerifikasi,
      PengajuanFilter.perbaikan,
      if (!hasMenunggu) PengajuanFilter.menungguVerifikasi,
      PengajuanFilter.proses,
      PengajuanFilter.selesai,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: notifier.search,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Cari nama perumahan atau registrasi...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => notifier.search(''),
                        ),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryRed,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.outlined(
              tooltip: 'Filter tahun',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _YearFilterSheet(),
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppColors.cardSurface,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Badge(
                isLabelVisible: true,
                label: Text(query.year != null ? '1' : '2'),
                backgroundColor: AppColors.primaryRed,
                child: const Icon(Icons.tune, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in displayFilters) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      filter == PengajuanFilter.semua
                          ? 'Semua (${items.length})'
                          : filter == PengajuanFilter.menungguVerifikasi
                          ? filter.label
                          : '${filter.label} (${items.where(filter.matches).length})',
                    ),
                    selected: query.filter == filter,
                    onSelected: (_) => notifier.filter(filter),
                    showCheckmark: false,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: AppColors.cardSurface,
                    side: BorderSide(
                      color: query.filter == filter
                          ? AppColors.primaryRed
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: query.filter == filter
                          ? AppColors.textOnRed
                          : AppColors.slate700,
                      fontWeight: query.filter == filter
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (hasMenunggu &&
                    filter == PengajuanFilter.menungguVerifikasi)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.swap_vert,
                        size: 16,
                        color: AppColors.slate700,
                      ),
                      label: Text(
                        query.sort.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: notifier.toggleSort,
                      backgroundColor: AppColors.cardSurface,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.pill,
                      ),
                    ),
                  ),
              ],
              if (!hasMenunggu)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.swap_vert,
                      size: 16,
                      color: AppColors.slate700,
                    ),
                    label: Text(
                      query.sort.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: notifier.toggleSort,
                    backgroundColor: AppColors.cardSurface,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (query.year != null)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('Tahun ${query.year}'),
              onDeleted: () => notifier.year(null),
            ),
          ),
      ],
    );
  }
}

class _YearFilterSheet extends ConsumerWidget {
  const _YearFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      pengajuanListQueryProvider.select((value) => value.year),
    );
    final years =
        ref
            .watch(pengajuanListProvider)
            .map(pengajuanYear)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter tahun', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final year in <int?>[null, ...years])
                  ChoiceChip(
                    label: Text(year == null ? 'Semua tahun' : '$year'),
                    selected: selected == year,
                    onSelected: (_) {
                      ref.read(pengajuanListQueryProvider.notifier).year(year);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
