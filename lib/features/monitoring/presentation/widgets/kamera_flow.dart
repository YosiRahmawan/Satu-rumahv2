import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../data/models/kamera_context.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';
import 'tab_beranda_monitoring.dart';

/// Mengisi form dengan data tugas survei. Bila tugas itu sudah punya draf,
/// drafnya yang dilanjutkan; kalau belum, form baru dibuat dari data tugas.
/// Digunakan oleh tombol "Buka Berita Acara & Mulai Survei" pada Beranda Perwaskim.
void prepareFormForPengajuan(WidgetRef ref, Pengajuan pengajuan) {
  final identity = PerwaskimIdentity.fromSession(ref.read(roleSessionProvider));
  final notifier = ref.read(monitoringFormProvider.notifier);
  notifier.resetForm();

  final existing = ref
      .read(monitoringRepositoryProvider)
      .getAllMonitoring()
      .where((m) => m.isDraft && m.pengajuanId == pengajuan.id);
  // Mode API: tim pelaksana ditetapkan Admin pada penugasan.
  final team = ref.read(assignmentTeamProvider(pengajuan.id));
  if (existing.isNotEmpty) {
    notifier.loadDraft(existing.first);
    if (team != null) notifier.setTimPelaksana(team);
    return;
  }

  notifier.updatePengajuanId(pengajuan.id);
  notifier.updateNamaPerumahan(pengajuan.namaPerumahan);
  notifier.updateNamaDeveloper(pengajuan.namaPt);
  notifier.updateLokasi('Kota Tasikmalaya');
  if (team != null) {
    notifier.setTimPelaksana(team);
  } else {
    notifier.updatePelaksanaNama(identity.nama);
    notifier.updatePelaksanaJabatan(identity.jabatan);
  }
}

/// Membuka bottom sheet modal Kamera Lapangan (Mode Selector).
/// Sesuai referensi Stitch Google Final:
/// 1. Pilihan "Foto Geotagging": Langsung membuka kamera fullscreen (mode mandiri).
/// 2. Pilihan "Foto untuk Tugas Survei": Memilih tugas aktif lalu membuka kamera fullscreen
///    dengan konteks tugas tersebut (tanpa mengubah data draf secara otomatis).
/// 3. Pilihan "Dokumentasi Saya": Memberikan umpan balik status fitur arsip.
Future<void> openKameraLapangan(BuildContext context, WidgetRef ref) async {
  final tasks = ref.read(surveyAktifProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => KameraModeBottomSheet(
      tasks: tasks,
      onSelectMandiri: () {
        Navigator.of(sheetContext).pop();
        context.push(
          '/monitoring/kamera',
          extra: const KameraContext.mandiri(),
        );
      },
      onSelectTask: (task) {
        Navigator.of(sheetContext).pop();
        context.push(
          '/monitoring/kamera',
          extra: KameraContext.tugas(
            taskId: task.id,
            taskTitle: task.namaPerumahan,
            nomorRegistrasi: task.id,
          ),
        );
      },
      onOpenDokumentasiSaya: () {
        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Dokumentasi Saya (Galeri & Arsip) akan tersedia pada tahap selanjutnya.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
      },
    ),
  );
}

/// Widget Bottom Sheet interaktif 2 tahap (Mode Selector & Task Selector).
class KameraModeBottomSheet extends StatefulWidget {
  final List<Pengajuan> tasks;
  final VoidCallback onSelectMandiri;
  final ValueChanged<Pengajuan> onSelectTask;
  final VoidCallback onOpenDokumentasiSaya;

  const KameraModeBottomSheet({
    super.key,
    required this.tasks,
    required this.onSelectMandiri,
    required this.onSelectTask,
    required this.onOpenDokumentasiSaya,
  });

  @override
  State<KameraModeBottomSheet> createState() => _KameraModeBottomSheetState();
}

class _KameraModeBottomSheetState extends State<KameraModeBottomSheet> {
  bool _isTaskSelector = false;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            // Sub-view Switcher
            Flexible(
              child: _isTaskSelector
                  ? _buildTaskSelectorView()
                  : _buildModeSelectorView(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW A: MODE SELECTOR ("Kamera Lapangan")
  // ==========================================
  Widget _buildModeSelectorView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kamera Lapangan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.enterpriseTextMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pilih cara mengambil dokumentasi lapangan.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.enterpriseTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // Option Cards Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                // Option 1: Foto Geotagging
                _buildModeCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Foto Geotagging',
                  badgeText: 'GPS Watermark',
                  badgeColor: const Color(0xFFECFDF5),
                  badgeTextColor: const Color(0xFF047857),
                  badgeBorderColor: const Color(0xFFA7F3D0),
                  description:
                      'Ambil foto dengan lokasi, koordinat, waktu, dan watermark GPS.',
                  footerText: 'Tersimpan langsung ke Dokumentasi Saya',
                  footerIcon: Icons.info_outline_rounded,
                  onTap: widget.onSelectMandiri,
                ),
                const SizedBox(height: 12),
                // Option 2: Foto untuk Tugas Survei
                _buildModeCard(
                  icon: Icons.assignment_outlined,
                  title: 'Foto untuk Tugas Survei',
                  badgeText: '${widget.tasks.length} Aktif',
                  badgeColor: const Color(0xFFFFFBEB),
                  badgeTextColor: const Color(0xFF92400E),
                  badgeBorderColor: const Color(0xFFFDE68A),
                  description:
                      'Pilih tugas pengawasan dan lampirkan foto ke berita acara.',
                  footerText: 'Masuk ke draf Berita Acara tugas terpilih',
                  footerIcon: Icons.description_outlined,
                  onTap: () {
                    if (widget.tasks.isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Belum ada tugas survei aktif untuk diasosiasikan.',
                            ),
                          ),
                        );
                      return;
                    }
                    setState(() => _isTaskSelector = true);
                  },
                ),
                const SizedBox(height: 16),
                // Secondary Action: Dokumentasi Saya
                Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.onOpenDokumentasiSaya,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Dokumentasi Saya (Galeri & Arsip)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Color(0xFF334155),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required Color badgeBorderColor,
    required String description,
    required String footerText,
    required IconData footerIcon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: AppColors.enterpriseTextMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeBorderColor),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: badgeTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.enterpriseTextMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          footerIcon,
                          size: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            footerText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW B: TASK SELECTOR ("Foto untuk tugas mana?")
  // ==========================================
  Widget _buildTaskSelectorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Back Arrow
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Kembali ke pilihan mode',
                onPressed: () => setState(() => _isTaskSelector = false),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.enterpriseTextMain,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto untuk tugas mana?',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.enterpriseTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Tersimpan ke draf Berita Acara tugas terpilih.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.enterpriseTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        // Task List
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: widget.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = widget.tasks[index];
              final dateStr = task.tanggalSurvey == null
                  ? null
                  : DateFormat('d MMM yyyy', 'id').format(task.tanggalSurvey!);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.onSelectTask(task),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.namaPerumahan,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: AppColors.enterpriseTextMain,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFEE2E2),
                                      ),
                                    ),
                                    child: const Text(
                                      'Tugas Aktif',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: AppColors.primaryRed,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dateStr == null
                                    ? task.namaPt
                                    : '${task.namaPt} · $dateStr',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.enterpriseTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'No. Registrasi: ${task.id}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 20,
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
    );
  }
}
