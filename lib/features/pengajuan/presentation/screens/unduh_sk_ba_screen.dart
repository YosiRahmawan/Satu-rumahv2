import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/app_housing_loader.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../monitoring/data/models/monitoring_model.dart';
import '../../../monitoring/presentation/providers/monitoring_form_provider.dart';
import '../../../monitoring/utils/ba_pdf_generator.dart';
import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import '../providers/pengajuan_form_controller.dart';
import 'pengajuan_detail_screen.dart';
import '../../../../core/widgets/app_illustration.dart';

/// Provider pengajuan lokal untuk layar Unduh SK & BA.
final unduhSkBaListProvider = FutureProvider.autoDispose<List<Pengajuan>>((
  ref,
) async {
  final list = ref.watch(pengajuanListProvider);
  await Future<void>.delayed(Duration.zero);
  return list;
});

/// Kategori filter dokumen
enum DocFilterCategory {
  semua('Semua'),
  sk('SK Persetujuan'),
  ba('Berita Acara');

  final String label;
  const DocFilterCategory(this.label);
}

/// Layar Unduh SK & BA untuk Pengembang — SATU RUMAH V2
/// Mengikuti spesifikasi visual Google Stitch & Design System:
/// - Sticky Header Merah Gradient dengan Back Button & Subtitle
/// - Search bar nama perumahan atau nomor registrasi
/// - Filter status dokumen horizontal (Semua, SK Persetujuan, Berita Acara)
/// - UI States: Loading (AppHousingLoader), Error, Empty State, Search Not Found, Data Cards
/// - Expandable Project Cards dengan status validitas dokumen riil
class UnduhSkBaScreen extends ConsumerStatefulWidget {
  const UnduhSkBaScreen({super.key, this.focusId});

  /// Pengajuan yang dibuka dan ditaruh paling atas (dari tombol Lihat SK).
  final String? focusId;

  @override
  ConsumerState<UnduhSkBaScreen> createState() => _UnduhSkBaScreenState();
}

class _UnduhSkBaScreenState extends ConsumerState<UnduhSkBaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  DocFilterCategory _selectedFilter = DocFilterCategory.semua;
  final Set<String> _expandedProjectIds = {};
  bool _hasInitializedExpandedState = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = DocFilterCategory.semua;
    });
  }

  void _toggleCardExpanded(String id) {
    setState(() {
      if (_expandedProjectIds.contains(id)) {
        _expandedProjectIds.remove(id);
      } else {
        _expandedProjectIds.add(id);
      }
    });
  }

  bool _hasValidSk(Pengajuan item) {
    if (item.statusTahap != StatusTahapPengajuan.selesai) return false;
    final path = item.skPersetujuanPath?.trim();
    if (path == null || path.isEmpty) return false;
    try {
      final file = File(path);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  MonitoringModel? _getValidBa(Pengajuan item) {
    final repo = ref.read(monitoringRepositoryProvider);
    return findLinkedFinalMonitoring(
      repo.getAllMonitoring(),
      item.id,
      beritaAcaraPath: item.beritaAcaraPath,
    );
  }

  int _countAvailableDocs(Pengajuan item) {
    int count = 0;
    if (_hasValidSk(item)) count++;
    if (_getValidBa(item) != null) count++;
    return count;
  }

  List<Pengajuan> _filterSubmissions(List<Pengajuan> submissions) {
    return submissions.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchName = item.namaPerumahan.toLowerCase().contains(query);
        final matchId = item.id.toLowerCase().contains(query);
        final matchPt = item.namaPt.toLowerCase().contains(query);
        if (!matchName && !matchId && !matchPt) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(unduhSkBaListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Sticky Header Merah Gradient ──
          _buildHeader(context),

          // ── Body Content ──
          Expanded(
            child: submissionsAsync.when(
              loading: () => const Center(child: AppHousingLoader.medium()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: DataStateView.error(
                    title: 'Gagal Memuat Dokumen',
                    message:
                        'Terjadi kendala saat memuat arsip dokumen. Silakan coba lagi.',
                    actionLabel: 'Coba Lagi',
                    onAction: () => ref.invalidate(unduhSkBaListProvider),
                  ),
                ),
              ),
              data: (allSubmissions) {
                if (!_hasInitializedExpandedState &&
                    allSubmissions.isNotEmpty) {
                  // Pengajuan yang dituju (dari Lihat SK) dibuka; bila tidak ada,
                  // card pertama dibuka agar pengguna langsung melihat contoh.
                  final focusId = widget.focusId;
                  final target = focusId == null
                      ? null
                      : allSubmissions.where((e) => e.id == focusId).toList();
                  _expandedProjectIds.add(
                    (target != null && target.isNotEmpty
                            ? target.first
                            : allSubmissions.first)
                        .id,
                  );
                  _hasInitializedExpandedState = true;
                }
                return _buildDataView(allSubmissions);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER (Sesuai Spesifikasi Jadwal Survey)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: 'Kembali',
            button: true,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  try {
                    context.go('/dashboard');
                  } catch (_) {}
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unduh SK & BA',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dokumen resmi pengajuan perumahan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DATA VIEW (SEARCH + FILTER + LIST / EMPTY)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDataView(List<Pengajuan> allSubmissions) {
    final filteredItems = _filterSubmissions(allSubmissions);
    final focusId = widget.focusId;
    if (focusId != null) {
      // Pengajuan yang dituju ditaruh paling atas agar langsung terlihat.
      filteredItems.sort(
        (a, b) => (a.id == focusId ? 0 : 1).compareTo(b.id == focusId ? 0 : 1),
      );
    }
    final bool isDatabaseEmpty = allSubmissions.isEmpty;
    final bool isFilteredEmpty = !isDatabaseEmpty && filteredItems.isEmpty;

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async {
        ref.invalidate(unduhSkBaListProvider);
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Search & Filter Controls ──
          if (!isDatabaseEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterPills(),
                  ],
                ),
              ),
            ),
          ],

          // ── Content State ──
          if (isDatabaseEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyDatabaseState(),
            )
          else if (isFilteredEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildSearchNotFoundState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < filteredItems.length) {
                      final item = filteredItems[index];
                      return Padding(
                        key: ValueKey('card_${item.id}'),
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildProjectCard(item),
                      );
                    }
                    // Item terakhir: Security & Guidance Callout
                    return Padding(
                      key: const ValueKey('security_callout'),
                      padding: EdgeInsets.zero,
                      child: _buildSecurityCallout(),
                    );
                  },
                  childCount: filteredItems.length + 1,
                  findChildIndexCallback: (Key key) {
                    if (key is ValueKey<String>) {
                      final keyVal = key.value;
                      if (keyVal.startsWith('card_')) {
                        final id = keyVal.substring(5);
                        final idx = filteredItems.indexWhere(
                          (it) => it.id == id,
                        );
                        return idx >= 0 ? idx : null;
                      } else if (keyVal == 'security_callout') {
                        return filteredItems.length;
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama perumahan atau registrasi...',
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTER PILLS (36dp Visual Height, 44dp Touch Target)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DocFilterCategory.values.map((category) {
          final isSelected = _selectedFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: category.label,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = category;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                mouseCursor: SystemMouseCursors.click,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: isSelected
                          ? const Color(0xFFB91C1C)
                          : Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0x00E2E8F0)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      child: Text(category.label),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PROJECT CARD WITH ACCORDION COLLAPSE / EXPAND
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildProjectCard(Pengajuan item) {
    final isExpanded = _expandedProjectIds.contains(item.id);
    final availableCount = _countAvailableDocs(item);
    final bool hasAvailableDocs = availableCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header Trigger ──
          InkWell(
            onTap: () => _toggleCardExpanded(item.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.id,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.namaPerumahan,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            if (item.namaPt.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.namaPt,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Chevron Rotate Indicator (180ms easeInOut)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.expand_more,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Availability Indicator & Location Chip
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasAvailableDocs
                              ? const Color(0xFFFFDAD6)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasAvailableDocs
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF64748B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$availableCount dari 2 Dokumen Tersedia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hasAvailableDocs
                                      ? const Color(0xFF93000B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.tipePerumahan.isNotEmpty)
                        Text(
                          item.tipePerumahan,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable Document Rows (Smooth AnimatedSize 200ms) ──
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? _buildDocumentsSection(item)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EXPANDABLE DOCUMENTS SECTION (SMOOTH FILTER TRANSITION)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDocumentsSection(Pengajuan item) {
    return Column(
      key: ValueKey('docs_section_${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren.map(
                        (child) =>
                            Positioned(top: 0, left: 0, right: 0, child: child),
                      ),
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey('filter_${_selectedFilter.name}_${item.id}'),
              child: _buildDocListForFilter(item),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocListForFilter(Pengajuan item) {
    final showSk =
        _selectedFilter == DocFilterCategory.semua ||
        _selectedFilter == DocFilterCategory.sk;
    final showBa =
        _selectedFilter == DocFilterCategory.semua ||
        _selectedFilter == DocFilterCategory.ba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row SK Persetujuan
        if (showSk) _buildSkDocumentRow(item),

        if (showSk && showBa) const SizedBox(height: 12),

        // Row Berita Acara
        if (showBa) _buildBaDocumentRow(item),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SK DOCUMENT ROW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSkDocumentRow(Pengajuan item) {
    final bool isAvailable = _hasValidSk(item);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFFFDAD6)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: isAvailable
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surat Keputusan (SK Persetujuan)',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? (item.nomorSk?.isNotEmpty == true
                                ? 'No: ${item.nomorSk}'
                                : 'SK Persetujuan Terbit')
                          : 'No. Registrasi: ${item.id}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(isAvailable: isAvailable),
            ],
          ),

          const SizedBox(height: 10),

          if (isAvailable) ...[
            // Metadata bar
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  item.tanggalSk ?? item.tanggal,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PDF RESMI',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tombol Unduh / Cetak SK Aktif
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final bytes = await File(
                      item.skPersetujuanPath!,
                    ).readAsBytes();
                    await Printing.layoutPdf(
                      onLayout: (_) async => bytes,
                      name: 'SK_${item.id}.pdf',
                    );
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Berkas SK Persetujuan tidak dapat dibuka saat ini.',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text(
                  'Lihat / Unduh PDF',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Keterangan Belum Tersedia
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.statusTahap == StatusTahapPengajuan.selesai
                          ? 'Berkas SK belum tersedia untuk dibuka di perangkat ini.'
                          : 'Pengajuan masih dalam proses verifikasi atau belum disahkan oleh Disperwaskim.',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDisabledDownloadButton(),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BA DOCUMENT ROW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBaDocumentRow(Pengajuan item) {
    final MonitoringModel? baModel = _getValidBa(item);
    final bool isAvailable = baModel != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFFFDAD6)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: isAvailable
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Berita Acara (BA Verifikasi Lapangan)',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? 'No: ${baModel.nomorSuratBA}'
                          : 'No. Registrasi: ${item.id}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(isAvailable: isAvailable),
            ],
          ),

          const SizedBox(height: 10),

          if (isAvailable) ...[
            // Metadata bar
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'd MMMM yyyy',
                    'id',
                  ).format(baModel.tanggalMonitoring),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PDF RESMI',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tombol Lihat / Unduh BA Aktif menggunakan BaPdfGenerator
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await BaPdfGenerator.printAndShare(baModel);
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Berita Acara tidak dapat diekspor saat ini.',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text(
                  'Lihat / Unduh PDF',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Keterangan Belum Tersedia
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.tanggalSurvey != null
                          ? 'Menunggu finalisasi hasil survey dan validasi teknis Tim Perwaskim.'
                          : 'Agenda survey lapangan belum selesai dilaksanakan.',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDisabledDownloadButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill({required bool isAvailable}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF64748B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Tersedia' : 'Belum Tersedia',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isAvailable
                  ? const Color(0xFF15803D)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledDownloadButton() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 15, color: Color(0xFF94A3B8)),
          SizedBox(width: 6),
          Text(
            'Belum Dapat Diunduh',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CALLOUT KEABSAHAN DOKUMEN (STITCH SECURITY SECTION)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSecurityCallout() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFFB91C1C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keabsahan Dokumen Resmi',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dokumen yang ditampilkan hanya untuk permohonan resmi berizin atas akun pengembang terdaftar. Dokumen resmi dilengkapi pengesahan digital Disperwaskim Kota Tasikmalaya.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMPTY STATE: DATABASE TIDAK MEMILIKI PENGAJUAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyDatabaseState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Maskot dengan dokumen SK/BA yang belum terbit.
            const AppIllustration(AppIllustration.unduhSkBa),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Dokumen Tersedia',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Dokumen SK dan BA akan otomatis muncul di sini setelah pengajuan Anda disurvey atau disetujui oleh Dinas.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(dashboardTabProvider.notifier).state = 1;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  try {
                    context.go('/dashboard');
                  } catch (_) {}
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Periksa Daftar Pengajuan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMPTY STATE: SEARCH / FILTER TIDAK COCOK
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIllustration(AppIllustration.hasilSurvey, width: 200),
            const SizedBox(height: 14),
            const Text(
              'Data Tidak Ditemukan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ada perumahan atau dokumen yang cocok dengan kata kunci pencarian Anda.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _resetSearchAndFilter,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Color(0xFF0F172A),
              ),
              label: const Text(
                'Reset pencarian dan filter',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
