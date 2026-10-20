import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import 'status_hasil_evaluasi_badge_widget.dart';

/// Reusable modern document preview card for Berita Acara Monitoring.
///
/// Consistently used across [LaporanSuccessScreen] and [LaporanPreviewScreen].
/// Renders authentic data from [MonitoringModel] without inventing fake values,
/// unverified signatures, or fictional QR codes.
class BeritaAcaraDocumentCard extends StatelessWidget {
  final MonitoringModel monitoring;
  final bool isSuccessContext;

  const BeritaAcaraDocumentCard({
    super.key,
    required this.monitoring,
    this.isSuccessContext = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = monitoring;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kop Instansi Disperwaskim
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.enterprisePrimary,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEMERINTAH KOTA TASIKMALAYA',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                        color: AppColors.enterpriseTextMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DINAS PERUMAHAN DAN KAWASAN PERMUKIMAN',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.enterpriseTextMuted,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Status Badge
          Align(
            alignment: Alignment.centerLeft,
            child: item.isDraft
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.enterpriseWarningSurface,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      'DOKUMEN LOKAL • BELUM DITERBITKAN',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseWarning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : StatusHasilEvaluasiBadgeWidget(
                    status: item.statusHasilEvaluasi,
                  ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.enterpriseTextMain,
              thickness: 1,
              height: 1,
            ),
          ),

          // Judul Dokumen
          Text(
            'BERITA ACARA MONITORING DAN EVALUASI LAPANGAN',
            style: AppTextStyles.labelLarge.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              letterSpacing: 0.2,
              color: AppColors.enterpriseTextMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Nomor: ${item.nomorSuratBA}',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Ringkasan Field Dokumen (Real Data)
          _dataRow('Nomor BA', item.nomorSuratBA),
          _dataRow(
            'Perumahan',
            item.namaPerumahan.isNotEmpty ? item.namaPerumahan : 'Belum diisi',
          ),
          _dataRow(
            'Lokasi',
            item.lokasiPerumahan.trim().isNotEmpty
                ? item.lokasiPerumahan
                : 'Belum diisi',
          ),
          _dataRow(
            'Waktu Monev',
            _formatIndonesianDate(item.tanggalMonitoring),
          ),
          _dataRow('Status Evaluasi', item.statusHasilEvaluasi.label),
          if (item.namaDeveloper.trim().isNotEmpty)
            _dataRow('Pengembang', item.namaDeveloper),

          // Poin-poin temuan dan kesimpulan jika tersedia secara asli
          if (item.temuanLapangan.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionTitle('I. Temuan di Lapangan'),
            _buildBulletList(item.temuanLapangan),
          ],
          if (item.kesimpulan.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionTitle('II. Kesimpulan'),
            _buildBulletList(item.kesimpulan),
          ],
          if (item.kesepakatan.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionTitle('III. Kesepakatan'),
            _buildBulletList(item.kesepakatan),
          ],
          if (item.rencanaTindakLanjut.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionTitle('IV. Rencana Tindak Lanjut'),
            _buildBulletList(item.rencanaTindakLanjut),
          ],

          // Identitas pihak yang tercatat (Hanya jika ada data asli, tanpa tanda tangan / QR fiktif)
          if (_hasSignatoryData(item)) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.enterpriseBorder),
            const SizedBox(height: 8),
            Text(
              'Identitas pihak yang tercatat',
              style: AppTextStyles.labelMedium.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                fontWeight: FontWeight.bold,
                color: AppColors.enterpriseTextMain,
              ),
            ),
            const SizedBox(height: 6),
            if (item.pelaksanaNama.trim().isNotEmpty)
              _identityRow(
                'Pelaksana',
                item.pelaksanaNama,
                item.pelaksanaJabatan,
              ),
            if (item.ditemuiNama.trim().isNotEmpty)
              _identityRow('Ditemui', item.ditemuiNama, item.ditemuiJabatan),
          ],
        ],
      ),
    );
  }

  bool _hasSignatoryData(MonitoringModel item) =>
      item.pelaksanaNama.trim().isNotEmpty ||
      item.ditemuiNama.trim().isNotEmpty;

  Widget _identityRow(String label, String name, String role) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ),
        Text(
          ': ',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    color: AppColors.enterpriseTextMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (role.trim().isNotEmpty)
                  TextSpan(
                    text: ' ($role)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dataRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontSize: 11.5,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ),
        Text(
          ': ',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontSize: 11.5,
            color: AppColors.enterpriseTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontSize: 11.5,
              color: AppColors.enterpriseTextMain,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title,
      style: AppTextStyles.labelSmall.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
        color: AppColors.enterpriseTextMain,
      ),
    ),
  );

  Widget _buildBulletList(List<String> items) {
    final valid = items.where((e) => e.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          '-',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMuted,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: valid
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.enterpriseTextMain,
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
            ),
          )
          .toList(),
    );
  }

  String _formatIndonesianDate(DateTime dt) {
    const hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulanList = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hari = hariList[dt.weekday - 1];
    final bulan = bulanList[dt.month];
    return '$hari, ${dt.day} $bulan ${dt.year}';
  }
}
