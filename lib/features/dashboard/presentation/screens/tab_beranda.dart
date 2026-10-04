import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../notifikasi/data/models/notifikasi_model.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
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

  void _quickDemo(BuildContext context, WidgetRef ref) {
    ref.read(pengajuanFormProvider.notifier).fillDummyData();

    final formState = ref.read(pengajuanFormProvider);
    final randomNum = Random().nextInt(900) + 100;
    final newId = 'REG-TSK-2026-$randomNum';

    final newPengajuan = Pengajuan(
      id: newId,
      namaPerumahan: formState.namaPerumahan.isNotEmpty
          ? formState.namaPerumahan
          : 'Mutiara Regency Tasik',
      namaPt: 'PT. Tasik Indah Sentosa',
      namaDirektur: 'H. Tatang Sutisna',
      npwpPerusahaan: formState.npwpPerusahaan.isNotEmpty
          ? formState.npwpPerusahaan
          : '09.123.456.7-423.000',
      luasLahan: formState.luasLahan > 0 ? formState.luasLahan : 12500.0,
      jumlahUnit: formState.jumlahUnit > 0 ? formState.jumlahUnit : 45,
      tipePerumahan: formState.tipePerumahan,
      status: 'Dalam Proses',
      tanggal: '20 Juli 2026',
      uploadedDocs: formState.uploadedDocs,
    );

    ref.read(pengajuanListProvider.notifier).addPengajuan(newPengajuan);

    ref.read(notifikasiProvider.notifier).addNotification(
          NotifikasiModel(
            id: 'notif-$newId',
            jenis: JenisNotifikasi.pengajuanBaru,
            judul: 'Pengajuan Berhasil Dikirim',
            deskripsi:
                'Pengajuan "${newPengajuan.namaPerumahan}" ($newId) telah diterima dan sedang dalam proses verifikasi administrasi.',
            waktu: DateTime.now(),
            targetRoute: '/pengajuan/detail/$newId',
          ),
        );

    ref.read(pengajuanFormProvider.notifier).reset();
    context.push('/pengajuan/success', extra: newId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsState = ref.watch(dashboardPengajuanAsyncProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: submissionsState.when(
        loading: () => const DataStateView.loading(),
        error: (error, stack) => DataStateView.error(
          onAction: () => ref.invalidate(dashboardPengajuanAsyncProvider),
        ),
        data: (list) {
          final lastSubmission = latestPengajuan(list);

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
                  // 1. HEADER MERAH
                  _DeveloperHeader(
                    onAvatarTap: () => _quickDemo(context, ref),
                  ),

                  // 2. CARD IDENTITAS PENGEMBANG (slightly overlapping header bottom curve)
                  const _DeveloperIdentityCard(),

                  const SizedBox(height: 8),

                  // 3. CARD "PENGAJUAN TERAKHIR"
                  _PengajuanTerakhirCard(
                    submission: lastSubmission,
                  ),

                  const SizedBox(height: 16),

                  // 4. SECTION "MENU LAYANAN PENGEMBANG"
                  const _MenuLayananPengembangSection(),

                  // Bottom padding for docked FAB & bar
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 1. HEADER MERAH
class _DeveloperHeader extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const _DeveloperHeader({required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sisi Kiri: Home icon, Satu Rumah, PORTAL PENGEMBANG
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Satu Rumah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'PORTAL PENGEMBANG',
                    style: TextStyle(
                      color: AppColors.primarySurfaceBorder,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sisi Kanan: Avatar YR + Indikator online hijau
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'YR',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // Online green
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2. CARD IDENTITAS PENGEMBANG
class _DeveloperIdentityCard extends StatelessWidget {
  const _DeveloperIdentityCard();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderNeutral, width: 1),
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
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Nama & ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'PT. Tasik Indah Sentosa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ID Pengembang: Dev-2026-082',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.semanticSuccessSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.semanticSuccessBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.semanticSuccessText,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.semanticSuccessText,
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
          border: Border.all(color: AppColors.borderNeutral, width: 1),
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.semanticWarningSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'Dalam Proses',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.semanticWarningText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nama proyek & Nomor registrasi
            Text(
              projectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              regNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Tahap & Progress langkah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Verifikasi Administrasi Dokumen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dividerLine,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Langkah 2 dari 4',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Foto perumahan dengan overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/perumahan/rumah1.jpg',
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 155,
                        width: double.infinity,
                        color: AppColors.dividerLine,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 36,
                        ),
                      );
                    },
                  ),
                  // Dark scrim gradient on bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Overlay kiri bawah: "Kec. Tawang, Kota Tasikmalaya"
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Kec. Tawang, Kota Tasikmalaya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Overlay kanan bawah: "45 Unit Subsidi"
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '45 Unit Subsidi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Progress labels & bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Progres kelengkapan (40%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'Verifikasi Tahap 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.40,
                minHeight: 7,
                backgroundColor: AppColors.dividerLine,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 14),

            const Divider(height: 1, color: AppColors.dividerLine),
            const SizedBox(height: 8),

            // CTA: "Cek Detail >"
            InkWell(
              onTap: () {
                context.push('/pengajuan/detail/$targetId');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'Cek Detail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primaryRed,
                    ),
                  ],
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu Layanan Pengembang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '4 Layanan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grid 2 kolom
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _MenuLayananCard(
                icon: Icons.folder_shared_outlined,
                title: 'Template Berkas',
                subtitle: 'Download 16 slot berkas resmi',
                onTap: () => showUnavailableAction(context, 'Template Berkas'),
              ),
              _MenuLayananCard(
                icon: Icons.calendar_month_outlined,
                title: 'Jadwal Survey',
                subtitle: 'Jadwal aktif & petugas Perwaskim',
                onTap: () => showUnavailableAction(context, 'Jadwal Survey'),
              ),
              _MenuLayananCard(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Unduh SK & BA',
                subtitle: 'File persetujuan PDF resmi',
                onTap: () => showUnavailableAction(context, 'Unduh SK & BA'),
              ),
              _MenuLayananCard(
                icon: Icons.headset_mic_outlined,
                title: 'Pusat Bantuan',
                subtitle: 'SOP & Layanan Dinas Perkim',
                onTap: () => showUnavailableAction(context, 'Pusat Bantuan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuLayananCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderNeutral, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Box icon merah muda
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
