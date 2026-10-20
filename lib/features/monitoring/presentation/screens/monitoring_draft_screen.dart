import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';
import '../widgets/ba_photo_gallery.dart';
import '../widgets/status_hasil_evaluasi_badge_widget.dart';

/// Screen displaying the inspection details for an in-progress draft monitoring report.
///
/// Provides a clear status banner showing that this report is still a draft,
/// displays authentic recorded data without fictional placeholders, and includes
/// a prominent "Lanjutkan Pengisian" action to resume editing in [TambahMonitoringStepperScreen].
class MonitoringDraftScreen extends ConsumerWidget {
  final MonitoringModel monitoring;

  const MonitoringDraftScreen({super.key, required this.monitoring});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil versi terbaru dari repository agar perubahan dari "Simpan Draft"
    // di formulir langsung terlihat setelah kembali ke layar ini.
    final latest = ref
        .watch(monitoringListProvider)
        .where((e) => e.id == monitoring.id);
    final item = latest.isEmpty ? monitoring : latest.first;

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/monitoring/lapangan');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        title: Text(
          'Dokumen Draft Monitoring',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.enterpriseTextMain,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDraftNoticeBanner(),
                    const SizedBox(height: 16),
                    _buildObjectCard(item),
                    const SizedBox(height: 16),
                    _buildEvaluationCard(item),
                    const SizedBox(height: 16),
                    _buildPeopleCard(item),
                  ],
                ),
              ),
            ),
            _buildBottomActionBar(context, ref, item),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.enterpriseWarningSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: AppColors.enterpriseWarning.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.enterpriseWarning.withValues(alpha: 0.15),
                  borderRadius: AppRadii.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: AppColors.enterpriseWarning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'STATUS: DRAFT',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseWarning,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Belum Difinalisasi',
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Laporan Pengawasan Belum Selesai',
            style: AppTextStyles.labelLarge.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.enterpriseTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data hasil evaluasi lapangan ini tersimpan sebagai draft lokal dan belum diterbitkan menjadi Berita Acara resmi. Anda dapat melanjutkan pengisian untuk melengkapi dan memfinalisasi laporan.',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectCard(MonitoringModel item) {
    String formattedDate = '-';
    try {
      formattedDate = DateFormat(
        'd MMMM yyyy',
        'id',
      ).format(item.tanggalMonitoring);
    } catch (_) {
      formattedDate = DateFormat('d MMM yyyy').format(item.tanggalMonitoring);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.apartment_rounded,
            title: 'Informasi Objek Monitoring',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow('Nama Perumahan', item.namaPerumahan, isBold: true),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Nama Pengembang',
            item.namaDeveloper.isNotEmpty ? item.namaDeveloper : '-',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Lokasi Perumahan',
            item.lokasiPerumahan.isNotEmpty ? item.lokasiPerumahan : '-',
          ),
          const SizedBox(height: 10),
          _buildDetailRow('Tanggal Survey', formattedDate),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Nomor Draft / Registrasi',
            item.nomorSuratBA,
            badgeColor: AppColors.enterprisePrimarySurfaceSoft,
            badgeTextColor: AppColors.enterprisePrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(MonitoringModel item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCardHeader(
                icon: Icons.fact_check_outlined,
                title: 'Hasil Evaluasi Lapangan',
              ),
              StatusHasilEvaluasiBadgeWidget(
                status: item.statusHasilEvaluasi,
                isCompact: true,
                showIcon: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSectionLabel('Temuan di Lapangan:'),
          const SizedBox(height: 6),
          _buildBulletList(item.temuanLapangan),
          const SizedBox(height: 12),
          _buildSectionLabel('Kesimpulan:'),
          const SizedBox(height: 6),
          _buildBulletList(item.kesimpulan),
          const SizedBox(height: 12),
          _buildSectionLabel('Kesepakatan:'),
          const SizedBox(height: 6),
          _buildBulletList(item.kesepakatan),
          const SizedBox(height: 12),
          _buildSectionLabel('Rencana Tindak Lanjut:'),
          const SizedBox(height: 6),
          _buildBulletList(item.rencanaTindakLanjut),
          if (item.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionLabel('Dokumentasi Lapangan:'),
            const SizedBox(height: 8),
            BaPhotoGallery(photos: item.photos),
          ],
        ],
      ),
    );
  }

  Widget _buildPeopleCard(MonitoringModel item) {
    final pelaksanaList = item.pelaksana.isNotEmpty
        ? item.pelaksana
        : (item.pelaksanaNama.isNotEmpty
              ? [
                  MonitoringPerson(
                    nama: item.pelaksanaNama,
                    jabatan: item.pelaksanaJabatan,
                  ),
                ]
              : <MonitoringPerson>[]);

    final ditemuiList = item.ditemui.isNotEmpty
        ? item.ditemui
        : (item.ditemuiNama.isNotEmpty
              ? [
                  MonitoringPerson(
                    nama: item.ditemuiNama,
                    jabatan: item.ditemuiJabatan,
                  ),
                ]
              : <MonitoringPerson>[]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.people_outline_rounded,
            title: 'Petugas & Pihak Terkait',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSectionLabel('Tim Pelaksana Pengawas:'),
          const SizedBox(height: 6),
          if (pelaksanaList.isEmpty)
            _buildEmptyMutedText('-')
          else
            ...pelaksanaList.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.enterprisePrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nama.isNotEmpty ? p.nama : '-',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontFamily: AppTextStyles.enterpriseFontFamily,
                              fontWeight: FontWeight.w700,
                              color: AppColors.enterpriseTextMain,
                            ),
                          ),
                          if (p.jabatan.isNotEmpty)
                            Text(
                              p.jabatan,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontFamily: AppTextStyles.enterpriseFontFamily,
                                color: AppColors.enterpriseTextMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildSectionLabel('Pihak Pengembang yang Ditemui:'),
          const SizedBox(height: 6),
          if (ditemuiList.isEmpty)
            _buildEmptyMutedText('-')
          else
            ...ditemuiList.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.enterpriseTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nama.isNotEmpty ? p.nama : '-',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontFamily: AppTextStyles.enterpriseFontFamily,
                              fontWeight: FontWeight.w700,
                              color: AppColors.enterpriseTextMain,
                            ),
                          ),
                          if (p.jabatan.isNotEmpty)
                            Text(
                              p.jabatan,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontFamily: AppTextStyles.enterpriseFontFamily,
                                color: AppColors.enterpriseTextMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    MonitoringModel item,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: const Border(
          top: BorderSide(color: AppColors.enterpriseBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('lanjutkan_pengisian_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.enterprisePrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
                elevation: 1,
              ),
              onPressed: () {
                ref.read(monitoringFormProvider.notifier).loadDraft(item);
                context.push('/monitoring/tambah');
              },
              icon: const Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Lanjutkan Pengisian',
                style: AppTextStyles.labelLarge.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('kembali_beranda_button'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.enterpriseBorder),
                minimumSize: const Size.fromHeight(42),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              onPressed: () {
                ref.read(monitoringTabProvider.notifier).state = 0;
                context.go('/monitoring/lapangan');
              },
              child: Text(
                'Kembali ke Beranda',
                style: AppTextStyles.labelMedium.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({required IconData icon, required String title}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.enterprisePrimary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.enterpriseTextMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        fontWeight: FontWeight.w700,
        color: AppColors.enterpriseTextMain,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    final valueWidget = badgeColor != null
        ? Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: AppTextStyles.labelSmall.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: badgeTextColor ?? AppColors.enterpriseTextMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        : Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.enterpriseTextMain,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth < 280 || textScale > 1.25) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMuted,
                ),
              ),
              const SizedBox(height: 3),
              valueWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 5, child: valueWidget),
          ],
        );
      },
    );
  }

  Widget _buildBulletList(List<String> items) {
    final valid = items.where((e) => e.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      return _buildEmptyMutedText('-');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: valid.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.enterprisePrimary,
                ),
              ),
              Expanded(
                child: Text(
                  e,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    color: AppColors.enterpriseTextMain,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyMutedText(String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        color: AppColors.enterpriseTextMuted,
      ),
    );
  }
}
