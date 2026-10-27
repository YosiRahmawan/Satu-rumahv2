import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/app_housing_loader.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/hasil_survey_model.dart';
import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import '../providers/pengajuan_form_controller.dart';
import '../widgets/survey_not_found_illustration.dart';
import 'pengajuan_detail_screen.dart';

/// Provider data jadwal survey yang bersumber dari daftar pengajuan aktif pengembang.
final jadwalSurveyListProvider = FutureProvider.autoDispose<List<Pengajuan>>((
  ref,
) async {
  final list = ref.watch(pengajuanListProvider);
  await Future<void>.delayed(Duration.zero);
  return list;
});

/// Enum kategori filter status survey
enum SurveyFilterCategory {
  semua('Semua'),
  sudahDijadwalkan('Sudah Dijadwalkan'),
  belumDijadwalkan('Belum Dijadwalkan'),
  selesai('Selesai');

  final String label;
  const SurveyFilterCategory(this.label);
}

/// Helper untuk menentukan status survey dari sebuah [Pengajuan]
enum SurveyStatus {
  sudahDijadwalkan('Sudah Dijadwalkan'),
  belumDijadwalkan('Belum Dijadwalkan'),
  selesai('Selesai');

  final String label;
  const SurveyStatus(this.label);
}

SurveyStatus getSurveyStatus(Pengajuan item) {
  // 1. Jika survey sudah selesai atau tahap pengajuan sudah selesai/persetujuan
  final bool hasCompletedSurvey = item.riwayatSurvey.any(
    (s) => s.sudahTerlaksana,
  );
  if (hasCompletedSurvey ||
      item.statusTahap == StatusTahapPengajuan.selesai ||
      item.statusTahap == StatusTahapPengajuan.persetujuan) {
    return SurveyStatus.selesai;
  }

  // 2. Jika tanggal survey sudah ditentukan atau status tahap survey lapangan
  if (item.tanggalSurvey != null ||
      item.statusTahap == StatusTahapPengajuan.surveyLapangan ||
      item.status.toLowerCase().contains('terjadwal')) {
    return SurveyStatus.sudahDijadwalkan;
  }

  // 3. Belum dijadwalkan (tahap administrasi atau teknis sebelum penjadwalan)
  return SurveyStatus.belumDijadwalkan;
}

/// Layar Jadwal Survey Pengembang — SATU RUMAH V2
/// Mengikuti spesifikasi visual Google Stitch:
/// - Sticky Header Merah Gradient dengan Back Button & Subtitle
/// - Search bar nama perumahan
/// - Filter status horizontal (Semua, Sudah Dijadwalkan, Belum Dijadwalkan, Selesai)
/// - 4 UI States: Loading (AppHousingLoader), Error, Empty State, dan Data Tersedia
class JadwalSurveyScreen extends ConsumerStatefulWidget {
  const JadwalSurveyScreen({super.key});

  @override
  ConsumerState<JadwalSurveyScreen> createState() => _JadwalSurveyScreenState();
}

class _JadwalSurveyScreenState extends ConsumerState<JadwalSurveyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SurveyFilterCategory _selectedFilter = SurveyFilterCategory.semua;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = SurveyFilterCategory.semua;
    });
  }

  List<Pengajuan> _filterSubmissions(List<Pengajuan> submissions) {
    return submissions.where((item) {
      // 1. Filter pencarian nama perumahan atau ID
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchName = item.namaPerumahan.toLowerCase().contains(query);
        final matchId = item.id.toLowerCase().contains(query);
        if (!matchName && !matchId) return false;
      }

      // 2. Filter status survey
      final status = getSurveyStatus(item);
      switch (_selectedFilter) {
        case SurveyFilterCategory.semua:
          return true;
        case SurveyFilterCategory.sudahDijadwalkan:
          return status == SurveyStatus.sudahDijadwalkan;
        case SurveyFilterCategory.belumDijadwalkan:
          return status == SurveyStatus.belumDijadwalkan;
        case SurveyFilterCategory.selesai:
          return status == SurveyStatus.selesai;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final surveyAsync = ref.watch(jadwalSurveyListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Column(
        children: [
          // ─── 1. STICKY HEADER SATU RUMAH V2 ──────────────────────────────
          _buildHeader(context),

          // ─── 2. CONTENT AREA ─────────────────────────────────────────────
          Expanded(
            child: surveyAsync.when(
              loading: () => _buildLoadingState(),
              error: (err, stack) => _buildErrorState(err),
              data: (submissions) => _buildDataView(submissions),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER
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
          // Circular Back Button
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

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Jadwal Survey',
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
                  'Daftar jadwal survey lapangan perumahan',
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
    final bool isDatabaseEmpty = allSubmissions.isEmpty;
    final bool isFilteredEmpty = !isDatabaseEmpty && filteredItems.isEmpty;

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async {
        ref.invalidate(jadwalSurveyListProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Search & Filter Bar (jika database memiliki data) ──
          if (!isDatabaseEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    // Horizontal Filter Pills
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
              child: _buildEmptyState(
                title: 'Belum Ada Jadwal Survey',
                description:
                    'Jadwal survey untuk pengajuan Anda akan ditampilkan di sini setelah tersedia.',
                buttonText: 'Periksa Status Pengajuan',
                onAction: () {
                  ref.read(dashboardTabProvider.notifier).state = 1;
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.go('/dashboard');
                    } catch (_) {}
                  }
                },
              ),
            )
          else if (isFilteredEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                title: 'Jadwal Tidak Ditemukan',
                description:
                    'Tidak ada jadwal survey yang sesuai dengan filter atau kata kunci pencarian Anda.',
                buttonText: 'Reset Filter',
                isFilterEmpty: true,
                onAction: _resetSearchAndFilter,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = filteredItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSurveyCard(item),
                  );
                }, childCount: filteredItems.length),
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
        border: Border.all(color: const Color(0xFFE0E3E5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama perumahan...',
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
  // FILTER PILLS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SurveyFilterCategory.values.map((category) {
          final isSelected = _selectedFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = category;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: isSelected ? const Color(0xFFB91C1C) : Colors.white,
                    shape: StadiumBorder(
                      side: isSelected
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                    ),
                  ),
                  child: Text(
                    category.label,
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
  // CARD JADWAL SURVEY (DATA TERSEDIA — GOOGLE STITCH FINAL)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSurveyCard(Pengajuan item) {
    final status = getSurveyStatus(item);

    // Format tanggal sesuai status dan Stitch spec
    String tanggalInfo;
    final bool isDateBold;
    final IconData dateIcon;
    final Color dateIconColor;

    if (status == SurveyStatus.belumDijadwalkan || item.tanggalSurvey == null) {
      tanggalInfo = 'Jadwal belum ditetapkan';
      isDateBold = false;
      dateIcon = Icons.schedule_rounded;
      dateIconColor = const Color(0xFFB45309);
    } else {
      isDateBold = true;
      if (status == SurveyStatus.sudahDijadwalkan) {
        dateIcon = Icons.calendar_today_outlined;
        dateIconColor = AppColors.primaryRed;
      } else {
        dateIcon = Icons.event_available_rounded;
        dateIconColor = const Color(0xFF64748B);
      }

      try {
        final formattedDate = DateFormat(
          'EEEE, d MMMM yyyy • HH.mm',
          'id',
        ).format(item.tanggalSurvey!);
        tanggalInfo = '$formattedDate WIB';
      } catch (_) {
        tanggalInfo =
            '${item.tanggalSurvey!.day}/${item.tanggalSurvey!.month}/${item.tanggalSurvey!.year}';
      }
    }

    // Nama petugas/tim
    final bool hasOfficer;
    final String officerText;
    if (item.riwayatSurvey.isNotEmpty &&
        item.riwayatSurvey.first.pelaksanaNama.isNotEmpty &&
        item.riwayatSurvey.first.pelaksanaNama != '-') {
      hasOfficer = true;
      var name = item.riwayatSurvey.first.pelaksanaNama;
      if (item.riwayatSurvey.first.pelaksanaJabatan.isNotEmpty &&
          item.riwayatSurvey.first.pelaksanaJabatan != '-') {
        name += ', ${item.riwayatSurvey.first.pelaksanaJabatan}';
      }
      officerText = 'Petugas: $name';
    } else if (item.catatanSurvey != null &&
        item.catatanSurvey!.trim().isNotEmpty &&
        status != SurveyStatus.belumDijadwalkan) {
      hasOfficer = true;
      officerText = 'Petugas: Tim Pengawas Perwaskim';
    } else {
      hasOfficer = false;
      officerText = 'Petugas: Belum Ditugaskan';
    }

    // Subtitle label (Status / Tipe pengajuan / Nama PT)
    final String subLabel;
    if (item.status.isNotEmpty) {
      subLabel = item.status;
    } else if (item.namaPt.isNotEmpty) {
      subLabel = item.namaPt;
    } else {
      subLabel = 'Pengajuan Site Plan';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Judul & Subtitle di Kiri, Status Badge di Kanan ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaPerumahan,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(text: item.id),
                          if (subLabel.isNotEmpty) ...[
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: SizedBox(
                                  width: 3.5,
                                  height: 3.5,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: subLabel),
                          ],
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),

          // ── Detail Rows (Date and Officer) ──
          // Row 1: Tanggal
          Row(
            children: [
              Icon(dateIcon, size: 17, color: dateIconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tanggalInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: isDateBold ? FontWeight.w500 : FontWeight.w400,
                    color: isDateBold
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Petugas
          Row(
            children: [
              Icon(
                hasOfficer
                    ? Icons.person_outline_rounded
                    : Icons.person_off_outlined,
                size: 17,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  officerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: hasOfficer
                        ? const Color(0xFF334155)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          // Catatan Khusus (jika ada pada data riil)
          if (item.catatanSurvey != null &&
              item.catatanSurvey!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Catatan: ${item.catatanSurvey!}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Progres dan hasil monitoring (dari Admin dan Pengawas) ──
          const SizedBox(height: 12),
          _buildProgresMonitoring(item),
          if (item.riwayatSurvey.isNotEmpty)
            _buildHasilMonitoring(item.riwayatSurvey.first),
          const SizedBox(height: 12),

          // ── Divider & Footer (OPD & Action) ──
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Disperwaskim Kota Tasikmalaya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  try {
                    context.push('/pengajuan/detail/${item.id}');
                  } catch (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PengajuanDetailScreen(id: item.id),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Text(
                    'Lihat Detail Pengajuan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Progres monitoring: Dijadwalkan, Survei dilaksanakan, Hasil terbit.
  Widget _buildProgresMonitoring(Pengajuan item) {
    final dijadwalkan =
        item.tanggalSurvey != null ||
        item.statusTahap == StatusTahapPengajuan.surveyLapangan ||
        item.riwayatSurvey.isNotEmpty;
    final dilaksanakan = item.riwayatSurvey.any((r) => r.sudahTerlaksana);
    final hasil = item.riwayatSurvey.any(
      (r) => (r.nomorSuratBA ?? '').isNotEmpty,
    );
    final steps = [
      ('Dijadwalkan', dijadwalkan),
      ('Survei dilaksanakan', dilaksanakan),
      ('Hasil terbit', hasil),
    ];
    // Langkah aktif = yang pertama belum selesai.
    final activeIndex = steps.indexWhere((e) => !e.$2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].$2
                          ? const Color(0xFF16A34A)
                          : (i == activeIndex
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: steps[i].$2
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i == activeIndex
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i].$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: i == activeIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: steps[i].$2 || i == activeIndex
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 16,
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: steps[i].$2
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE2E8F0),
              ),
          ],
        ],
      ),
    );
  }

  /// Ringkasan hasil monitoring terbaru; warna mengikuti status semantik design.md.
  Widget _buildHasilMonitoring(HasilSurveyItem r) {
    final (
      Color fg,
      Color bg,
      Color border,
      IconData icon,
    ) = switch (r.statusHasilEvaluasi) {
      'sesuai' => (
        const Color(0xFF16A34A),
        const Color(0xFFDCFCE7),
        const Color(0xFFBBF7D0),
        Icons.check_circle_outline_rounded,
      ),
      'tidak_sesuai' => (
        const Color(0xFFB91C1C),
        const Color(0xFFFFF1F2),
        const Color(0xFFFECDD3),
        Icons.error_outline_rounded,
      ),
      _ => (
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
        const Color(0xFFFDE68A),
        Icons.assignment_late_outlined,
      ),
    };
    final kesimpulan = r.kesimpulan.isNotEmpty
        ? r.kesimpulan.first
        : (r.temuanLapangan.isNotEmpty ? r.temuanLapangan.first : null);
    final rtl = r.rencanaTindakLanjut.take(2).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Monitoring: ${r.statusLabel}',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  if ((r.nomorSuratBA ?? '').isNotEmpty)
                    Text(
                      'BA ${r.nomorSuratBA}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  if (kesimpulan != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      kesimpulan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                  if (rtl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Tindak lanjut:',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    for (final t in rtl)
                      Text(
                        '• $t',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SurveyStatus status) {
    final Color bg;
    final Color border;
    final Color fg;
    final Color dotColor;

    switch (status) {
      case SurveyStatus.sudahDijadwalkan:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        fg = const Color(0xFF047857);
        dotColor = const Color(0xFF059669);
        break;
      case SurveyStatus.belumDijadwalkan:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        fg = const Color(0xFFB45309);
        dotColor = const Color(0xFFD97706);
        break;
      case SurveyStatus.selesai:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        dotColor = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMPTY STATE (GOOGLE STITCH ALIGNED)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onAction,
    bool isFilterEmpty = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            if (isFilterEmpty)
              const SurveyNotFoundIllustration(width: 200, height: 157)
            else
              // Calendar with SATU RUMAH House Accent illustration
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFFEE2E2), width: 2),
                  ),
                ),
                alignment: Alignment.center,
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 54,
                      color: AppColors.primaryRed,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.home_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    isFilterEmpty
                        ? Icons.refresh_rounded
                        : Icons.assignment_turned_in_outlined,
                    size: 18,
                  ),
                  label: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 1,
                    shadowColor: const Color(0x1A0F172A),
                    side: const BorderSide(color: Color(0xFFE0E3E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOADING STATE (GOOGLE STITCH HOUSING ANIMATION SPEC)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppHousingLoader.medium(
              semanticsLabel: 'Memuat data jadwal survey perumahan',
            ),
            SizedBox(height: 16),
            Text(
              'Memuat jadwal survey...',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Mohon tunggu sebentar.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ERROR STATE (GOOGLE STITCH MINIMAL WIFI_OFF & SOLID RED RETRY SPEC)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(Object error) {
    const String errorMessage =
        'Jadwal survey belum dapat ditampilkan. Silakan coba kembali.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2), // rose-50
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE4E6)), // rose-100
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFB91C1C),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Jadwal Survey',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: const Text(
                errorMessage,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(jadwalSurveyListProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
