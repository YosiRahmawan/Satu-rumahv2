import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../providers/monitoring_list_provider.dart';
import '../widgets/tab_beranda_monitoring.dart';
import '../widgets/tab_profil_monitoring.dart';
import 'monitoring_list_screen.dart';

class MonitoringMainScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MonitoringMainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MonitoringMainScreen> createState() =>
      _MonitoringMainScreenState();
}

class _MonitoringMainScreenState extends ConsumerState<MonitoringMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Selaraskan provider dengan tab awal dari rute, di luar fase build.
    Future.microtask(() {
      if (mounted) {
        ref.read(monitoringTabProvider.notifier).state = _currentIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TabBerandaMonitoring(),
      const MonitoringListScreen(showBottomNav: false),
      const TabProfilMonitoring(),
    ];

    // Layar lain (mis. "Kembali ke Beranda") mengubah tab lewat provider.
    ref.listen<int>(monitoringTabProvider, (previous, next) {
      if (next != _currentIndex) setState(() => _currentIndex = next);
    });

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: AppBottomNavigation.enterprise(
        currentIndex: _currentIndex,
        onTap: (index) {
          ref.read(monitoringTabProvider.notifier).state = index;
          setState(() => _currentIndex = index);
        },
        items: const [
          AppBottomNavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Beranda',
          ),
          AppBottomNavigationItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Riwayat',
          ),
          AppBottomNavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
