import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/route_feedback.dart';

class DeveloperMainScreen extends StatefulWidget {
  final int initialIndex;

  const DeveloperMainScreen({super.key, this.initialIndex = 0});

  @override
  State<DeveloperMainScreen> createState() => _DeveloperMainScreenState();
}

class _DeveloperMainScreenState extends State<DeveloperMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _DeveloperHomeScreen(),
      const _DeveloperPlaceholderScreen(
        title: 'Pengajuan Site Plan',
        icon: PhosphorIconsRegular.clipboardText,
      ),
      const SizedBox(), // Spacer for FAB
      const _DeveloperPlaceholderScreen(
        title: 'Notifikasi',
        icon: PhosphorIconsRegular.bell,
      ),
      const _DeveloperProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 30),
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () => context.push('/pengajuan/step1'),
          backgroundColor: AppColors.chilliDust,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 24),
              Text(
                'AJUKAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Beranda'),
              _buildNavItem(1, PhosphorIconsRegular.clipboardText, PhosphorIconsFill.clipboardText, 'Pengajuan'),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(3, PhosphorIconsRegular.bell, PhosphorIconsFill.bell, 'Notifikasi'),
              _buildNavItem(4, PhosphorIconsRegular.user, PhosphorIconsFill.user, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.chilliDust : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.chilliDust : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperHomeScreen extends StatelessWidget {
  const _DeveloperHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Developer Info Card
                  _buildDeveloperInfoCard(),
                  
                  const SizedBox(height: 24),
                  // Latest Application Section
                  _buildLatestApplicationSection(context),
                  
                  const SizedBox(height: 24),
                  // Service Menu Section
                  _buildServiceMenu(context),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.chilliDust,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsRegular.house, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satu Rumah',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'PORTAL PENGEMBANG',
                    style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text('YR', style: TextStyle(color: AppColors.chilliDust, fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.chilliDust, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(PhosphorIconsRegular.buildings, color: AppColors.chilliDust),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PT. Tasik Indah Sentosa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'ID Pengembang: Dev-2026-082',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Terverifikasi',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestApplicationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PENGAJUAN TERAKHIR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Colors.orange),
                  SizedBox(width: 4),
                  Text('Dalam Proses', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mutiara Regency Tasik',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'REG - TSK-2026-084',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tahap: Verifikasi Administrasi Dokumen (Langkah 2 dari 4)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  ClipRRect(
                    child: Image.asset(
                      'assets/images/foto_perumahan.jfif',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(PhosphorIconsRegular.mapPin, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Kec. Tawang, Kota Tasikmalaya', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.chilliDust,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('45 Unit Subsidi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progres kelengkapan (40%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Verifikasi Tahap 2', style: TextStyle(fontSize: 12, color: AppColors.chilliDust, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.4,
                        minHeight: 8,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.chilliDust),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(PhosphorIconsRegular.fileText, size: 16, color: AppColors.chilliDust),
                        label: const Row(
                          children: [
                            Text('Cek Detail', style: TextStyle(color: AppColors.chilliDust, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_right_alt, color: AppColors.chilliDust),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Menu Layanan Pengembang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('4 Layanan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildServiceItem(PhosphorIconsRegular.fileText, 'Template Berkas', 'Download 16 slot berkas resmi'),
            _buildServiceItem(PhosphorIconsRegular.calendar, 'Jadwal Survey', 'Jadwal aktif & petugas Perwaskim'),
            _buildServiceItem(PhosphorIconsRegular.downloadSimple, 'Unduh SK & BA', 'File persetujuan PDF resmi'),
            _buildServiceItem(PhosphorIconsRegular.chatCircleDots, 'Pusat Bantuan', 'SOP & Layanan Dinas Perkim'),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.chilliDust, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DeveloperProfileScreen extends StatelessWidget {
  const _DeveloperProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Profil Pengembang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.chilliDust,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.chilliDust,
              child: Icon(Icons.business, color: Colors.white),
            ),
            title: Text(
              'PT. Tasik Indah Sentosa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID Pengembang: Dev-2026-082'),
          ),
          const Divider(),
          _buildItem(context, 'Profil Perusahaan', PhosphorIconsRegular.buildings),
          _buildItem(
            context,
            'Berkas Persyaratan (KTP/NIB/NPWP)',
            PhosphorIconsRegular.folderSimpleUser,
          ),
          _buildItem(context, 'Riwayat Pengajuan', PhosphorIconsRegular.clockCounterClockwise),
          _buildItem(context, 'Bantuan & Syarat Ketentuan', PhosphorIconsRegular.question),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.signOut, color: AppColors.chilliDust),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.chilliDust,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              ProviderScope.containerOf(
                context,
                listen: false,
              ).read(roleSessionProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cocoaBeanRoast),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey600),
      onTap: () => showUnavailableAction(context, title),
    );
  }
}

class _DeveloperPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DeveloperPlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.chilliDust,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Halaman $title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.cocoaBeanRoast,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
