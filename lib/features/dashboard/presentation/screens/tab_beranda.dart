import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_state_view.dart';
import '../../../../core/widgets/developer_header.dart';
import '../../../../core/widgets/route_feedback.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../notifikasi/data/models/notifikasi_model.dart';
import '../../../notifikasi/presentation/providers/notifikasi_provider.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';

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
      backgroundColor: AppColors.backgroundCanvas,
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
                  DeveloperHeader(
                    avatarLabel: 'YR',
                    showOnlineIndicator: true,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PT. Tasik Indah Sentosa',
                      style: TextStyle(
                        fontSize: 14,
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
                  color: AppColors.statusSuccessSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.statusSuccessText.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.statusSuccessText,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusSuccessText,
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PENGAJUAN TERAKHIR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                StatusBadge(status: 'Dalam Proses'),
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
                      fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                      return Image.asset(
                        'assets/images/foto_perumahan.jfif',
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
                      );
                    },
                  ),
                  // Overlay foto perumahan (Row + Flexible untuk mencegah tabrakan pada 360dp)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.60),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Kec. Tawang, Kota Tasikmalaya',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '45 Unit Subsidi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'Verifikasi Tahap 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                minHeight: 7,
                backgroundColor: AppColors.dividerLine,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 14),

            const Divider(height: 1, color: AppColors.dividerLine),
            const SizedBox(height: 8),

            // CTA: "[file_icon] Cek Detail ->"
            InkWell(
              onTap: () {
                context.push('/pengajuan/detail/$targetId');
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 15,
                      color: AppColors.primaryRed,
                    ),
                    SizedBox(width: 4),
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
                      Icons.arrow_forward_rounded,
                      size: 14,
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
        border: Border.all(color: AppColors.borderSubtle, width: 1),
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
