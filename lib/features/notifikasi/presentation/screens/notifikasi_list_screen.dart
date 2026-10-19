import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../../core/widgets/prototype_data_banner.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/data/models/status_tahap_pengajuan.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../data/models/notifikasi_model.dart';
import '../providers/notifikasi_provider.dart';
import '../widgets/developer_notification_view.dart';
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

/// Id notifikasi revisi yang masih aktif. Aktif bila jenisnya `perluRevisi`,
/// merujuk pengajuan yang ada, pengajuan itu masih `perluPerbaikan`, belum
/// dikirim ulang, dan masih punya dokumen yang diminta revisi. Bila satu
/// pengajuan punya beberapa permintaan, hanya yang terbaru yang aktif.
Set<String> activeRevisionNotificationIds(
  List<NotifikasiModel> items,
  List<Pengajuan> pengajuan,
) {
  final latest = <String, NotifikasiModel>{};
  for (final item in items) {
    final id = item.pengajuanId;
    if (item.jenis != JenisNotifikasi.perluRevisi || id == null) continue;
    final current = latest[id];
    if (current == null || item.waktu.isAfter(current.waktu)) latest[id] = item;
  }
  final active = <String>{};
  for (final entry in latest.entries) {
    final match = pengajuan.where((e) => e.id == entry.key);
    if (match.isEmpty) continue;
    final item = match.first;
    if (item.statusTahap == StatusTahapPengajuan.perluPerbaikan &&
        !item.revisionSubmitted &&
        item.dokumenPerluRevisi.isNotEmpty) {
      active.add(entry.value.id);
    }
  }
  return active;
}

/// Tujuan ketuk notifikasi Pengembang. Relasi utama adalah `pengajuanId`;
/// pengajuan yang tidak ada berarti tujuan tidak tersedia (null), bukan
/// navigasi ke layar kosong. Tanpa `pengajuanId`, dipakai pemetaan rute lama.
String? developerNotificationTarget(
  NotifikasiModel item,
  List<Pengajuan> pengajuan, {
  required bool revisiAktif,
}) {
  final id = item.pengajuanId;
  if (id != null) {
    if (!pengajuan.any((e) => e.id == id)) return null;
    final encoded = Uri.encodeComponent(id);
    return revisiAktif
        ? '/pengajuan/perbarui-berkas/$encoded'
        : '/pengajuan/detail/$encoded';
  }
  return notificationTargetForRole(item, AppRole.developer);
}

class NotifikasiListScreen extends ConsumerStatefulWidget {
  const NotifikasiListScreen({super.key});

  @override
  ConsumerState<NotifikasiListScreen> createState() =>
      _NotifikasiListScreenState();
}

class _NotifikasiListScreenState extends ConsumerState<NotifikasiListScreen> {
  String _selectedFilter = 'Semua';
  NotifikasiFilter _developerFilter = NotifikasiFilter.semua;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(notifikasiProvider.notifier);
    final session = ref.watch(roleSessionProvider);
    final role = session.role;
    // Hanya notifikasi yang ditujukan ke peran aktif (Pengembang tidak melihat
    // notifikasi Admin/Perwaskim, dan sebaliknya).
    final allNotifs = ref
        .watch(notifikasiProvider)
        .where((item) => item.untukRole(role))
        .toList();

    if (role == AppRole.developer) {
      return _buildDeveloperView(allNotifs, notifier, session);
    }

    if (role == AppRole.perwaskim) {
      return _buildPerwaskimView(context, allNotifs, notifier, session);
    }

    return _buildStandardView(context, allNotifs, notifier, role);
  }

  // ==========================================
  // PENGEMBANG VIEW
  // ==========================================
  Widget _buildDeveloperView(
    List<NotifikasiModel> allNotifs,
    NotifikasiNotifier notifier,
    RoleSessionState session,
  ) {
    final role = session.role;
    final avatarInitials =
        (session.username != null && session.username!.trim().isNotEmpty)
        ? (session.username!.trim().length >= 2
              ? session.username!.trim().substring(0, 2).toUpperCase()
              : session.username!.trim().toUpperCase())
        : null;
    final pengajuan = ref.watch(pengajuanListProvider);
    final activeIds = activeRevisionNotificationIds(allNotifs, pengajuan);
    final shown = switch (_developerFilter) {
      NotifikasiFilter.semua => allNotifs,
      NotifikasiFilter.belumDibaca =>
        allNotifs.where((e) => !e.isRead).toList(),
      NotifikasiFilter.perluRevisi =>
        allNotifs.where((e) => activeIds.contains(e.id)).toList(),
    };
    final sortedNotifs = [...shown]..sort((a, b) => b.waktu.compareTo(a.waktu));
    return DeveloperNotificationView(
      items: sortedNotifs,
      unreadCount: allNotifs.where((item) => !item.isRead).length,
      filter: _developerFilter,
      activeRevisionIds: activeIds,
      avatarLabel: avatarInitials,
      showOnlineIndicator: session.isAuthenticated,
      onFilterChanged: (filter) => setState(() => _developerFilter = filter),
      onMarkAllRead: () => notifier.markAllAsRead(untuk: role),
      onAvatarTap: () => ref.read(dashboardTabProvider.notifier).state = 3,
      onOpen: (item) {
        final route = developerNotificationTarget(
          item,
          pengajuan,
          revisiAktif: activeIds.contains(item.id),
        );
        if (route == null) {
          // Tujuan gagal dibuka: jangan tandai dibaca.
          showUnavailableAction(context, 'Tujuan notifikasi ini');
          return;
        }
        notifier.markAsRead(item.id);
        context.push(route);
      },
    );
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
        allNotifs
            .where(
              (e) =>
                  e.jenis == JenisNotifikasi.dokumenDiunggahUlang ||
                  e.jenis == JenisNotifikasi.deadlineVerifikasi,
            )
            .toList(),
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

  Widget _buildPerwaskimHeader(
    BuildContext context,
    PerwaskimIdentity identity,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.enterprisePrimary,
            AppColors.enterprisePrimaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Back button (left) and Avatar (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
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
                  // User Avatar with status dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            identity.initials,
                            style: const TextStyle(
                              color: AppColors.enterprisePrimaryDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.enterpriseSuccess,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Header Title & Subtitle
              const Text(
                'Notifikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pembaruan penugasan, monitoring, dan evaluasi lapangan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
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
    const role = AppRole.perwaskim;
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
                  ? () => notifier.markAllAsRead(untuk: role)
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: AppColors.enterpriseTextMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada notifikasi.',
            style: TextStyle(
              color: AppColors.enterpriseTextMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          AppColors.enterpriseWarningSurface,
          AppColors.enterpriseWarning,
        );
      case JenisNotifikasi.pengajuanBaru:
        return (
          'VERIFIKASI ADMINISTRASI',
          AppColors.enterprisePrimarySurface,
          AppColors.enterprisePrimary,
        );
      case JenisNotifikasi.deadlineVerifikasi:
        return (
          'EVALUASI LAPANGAN',
          AppColors.enterpriseSuccessSurface,
          AppColors.enterpriseSuccess,
        );
      case JenisNotifikasi.perluRevisi:
        return (
          'PERLU REVISI',
          AppColors.enterpriseWarningSurface,
          AppColors.enterpriseWarning,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? AppColors.enterpriseBorder : const Color(0xFFFECDD3),
          width: isRead ? 1.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isRead ? 0.02 : 0.04),
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
            final route = notificationTargetForRole(item, role);
            if (route == null) {
              showUnavailableAction(context, 'Tujuan notifikasi ini');
            } else {
              try {
                context.push(route);
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
                // Top Row: Category Badge Pill & Unread Dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.5,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8.5,
                        height: 8.5,
                        decoration: const BoxDecoration(
                          color: AppColors.enterprisePrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Body: Category Icon Box & Text Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isRead
                            ? const Color(0xFFF8FAFC)
                            : AppColors.enterprisePrimarySurfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead
                              ? AppColors.enterpriseBorder
                              : const Color(0xFFFECDD3).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        jenis.icon,
                        color: isRead
                            ? AppColors.enterpriseTextMuted
                            : AppColors.enterprisePrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.judul,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.enterpriseTextMain,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.deskripsi,
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
        variant: AppHeaderVariant.roleBased,
        title: role == AppRole.admin
            ? 'Pemerintah Kota Tasikmalaya'
            : 'SATU RUMAH',
        subtitle: role == AppRole.admin ? 'SATU RUMAH - Disperwaskim' : null,
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
                            ? () => notifier.markAllAsRead(untuk: role)
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
