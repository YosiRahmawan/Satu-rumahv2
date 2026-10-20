import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../../../pengajuan/presentation/widgets/survey_not_found_illustration.dart';
import '../providers/monitoring_list_provider.dart';

class MonitoringListScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;

  /// Bila diisi, header menampilkan tombol kembali (halaman dibuka sebagai
  /// rute sendiri, bukan sebagai tab).
  final VoidCallback? onBack;

  const MonitoringListScreen({
    super.key,
    this.showBottomNav = true,
    this.onBack,
  });

  @override
  ConsumerState<MonitoringListScreen> createState() =>
      _MonitoringListScreenState();
}

enum _HistoryFilter { all, draf, sesuai, perluEvaluasi }

const _filterLabels = {
  _HistoryFilter.all: 'Semua',
  _HistoryFilter.draf: 'Draf',
  _HistoryFilter.sesuai: 'Sesuai',
  _HistoryFilter.perluEvaluasi: 'Perlu evaluasi',
};

const _searchBandHeight = 112.0;

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DeveloperHeader(
              showBrandBar: false,
              pageTitle: 'Riwayat Survey & BA',
              pageSubtitle: '${allMonitoring.length} laporan',
              bottomPadding: AppSpacing.xl,
              onBack: widget.onBack,
            ),
          ),
          ...monitoringAsync.when(
            loading: () => [_fillState(_buildLoadingState())],
            error: (error, stackTrace) => [_fillState(_buildErrorState())],
            data: _buildHistorySlivers,
          ),
        ],
      ),
    );
  }

  Widget _fillState(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryRed),
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
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Riwayat survey belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.enterpriseTextMain,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coba muat ulang data untuk melihat laporan yang tersedia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(monitoringListAsyncProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Coba lagi',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHistorySlivers(List<MonitoringModel> allItems) {
    final filteredItems = _filterItems(allItems);

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _SearchBandDelegate(
          builder: (context, pinned) => _buildSearchBand(pinned),
        ),
      ),
      if (filteredItems.isEmpty)
        _fillState(_buildEmptyState())
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                _buildReportCard(filteredItems[index]),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
    ];
  }

  Widget _buildSearchBand(bool pinned) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.enterpriseCanvas,
        border: Border(
          bottom: BorderSide(
            color: pinned ? AppColors.enterpriseBorder : Colors.transparent,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: AppSpacing.sm),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.enterpriseTextMain,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari perumahan atau pengembang',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: AppColors.cardSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          border: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: BorderSide(color: AppColors.enterpriseBorder),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: BorderSide(color: AppColors.enterpriseBorder),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadii.control,
            borderSide: BorderSide(color: AppColors.primaryRed),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = _filterLabels.keys.elementAt(index);
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            label: Text(
              _filterLabels[filter]!,
              style: AppTextStyles.labelLarge.copyWith(
                color: selected
                    ? AppColors.textOnRed
                    : AppColors.enterpriseTextMain,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selectedColor: AppColors.primaryRed,
            backgroundColor: AppColors.cardSurface,
            side: BorderSide(
              color: selected
                  ? AppColors.primaryRed
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
    final query = _searchQuery.trim();
    final hasQuery = query.isNotEmpty;
    final hasFilter = _selectedFilter != _HistoryFilter.all;

    final String title;
    final String description;
    final String? actionLabel;
    final IconData? actionIcon;
    final VoidCallback? onReset;

    if (hasQuery && hasFilter) {
      // Kondisi 4: Kombinasi pencarian dan filter tidak menemukan hasil
      title = 'Tidak ada laporan yang sesuai filter';
      description =
          'Tidak ada laporan dengan kata kunci "$query" dan status "${_filterLabels[_selectedFilter]}".';
      actionLabel = 'Reset Pencarian & Filter';
      actionIcon = Icons.refresh_rounded;
      onReset = () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _selectedFilter = _HistoryFilter.all;
        });
      };
    } else if (hasQuery) {
      // Kondisi 2: Pencarian tidak menemukan hasil
      title = 'Laporan tidak ditemukan';
      description =
          'Tidak ada laporan yang sesuai dengan kata kunci "$query". Periksa kembali ejaan Anda.';
      actionLabel = 'Hapus Pencarian';
      actionIcon = Icons.close_rounded;
      onReset = () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      };
    } else if (hasFilter) {
      // Kondisi 3: Filter status tidak menemukan hasil
      title = 'Tidak ada laporan dengan status ini';
      description =
          'Tidak ada laporan survey dengan status "${_filterLabels[_selectedFilter]}". Coba pilih status filter lainnya.';
      actionLabel = 'Reset Filter';
      actionIcon = Icons.refresh_rounded;
      onReset = () {
        setState(() => _selectedFilter = _HistoryFilter.all);
      };
    } else {
      // Kondisi 1: Belum ada laporan
      title = 'Belum ada laporan survey';
      description =
          'Laporan hasil survey dan berita acara akan tampil di sini setelah survey dicatat.';
      actionLabel = null;
      actionIcon = null;
      onReset = null;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SurveyNotFoundIllustration(width: 150, height: 118),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.enterpriseTextMain,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onReset != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.enterpriseTextMain,
                  side: const BorderSide(
                    color: AppColors.enterpriseBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  backgroundColor: AppColors.cardSurface,
                  elevation: 0,
                ),
                icon: Icon(
                  actionIcon ?? Icons.refresh_rounded,
                  size: 16,
                  color: AppColors.enterpriseTextMain,
                ),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.enterpriseTextMain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(MonitoringModel item) {
    final date = DateFormat('d MMM yyyy', 'id').format(item.tanggalMonitoring);
    final nomorBA = item.nomorSuratBA.trim().isNotEmpty
        ? item.nomorSuratBA.trim()
        : MonitoringModel.generateNomorSuratBA(item.tanggalMonitoring);
    final meta = '$date · $nomorBA';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.enterpriseBorder),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: () => context.push(
            item.isDraft ? '/monitoring/draft' : '/monitoring/preview',
            extra: item.isDraft
                ? item
                : {'model': item, 'isDraft': item.isDraft},
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
                      child: Text(
                        item.namaPerumahan,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.enterpriseTextMain,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusPill(item: item),
                  ],
                ),
                if (item.namaDeveloper.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.namaDeveloper,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
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
    final filtered = items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.namaPerumahan.toLowerCase().contains(query) ||
          item.namaDeveloper.toLowerCase().contains(query) ||
          item.lokasiPerumahan.toLowerCase().contains(query);
      return matchesQuery && _matchesFilter(item, _selectedFilter);
    }).toList();
    filtered.sort((a, b) => b.tanggalMonitoring.compareTo(a.tanggalMonitoring));
    return filtered;
  }

  bool _matchesFilter(MonitoringModel item, _HistoryFilter filter) {
    switch (filter) {
      case _HistoryFilter.all:
        return true;
      case _HistoryFilter.draf:
        return item.isDraft;
      case _HistoryFilter.sesuai:
        return !item.isDraft &&
            item.statusHasilEvaluasi == StatusHasilEvaluasi.sesuaiSiteplan;
      case _HistoryFilter.perluEvaluasi:
        return !item.isDraft &&
            item.statusHasilEvaluasi != StatusHasilEvaluasi.sesuaiSiteplan;
    }
  }
}

/// Satu status per kartu: draf belum punya hasil evaluasi final.
class _StatusPill extends StatelessWidget {
  final MonitoringModel item;

  const _StatusPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = item.isDraft
        ? ('Draf', AppColors.enterpriseBorder, const Color(0xFF334155))
        : switch (item.statusHasilEvaluasi) {
            StatusHasilEvaluasi.sesuaiSiteplan => (
              'Sesuai',
              AppColors.enterpriseSuccessSurface,
              const Color(0xFF166534),
            ),
            StatusHasilEvaluasi.tidakSesuaiSiteplan => (
              'Tidak sesuai',
              AppColors.enterprisePrimarySurface,
              const Color(0xFF991B1B),
            ),
            StatusHasilEvaluasi.perluEvaluasiLanjutan => (
              'Perlu evaluasi',
              AppColors.enterpriseWarningSurface,
              const Color(0xFF92400E),
            ),
          };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 3,
        vertical: AppSpacing.xs - 1,
      ),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.pill),
      child: Text(
        label,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
        style: AppTextStyles.labelMedium.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchBandDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(BuildContext context, bool pinned) builder;

  const _SearchBandDelegate({required this.builder});

  @override
  double get minExtent => _searchBandHeight;

  @override
  double get maxExtent => _searchBandHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Skala teks dibatasi agar band yang menempel tidak membengkak.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      ),
      child: builder(context, overlapsContent),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBandDelegate oldDelegate) => true;
}
