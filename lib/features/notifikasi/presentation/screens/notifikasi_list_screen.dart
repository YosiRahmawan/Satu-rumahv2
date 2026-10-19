import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../../pengajuan/presentation/widgets/survey_not_found_illustration.dart';
import '../../data/models/notifikasi_model.dart';
import '../providers/notifikasi_provider.dart';
import '../../../monitoring/presentation/widgets/tab_beranda_monitoring.dart';

/// Rewrites a notification's local target into a route valid for the active
/// role. A null result is an explicit unavailable outcome, never a silent
/// navigation to another role's shell.
String? notificationTargetForRole(NotifikasiModel item, AppRole role) {
  final target = item.targetRoute;
  if (target == null || target.trim().isEmpty) return null;

  final pengajuanId = RegExp(
    r'SR-[A-Za-z0-9-]+',
  ).firstMatch(item.deskripsi)?.group(0);
  switch (role) {
    case AppRole.guest:
      return null;
    case AppRole.admin:
      if (target.startsWith('/admin/pengajuan/detail/')) return target;
      if (target.startsWith('/pengajuan/detail/')) {
        return target.replaceFirst(
          '/pengajuan/detail/',
          '/admin/pengajuan/detail/',
        );
      }
      if (target == '/monitoring' ||
          target.startsWith('/monitoring/preview') ||
          target == '/monitoring/tambah') {
        return target;
      }
      if (target.startsWith('/monitoring/lapangan')) return '/monitoring';
      return null;
    case AppRole.developer:
      if (target.startsWith('/pengajuan/detail/')) return target;
      if (target.startsWith('/admin/pengajuan/detail/')) {
        return target.replaceFirst(
          '/admin/pengajuan/detail/',
          '/pengajuan/detail/',
        );
      }
      if (target.startsWith('/monitoring')) {
        return pengajuanId == null ? null : '/pengajuan/detail/$pengajuanId';
      }
      if (target == '/dashboard') return target;
      return null;
    case AppRole.perwaskim:
      if (target.startsWith('/monitoring/lapangan')) return target;
      if (target == '/monitoring') return '/monitoring/lapangan';
      if (target.startsWith('/monitoring/preview')) return target;
      if (target.startsWith('/pengajuan/detail/') ||
          target.startsWith('/admin/pengajuan/detail/')) {
        return '/monitoring/lapangan';
      }
      return null;
  }
}

class NotifikasiListScreen extends ConsumerStatefulWidget {
  const NotifikasiListScreen({super.key});

  @override
  ConsumerState<NotifikasiListScreen> createState() =>
      _NotifikasiListScreenState();
}

class _NotifikasiListScreenState extends ConsumerState<NotifikasiListScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final allNotifs = ref.watch(notifikasiProvider);
    final notifier = ref.read(notifikasiProvider.notifier);
    final session = ref.watch(roleSessionProvider);
    final role = session.role;

    if (role == AppRole.perwaskim) {
      return _buildPerwaskimView(context, allNotifs, notifier, session);
    }

    return _buildStandardView(context, allNotifs, notifier, role);
  }

  // ==========================================
  // PERWASKIM (PENGAWAS LAPANGAN) ENTERPRISE VIEW
  // ==========================================
  Widget _buildPerwaskimView(
    BuildContext context,
    List<NotifikasiModel> allNotifs,
    NotifikasiNotifier notifier,
    RoleSessionState session,
  ) {
    final identity = PerwaskimIdentity.fromSession(session);
    final unreadCount = allNotifs.where((e) => !e.isRead).length;

    final filteredNotifs = switch (_selectedFilter) {
      'Belum Dibaca' => allNotifs.where((e) => !e.isRead).toList(),
      'Perlu Tindak Lanjut' =>
        allNotifs.where(_isPerluTindakLanjutPerwaskim).toList(),
      _ => allNotifs,
    };

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildPerwaskimHeader(context, identity),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildFilterChips(unreadCount)),
              SliverToBoxAdapter(
                child: _buildFilterSummaryRow(
                  allNotifs,
                  filteredNotifs,
                  notifier,
                ),
              ),
              if (filteredNotifs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildPerwaskimEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildPerwaskimCard(
                        context: context,
                        item: filteredNotifs[index],
                        notifier: notifier,
                        role: session.role,
                      );
                    }, childCount: filteredNotifs.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPerluTindakLanjutPerwaskim(NotifikasiModel item) {
    final titleLower = item.judul.toLowerCase();
    final descLower = item.deskripsi.toLowerCase();

    // Notifikasi yang sudah final atau selesai diverifikasi tidak membutuhkan aksi aktif petugas
    if (titleLower.contains('final') ||
        titleLower.contains('disahkan') ||
        descLower.contains('telah disahkan') ||
        descLower.contains('telah final') ||
        descLower.contains('telah diverifikasi')) {
      return false;
    }

    // Penugasan survei baru atau agenda survei lapangan aktif
    if (item.jenis == JenisNotifikasi.reminderSurvey) {
      return true;
    }

    // Tindakan perbaikan dokumen atau instruksi perbaikan yang membutuhkan aksi
    if (item.jenis == JenisNotifikasi.dokumenDiunggahUlang) {
      return true;
    }

    // Catatan evaluasi yang meminta tindak lanjut aktif
    if (item.jenis == JenisNotifikasi.deadlineVerifikasi) {
      return titleLower.contains('tindak lanjut') ||
          titleLower.contains('perlu') ||
          descLower.contains('tindak lanjut') ||
          descLower.contains('siap untuk survey');
    }

    return false;
  }

  Widget _buildPerwaskimHeader(
    BuildContext context,
    PerwaskimIdentity identity,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Back button, Title & Avatar
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    button: true,
                    label: 'Kembali',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/monitoring/lapangan');
                          }
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // User Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        identity.initials,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.enterprisePrimaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Subtitle positioned below the title row
              const Padding(
                padding: EdgeInsets.only(
                  left: 44.0 + AppSpacing.md,
                  right: AppSpacing.xs,
                ),
                child: Text(
                  'Informasi tugas dan hasil pengawasan lapangan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(int unreadCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Semua', 'Semua'),
          const SizedBox(width: 8),
          _buildFilterChip('Belum Dibaca', 'Belum Dibaca ($unreadCount)'),
          const SizedBox(width: 8),
          _buildFilterChip('Perlu Tindak Lanjut', 'Perlu Tindak Lanjut'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.enterprisePrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.enterprisePrimary
                  : AppColors.enterpriseBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.enterpriseTextMain,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSummaryRow(
    List<NotifikasiModel> allNotifs,
    List<NotifikasiModel> filteredNotifs,
    NotifikasiNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${filteredNotifs.length} notifikasi',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.enterpriseTextMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: TextButton(
              onPressed: allNotifs.any((item) => !item.isRead)
                  ? notifier.markAllAsRead
                  : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.enterprisePrimary,
                disabledForegroundColor: AppColors.enterpriseTextMuted
                    .withValues(alpha: 0.4),
              ),
              child: const Text(
                'Tandai semua dibaca',
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerwaskimEmptyState() {
    final String title;
    final String description;

    switch (_selectedFilter) {
      case 'Belum Dibaca':
        title = 'Semua notifikasi sudah dibaca';
        description = 'Belum ada pemberitahuan baru yang perlu dibaca.';
        break;
      case 'Perlu Tindak Lanjut':
        title = 'Tidak ada tindak lanjut';
        description = 'Belum ada tugas atau evaluasi yang memerlukan tindakan.';
        break;
      case 'Semua':
      default:
        title = 'Belum ada notifikasi';
        description = 'Informasi penugasan dan pengawasan akan muncul di sini.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SurveyNotFoundIllustration(width: 140, height: 110),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.enterpriseTextMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.enterpriseTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _getCategoryBadgeInfo(JenisNotifikasi jenis) {
    switch (jenis) {
      case JenisNotifikasi.reminderSurvey:
        return (
          'JADWAL PENINJAUAN',
          const Color(0xFFF1F5F9),
          const Color(0xFF334155),
        );
      case JenisNotifikasi.dokumenDiunggahUlang:
        return (
          'TINDAKAN DIPERLUKAN',
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
        );
      case JenisNotifikasi.pengajuanBaru:
        return (
          'VERIFIKASI ADMINISTRASI',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        );
      case JenisNotifikasi.deadlineVerifikasi:
        return (
          'EVALUASI LAPANGAN',
          const Color(0xFFECFDF5),
          const Color(0xFF065F46),
        );
    }
  }

  Widget _buildPerwaskimCard({
    required BuildContext context,
    required NotifikasiModel item,
    required NotifikasiNotifier notifier,
    required AppRole role,
  }) {
    final jenis = item.jenis;
    final dateStr = _formatWaktu(item.waktu);
    final isRead = item.isRead;
    final (badgeLabel, badgeBg, badgeTextColor) = _getCategoryBadgeInfo(jenis);
    final validRoute = notificationTargetForRole(item, role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.enterpriseBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: () {
            notifier.markAsRead(item.id);
            if (validRoute == null) {
              showUnavailableAction(context, 'Tujuan notifikasi ini');
            } else {
              try {
                context.push(validRoute);
              } catch (_) {
                // Safe fallback for isolated widget tests without GoRouter
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Label & Unread Dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.enterprisePrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Body: Category Icon Box & Text Content & Optional Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.enterpriseBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        jenis.icon,
                        color: AppColors.enterpriseTextMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.enterpriseTextMain,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.deskripsi,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.enterpriseTextMuted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.enterpriseTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (validRoute != null) ...[
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.enterpriseTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STANDARD VIEW (DEVELOPER & ADMIN ROLES)
  // ==========================================
  Widget _buildStandardView(
    BuildContext context,
    List<NotifikasiModel> allNotifs,
    NotifikasiNotifier notifier,
    AppRole role,
  ) {
    final filteredNotifs = _selectedFilter == 'Belum Dibaca'
        ? allNotifs.where((e) => !e.isRead).toList()
        : allNotifs;

    return Scaffold(
      appBar: AppHeader(
        variant: role == AppRole.admin
            ? AppHeaderVariant.authority
            : AppHeaderVariant.light,
        title: role == AppRole.admin
            ? 'Pemerintah Kota Tasikmalaya'
            : 'SATU RUMAH',
        subtitle: role == AppRole.admin ? 'SATU RUMAH' : null,
        showBackButton: false,
        showNotifications: false,
      ),
      backgroundColor: AppColors.surfaceWarm,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: PrototypeDataBanner(),
              ),
              // Title & Dropdown Filter Row
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Notifikasi',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.cocoaBeanRoast,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadii.pill,
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isDense: true,
                              value: _selectedFilter == 'Perlu Tindak Lanjut'
                                  ? 'Semua'
                                  : _selectedFilter,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.cocoaBeanRoast,
                                size: 18,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cocoaBeanRoast,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedFilter = val);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'Semua',
                                  child: Text('Semua'),
                                ),
                                DropdownMenuItem(
                                  value: 'Belum Dibaca',
                                  child: Text('Belum Dibaca'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: allNotifs.any((item) => !item.isRead)
                            ? notifier.markAllAsRead
                            : null,
                        child: const Text('Tandai semua dibaca'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // List Items
              Expanded(
                child: filteredNotifs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 56,
                              color: AppColors.grey400,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada notifikasi.',
                              style: TextStyle(
                                color: AppColors.grey600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        itemCount: filteredNotifs.length,
                        itemBuilder: (context, index) {
                          final item = filteredNotifs[index];
                          final jenis = item.jenis;
                          final dateStr = _formatWaktu(item.waktu);
                          final isRead = item.isRead;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  notifier.markAsRead(item.id);
                                  final route = notificationTargetForRole(
                                    item,
                                    role,
                                  );
                                  if (route == null) {
                                    showUnavailableAction(
                                      context,
                                      'Tujuan notifikasi ini',
                                    );
                                  } else {
                                    try {
                                      context.push(route);
                                    } catch (_) {
                                      // Safe fallback
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceAttention,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          jenis.icon,
                                          color: AppColors.chilliDust,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.judul,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.cocoaBeanRoast,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.deskripsi,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.grey700,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.grey600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                            top: 4,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.chilliDust,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWaktu(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return DateFormat('d MMM').format(time);
    }
  }
}
