import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';
import 'tab_beranda_monitoring.dart';

/// Mengisi form dengan data tugas survei. Bila tugas itu sudah punya draf,
/// drafnya yang dilanjutkan; kalau belum, form baru dibuat dari data tugas.
void prepareFormForPengajuan(WidgetRef ref, Pengajuan pengajuan) {
  final identity = PerwaskimIdentity.fromSession(ref.read(roleSessionProvider));
  final notifier = ref.read(monitoringFormProvider.notifier);
  notifier.resetForm();

  final existing = ref
      .read(monitoringRepositoryProvider)
      .getAllMonitoring()
      .where((m) => m.isDraft && m.pengajuanId == pengajuan.id);
  if (existing.isNotEmpty) {
    notifier.loadDraft(existing.first);
    return;
  }

  notifier.updatePengajuanId(pengajuan.id);
  notifier.updateNamaPerumahan(pengajuan.namaPerumahan);
  notifier.updateNamaDeveloper(pengajuan.namaPt);
  notifier.updateLokasi('Kota Tasikmalaya');
  notifier.updatePelaksanaNama(identity.nama);
  notifier.updatePelaksanaJabatan(identity.jabatan);
}

/// Tombol kamera tengah: pilih tugas survei (otomatis bila hanya satu),
/// siapkan drafnya, lalu buka kamera.
Future<void> openKameraLapangan(BuildContext context, WidgetRef ref) async {
  final tasks = ref.read(surveyAktifProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (tasks.isEmpty) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada tugas survei aktif. Foto dokumentasi disimpan ke '
            'draf tugas survei.',
          ),
        ),
      );
    return;
  }
  final Pengajuan? chosen = tasks.length == 1
      ? tasks.first
      : await showModalBottomSheet<Pengajuan>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _TugasPickerSheet(tasks: tasks),
        );
  if (chosen == null || !context.mounted) return;
  prepareFormForPengajuan(ref, chosen);
  await context.push('/monitoring/kamera');
}

class _TugasPickerSheet extends StatelessWidget {
  final List<Pengajuan> tasks;
  const _TugasPickerSheet({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Foto untuk tugas mana?',
                style: AppTextStyles.h4.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                'Foto disimpan ke draf Berita Acara tugas yang dipilih.',
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMuted,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final date = task.tanggalSurvey == null
                      ? null
                      : DateFormat(
                          'd MMM yyyy',
                          'id',
                        ).format(task.tanggalSurvey!);
                  return ListTile(
                    minVerticalPadding: AppSpacing.md,
                    title: Text(
                      task.namaPerumahan,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        fontWeight: FontWeight.w700,
                        color: AppColors.enterpriseTextMain,
                      ),
                    ),
                    subtitle: Text(
                      date == null ? task.namaPt : '${task.namaPt} · $date',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseTextMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(task),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
