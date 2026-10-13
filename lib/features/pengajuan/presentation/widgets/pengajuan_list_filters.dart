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

  void _openYearFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _YearFilterSheet(),
    );
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
              onPressed: _openYearFilterSheet,
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
        if (query.year != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.slate500,
                  ),
                  const SizedBox(width: 6),
                  Text.rich(
                    TextSpan(
                      text: 'Periode: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: '${query.year}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMain,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _openYearFilterSheet,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Ubah',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _YearFilterSheet extends ConsumerStatefulWidget {
  const _YearFilterSheet();

  @override
  ConsumerState<_YearFilterSheet> createState() => _YearFilterSheetState();
}

class _YearFilterSheetState extends ConsumerState<_YearFilterSheet>
    with SingleTickerProviderStateMixin {
  int? _tempYear;
  bool _isDropdownOpen = true;
  late final TextEditingController _searchController;
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late final Animation<double> _chevronTurns;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempYear = ref.read(pengajuanListQueryProvider).year;
    _searchController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 280),
      value: _isDropdownOpen ? 1.0 : 0.0,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_controller.status == AnimationStatus.forward ||
        (_controller.value > 0.0 &&
            _controller.status != AnimationStatus.reverse)) {
      setState(() => _isDropdownOpen = false);
      _controller.reverse();
    } else {
      setState(() => _isDropdownOpen = true);
      _controller.forward();
    }
  }

  void _selectYear(int? year) {
    setState(() {
      _tempYear = year;
    });
  }

  void _resetFilter() {
    setState(() {
      _tempYear = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _applyFilter() {
    ref.read(pengajuanListQueryProvider.notifier).year(_tempYear);
    Navigator.of(context).pop();
  }

  Widget _buildYearOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: isSelected ? AppColors.primarySurface : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.primaryRed : AppColors.slate700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primaryRed,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years =
        ref
            .watch(pengajuanListProvider)
            .map(pengajuanYear)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final filteredYears = years.where((y) {
      if (_searchQuery.isEmpty) return true;
      return '$y'.contains(_searchQuery) ||
          'tahun $y'.toLowerCase().contains(_searchQuery);
    }).toList();

    final bool showSemuaTahun = _searchQuery.isEmpty ||
        'semua tahun'.contains(_searchQuery) ||
        'semua'.contains(_searchQuery);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Centered Drag Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header: Judul, Subtitle, & Tombol X
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Tahun',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih tahun pengajuan yang ingin ditampilkan.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup filter',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.slate600,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerLine,
              ),

              // 3. Input Section: Periode Pengajuan & Compact Dropdown Picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PERIODE PENGAJUAN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown Trigger Button
                    InkWell(
                      onTap: _toggleDropdown,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedBuilder(
                        animation: _curve,
                        builder: (context, child) {
                          return Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                AppColors.slate50,
                                Colors.white,
                                _curve.value,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color.lerp(
                                  AppColors.borderSubtle,
                                  AppColors.primaryRed,
                                  _curve.value,
                                )!,
                                width: 1.0 + (0.5 * _curve.value),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.slate500,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _tempYear == null
                                    ? 'Semua Tahun'
                                    : 'Tahun $_tempYear',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            RotationTransition(
                              turns: _chevronTurns,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expandable Dropdown Menu with Fluid Size & Fade Transition
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        if (_controller.isDismissed) {
                          return const SizedBox.shrink();
                        }
                        return ClipRect(
                          child: SizeTransition(
                            sizeFactor: _curve,
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FadeTransition(
                                opacity: _curve,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search box inside dropdown
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.slate50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.dividerLine,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                  });
                                },
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMain,
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppColors.slate400,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  hintText: 'Cari tahun...',
                                  hintStyle: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.slate400,
                                    fontSize: 12,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Scrollable Options List (max-height: 192dp)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 192),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: [
                                  if (showSemuaTahun)
                                    _buildYearOption(
                                      label: 'Semua Tahun',
                                      isSelected: _tempYear == null,
                                      onTap: () => _selectYear(null),
                                    ),
                                  for (final year in filteredYears) ...[
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors.dividerLine,
                                    ),
                                    _buildYearOption(
                                      label: 'Tahun $year',
                                      isSelected: _tempYear == year,
                                      onTap: () => _selectYear(year),
                                    ),
                                  ],
                                  if (!showSemuaTahun && filteredYears.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Tahun tidak ditemukan',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.slate400,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerLine,
              ),

              // 4. Footer Actions (Reset & Terapkan Filter)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: [
                    // Secondary: Reset Button
                    OutlinedButton.icon(
                      onPressed: _resetFilter,
                      icon: const Icon(
                        Icons.rotate_left_rounded,
                        size: 18,
                        color: AppColors.slate500,
                      ),
                      label: Text(
                        'Reset',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(90, 48),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Primary: Terapkan Filter Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _applyFilter,
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Terapkan Filter',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shadowColor: AppColors.primaryRed.withValues(alpha: 0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
