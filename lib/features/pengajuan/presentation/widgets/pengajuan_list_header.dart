import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/developer_header.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';

class PengajuanListHeader extends ConsumerWidget {
  const PengajuanListHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return DeveloperHeader(
      pageTitle: 'Pengajuan',
      pageSubtitle: 'Daftar pengajuan site plan perumahan',
      avatarLabel: 'YR',
      showOnlineIndicator: true,
      avatarTooltip: 'Buka profil',
      onAvatarTap: () => ref.read(dashboardTabProvider.notifier).state = 3,
      notificationCount: unread,
      onNotificationTap: () =>
          ref.read(dashboardTabProvider.notifier).state = 2,
    );
  }
}
