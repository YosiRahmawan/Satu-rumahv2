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
    // Hanya notifikasi yang ditujukan ke role aktif (Pengembang tidak melihat
    // notifikasi Admin/Perwaskim, dan sebaliknya).
    final allNotifs = ref
        .watch(notifikasiProvider)
        .where((item) => item.untukRole(role))
        .toList();
    final String? avatarInitials =
        (session.username != null && session.username!.trim().isNotEmpty)
        ? (session.username!.trim().length >= 2
              ? session.username!.trim().substring(0, 2).toUpperCase()
              : session.username!.trim().toUpperCase())
        : null;

    final filteredNotifs = _selectedFilter == 'Belum Dibaca'
        ? allNotifs.where((e) => !e.isRead).toList()
        : allNotifs;

    if (role == AppRole.developer) {
      final pengajuan = ref.watch(pengajuanListProvider);
      final activeIds = activeRevisionNotificationIds(allNotifs, pengajuan);
      final shown = switch (_developerFilter) {
        NotifikasiFilter.semua => allNotifs,
        NotifikasiFilter.belumDibaca =>
          allNotifs.where((e) => !e.isRead).toList(),
        NotifikasiFilter.perluRevisi =>
          allNotifs.where((e) => activeIds.contains(e.id)).toList(),
      };
      final sortedNotifs = [...shown]
        ..sort((a, b) => b.waktu.compareTo(a.waktu));
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

    return Scaffold(
      appBar: AppHeader(
        variant: AppHeaderVariant.roleBased,
        title: role == AppRole.admin
            ? 'Pemerintah Kota Tasikmalaya'
            : (role == AppRole.perwaskim
                  ? 'Pengawasan Lapangan'
                  : 'SATU RUMAH'),
        subtitle: role == AppRole.admin
            ? 'SATU RUMAH - Disperwaskim'
            : (role == AppRole.perwaskim ? 'Disperwaskim' : 'Kotak Notifikasi'),
        showNotifications: false,
      ),
      backgroundColor: AppColors.background,
      body: Column(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifikasi',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.pill,
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textMain,
                            size: 18,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
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
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi.',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 14,
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.card,
                        ),
                        color: AppColors.surface,
                        child: InkWell(
                          borderRadius: AppRadii.card,
                          onTap: () {
                            notifier.markAsRead(item.id);
                            final route = notificationTargetForRole(item, role);
                            if (route == null) {
                              showUnavailableAction(
                                context,
                                'Tujuan notifikasi ini',
                              );
                            } else {
                              context.push(route);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    jenis.icon,
                                    color: AppColors.primaryRed,
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
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.deskripsi,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey700,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      left: 8,
                                      top: 4,
                                    ),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
