import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../../pengajuan/presentation/screens/jadwal_survey_screen.dart';
import '../providers/dashboard_provider.dart';

Pengajuan? latestPengajuan(List<Pengajuan> submissions) {
  return submissions.isEmpty ? null : submissions.first;
}

final dashboardPengajuanAsyncProvider = FutureProvider<List<Pengajuan>>((
  ref,
) async {
  final submissions = ref.watch(pengajuanListProvider);
  await Future<void>.delayed(Duration.zero);
  return submissions;
});

int? dashboardShortcutTab(String title) {
  switch (title) {
    case 'Pengajuan Saya':
      return 1;
    case 'Notifikasi':
      return 2;
    case 'Profil Saya':
      return 3;
    case 'Format Dokumen':
      return null;
    default:
      return null;
  }
}

class TabBeranda extends ConsumerWidget {
  const TabBeranda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsState = ref.watch(dashboardPengajuanAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: submissionsState.when(
        loading: () => const DataStateView.loading(),
        error: (error, stack) => DataStateView.error(
          onAction: () => ref.invalidate(dashboardPengajuanAsyncProvider),
        ),
        data: (list) {
          final lastSubmission = latestPengajuan(list);

          final session = ref.watch(roleSessionProvider);
          final String? avatarInitials = (session.username != null && session.username!.trim().isNotEmpty)
              ? (session.username!.trim().length >= 2
                  ? session.username!.trim().substring(0, 2).toUpperCase()
                  : session.username!.trim().toUpperCase())
              : null;

          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () async {
              ref.invalidate(dashboardPengajuanAsyncProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER MERAH (Scrolls naturally with content)
                  DeveloperHeader(
                    brandTitle: 'Satu Rumah',
                    avatarLabel: avatarInitials ?? 'YR',
                    showOnlineIndicator: true,
                    avatarTooltip: 'Buka profil',
                    onAvatarTap: () =>
                        ref.read(dashboardTabProvider.notifier).state = 3,
                  ),

                  // 2. GAP 16dp antara header dan card identitas
                  const SizedBox(height: 16),

                  // 3. CARD IDENTITAS PENGEMBANG
                  const _DeveloperIdentityCard(),

                  const SizedBox(height: 8),

                  // 4. CARD "PENGAJUAN TERAKHIR"
                  _PengajuanTerakhirCard(submission: lastSubmission),

                  const SizedBox(height: 20),

                  // 5. SECTION "MENU LAYANAN PENGEMBANG"
                  const _MenuLayananPengembangSection(),

                  // Bottom padding for docked FAB & bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2. CARD IDENTITAS PENGEMBANG
class _DeveloperIdentityCard extends StatelessWidget {
  const _DeveloperIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
          child: Row(
            children: [
              // Icon gedung pada box merah muda
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFEE2E2),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Nama & ID
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PT. Tasik Indah Sentosa',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ID Pengembang: Dev-2026-082',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge Terverifikasi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFA7F3D0),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF059669),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
}

/// 3. CARD "PENGAJUAN TERAKHIR"
class _PengajuanTerakhirCard extends StatelessWidget {
  final Pengajuan? submission;

  const _PengajuanTerakhirCard({this.submission});

  @override
  Widget build(BuildContext context) {
    final projectName = submission?.namaPerumahan.isNotEmpty == true
        ? submission!.namaPerumahan
        : 'Mutiara Regency Tasik';
    final regNumber = submission?.id.isNotEmpty == true
        ? (submission!.id.startsWith('REG')
              ? submission!.id
              : 'REG - ${submission!.id}')
        : 'REG - TSK-2026-084';
    final targetId = submission?.id ?? 'REG-TSK-2026-084';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: Label & Status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PENGAJUAN TERAKHIR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEAB308),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Dalam Proses',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nama proyek & Nomor registrasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  regNumber,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tahap: Verifikasi Administrasi Dokumen (Langkah 2 dari 4)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Progress labels & bar
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progres kelengkapan (40%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'Verifikasi Tahap 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.40,
                minHeight: 6,
                backgroundColor: Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 14),

            // CTA: "[description_outlined] Cek Detail ->"
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  context.push('/pengajuan/detail/$targetId');
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'Cek Detail',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
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

/// 4. SECTION "MENU LAYANAN PENGEMBANG"
class _MenuLayananPengembangSection extends ConsumerWidget {
  const _MenuLayananPengembangSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu Layanan Pengembang',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '4 Layanan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid 2 Kolom (Row 1)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MenuLayananCard(
                    icon: Icons.description_outlined,
                    title: 'Template Berkas',
                    subtitle: 'Download 16 slot berkas resmi',
                    onTap: () => showUnavailableAction(context, 'Template Berkas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MenuLayananCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Jadwal Survey',
                    subtitle: 'Jadwal aktif & petugas Perwaskim',
                    onTap: () {
                      try {
                        context.push('/jadwal-survey');
                      } catch (_) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const JadwalSurveyScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Grid 2 Kolom (Row 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MenuLayananCard(
                    icon: Icons.file_download_outlined,
                    title: 'Unduh SK & BA',
                    subtitle: 'File persetujuan PDF resmi',
                    onTap: () => showUnavailableAction(context, 'Unduh SK & BA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MenuLayananCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Pusat Bantuan',
                    subtitle: 'SOP & Layanan Dinas Perkim',
                    onTap: () => showUnavailableAction(context, 'Pusat Bantuan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLayananCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuLayananCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MenuLayananCard> createState() => _MenuLayananCardState();
}

class _MenuLayananCardState extends State<_MenuLayananCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Container(
        constraints: const BoxConstraints(minHeight: 162),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (highlighted) {
              setState(() {
                _isPressed = highlighted;
              });
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFFB91C1C).withValues(alpha: 0.08),
            highlightColor: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Icon container 52x52
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFFB91C1C),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle / Description
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
