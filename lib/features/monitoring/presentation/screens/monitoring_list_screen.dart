import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_list_provider.dart';
import '../widgets/status_hasil_evaluasi_badge_widget.dart';

class MonitoringListScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;

  const MonitoringListScreen({super.key, this.showBottomNav = true});

  @override
  ConsumerState<MonitoringListScreen> createState() =>
      _MonitoringListScreenState();
}

enum _HistoryFilter { all, sesuai, perluEvaluasi }

class _MonitoringListScreenState extends ConsumerState<MonitoringListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMonitoring = ref.watch(monitoringListProvider);
    final monitoringAsync = ref.watch(monitoringListAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppHeader(
        variant: AppHeaderVariant.authority,
        title: 'Riwayat Survey & BA',
        subtitle: 'Arsip resmi berita acara dan evaluasi lapangan',
        showAuthorityIcon: false,
        authorityGradient: true,
        uppercaseAuthoritySubtitle: false,
        height: 96,
        bottomRadius: AppRadii.hero,
        actions: [_buildArchiveCount(allMonitoring.length)],
      ),
      body: monitoringAsync.when(
        loading: _buildLoadingState,
        error: (error, stackTrace) => _buildErrorState(),
        data: _buildHistoryContent,
      ),
    );
  }

  Widget _buildArchiveCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$count Arsip',
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: AppTextStyles.enterpriseFontFamily,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.enterprisePrimary),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.enterpriseTextMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Riwayat survey belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: _text(
                AppTextStyles.titleMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coba muat ulang data untuk melihat laporan yang tersedia.',
              textAlign: TextAlign.center,
              style: _text(
                AppTextStyles.bodySmall,
                color: AppColors.enterpriseTextMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(monitoringListAsyncProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Coba lagi', style: _text(AppTextStyles.labelLarge)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent(List<MonitoringModel> allItems) {
    final filteredItems = _filterItems(allItems);
    final counts = _filterCounts(allItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: PrototypeDataBanner(),
        ),
        _buildSearchField(),
        _buildFilterChips(counts),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'DAFTAR LAPORAN TERVERIFIKASI',
                  style: _text(
                    AppTextStyles.labelMedium,
                    color: AppColors.enterpriseTextMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${filteredItems.length} laporan',
                style: _text(
                  AppTextStyles.bodySmall,
                  color: AppColors.enterpriseTextMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) =>
                      _buildReportCard(filteredItems[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: _text(AppTextStyles.bodyMedium),
        decoration: InputDecoration(
          hintText: 'Cari nama perumahan, pengembang...',
          hintStyle: _text(
            AppTextStyles.bodySmall,
            color: AppColors.enterpriseTextMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.enterpriseTextMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.enterpriseTextMuted,
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: AppColors.enterpriseSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: const BorderSide(color: AppColors.enterpriseBorder),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: const BorderSide(color: AppColors.enterpriseBorder),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: const BorderSide(color: AppColors.enterprisePrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Map<_HistoryFilter, int> counts) {
    final labels = {
      _HistoryFilter.all: 'Semua',
      _HistoryFilter.sesuai: 'Sesuai',
      _HistoryFilter.perluEvaluasi: 'Perlu Evaluasi',
    };

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = labels.keys.elementAt(index);
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(
              '${labels[filter]} (${counts[filter] ?? 0})',
              style: _text(
                AppTextStyles.labelMedium,
                color: selected ? Colors.white : AppColors.enterpriseTextMain,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selectedColor: AppColors.enterprisePrimary,
            backgroundColor: AppColors.enterpriseSurface,
            side: BorderSide(
              color: selected
                  ? AppColors.enterprisePrimary
                  : AppColors.enterpriseBorder,
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => setState(() => _selectedFilter = filter),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchQuery.trim().isNotEmpty || _selectedFilter != _HistoryFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.enterpriseTextMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilters
                  ? 'Tidak ada laporan yang sesuai filter.'
                  : 'Belum ada laporan survey.',
              textAlign: TextAlign.center,
              style: _text(
                AppTextStyles.titleMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? 'Coba ubah kata kunci atau status filter.'
                  : 'Laporan final akan tampil di sini.',
              textAlign: TextAlign.center,
              style: _text(
                AppTextStyles.bodySmall,
                color: AppColors.enterpriseTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(MonitoringModel item) {
    final date = DateFormat('d MMM yyyy').format(item.tanggalMonitoring);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: () => context.push(
            '/monitoring/preview',
            extra: {'model': item, 'isDraft': item.isDraft},
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.enterprisePrimarySurface,
                          borderRadius: AppRadii.small,
                        ),
                        child: Text(
                          item.nomorSuratBA,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            AppTextStyles.labelSmall,
                            color: AppColors.enterprisePrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: StatusHasilEvaluasiBadgeWidget(
                        status: item.statusHasilEvaluasi,
                        isCompact: true,
                        showIcon: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.namaPerumahan,
                  style: _text(
                    AppTextStyles.headlineSmall,
                    color: AppColors.enterpriseTextMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.namaDeveloper.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.namaDeveloper,
                    style: _text(
                      AppTextStyles.bodySmall,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
                ],
                if (item.lokasiPerumahan.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.lokasiPerumahan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      AppTextStyles.bodySmall,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.enterpriseBorder),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.enterpriseTextMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          date,
                          style: _text(
                            AppTextStyles.bodySmall,
                            color: AppColors.enterpriseTextMuted,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/monitoring/preview',
                        extra: {'model': item, 'isDraft': item.isDraft},
                      ),
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.enterprisePrimary,
                      ),
                      label: Text(
                        'Lihat Dokumen BA',
                        style: _text(
                          AppTextStyles.labelMedium,
                          color: AppColors.enterprisePrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MonitoringModel> _filterItems(List<MonitoringModel> items) {
    final query = _searchQuery.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.namaPerumahan.toLowerCase().contains(query) ||
          item.namaDeveloper.toLowerCase().contains(query) ||
          item.lokasiPerumahan.toLowerCase().contains(query);
      return matchesQuery && _matchesFilter(item, _selectedFilter);
    }).toList();
  }

  Map<_HistoryFilter, int> _filterCounts(List<MonitoringModel> items) {
    return {
      _HistoryFilter.all: items.length,
      _HistoryFilter.sesuai: items
          .where((item) => _matchesFilter(item, _HistoryFilter.sesuai))
          .length,
      _HistoryFilter.perluEvaluasi: items
          .where((item) => _matchesFilter(item, _HistoryFilter.perluEvaluasi))
          .length,
    };
  }

  bool _matchesFilter(MonitoringModel item, _HistoryFilter filter) {
    switch (filter) {
      case _HistoryFilter.all:
        return true;
      case _HistoryFilter.sesuai:
        return item.statusHasilEvaluasi == StatusHasilEvaluasi.sesuaiSiteplan;
      case _HistoryFilter.perluEvaluasi:
        return item.statusHasilEvaluasi != StatusHasilEvaluasi.sesuaiSiteplan;
    }
  }

  TextStyle _text(
    TextStyle base, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return base.copyWith(
      color: color ?? base.color,
      fontWeight: fontWeight ?? base.fontWeight,
      letterSpacing: letterSpacing ?? base.letterSpacing,
      fontFamily: AppTextStyles.enterpriseFontFamily,
    );
  }
}
