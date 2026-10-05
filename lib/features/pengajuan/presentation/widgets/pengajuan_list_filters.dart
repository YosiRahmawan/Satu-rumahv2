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
                  hintText: 'Cari perumahan atau no. registrasi…',
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
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.control,
                ),
              ),
              icon: Badge(
                isLabelVisible: query.year != null,
                label: const Text('1'),
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
              for (final filter in PengajuanFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      '${filter.label} (${items.where(filter.matches).length})',
                    ),
                    selected: query.filter == filter,
                    onSelected: (_) => notifier.filter(filter),
                    showCheckmark: false,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: AppColors.cardSurface,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: query.filter == filter
                          ? AppColors.textOnRed
                          : AppColors.textSecondary,
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
