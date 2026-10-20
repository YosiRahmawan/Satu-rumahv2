import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/evidence_photo_item.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/photo_bytes_cache.dart';
import '../../utils/photo_location_summary.dart';
import '../providers/project_reference_provider.dart';

/// Daftar foto dokumentasi sebuah laporan: gambar dan lokasi tercatat per foto,
/// agar pemeriksa melihat titik, sumber, jarak, dan alasan petugas tanpa
/// membuka formulir.
class MonitoringPhotoGallery extends ConsumerWidget {
  final MonitoringModel monitoring;

  const MonitoringPhotoGallery({super.key, required this.monitoring});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(
      projectReferenceProvider(monitoring.pengajuanId),
    );
    final photos = [
      for (final photo in monitoring.photos)
        if (photo.localRef.trim().isNotEmpty) photo,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < photos.length; i++) ...[
          if (i > 0)
            const Divider(height: 20, color: AppColors.enterpriseBorder),
          _PhotoRow(
            number: i + 1,
            photo: photos[i],
            summary: summarizePhotoLocation(photos[i], reference: reference),
          ),
        ],
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final int number;
  final EvidencePhotoItem photo;
  final PhotoLocationSummary summary;

  const _PhotoRow({
    required this.number,
    required this.photo,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadii.small,
          child: SizedBox(width: 76, height: 76, child: _thumbnail()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto $number',
                style: AppTextStyles.labelLarge.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.enterpriseTextMain,
                ),
              ),
              const SizedBox(height: 4),
              for (final line in summary.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      fontSize: 11,
                      height: 1.35,
                      color:
                          summary.outsideTolerance &&
                              line.startsWith('Jarak ke proyek')
                          ? AppColors.enterpriseWarning
                          : (!summary.hasLocation
                                ? AppColors.enterprisePrimary
                                : AppColors.enterpriseTextMuted),
                      fontWeight:
                          summary.outsideTolerance &&
                              line.startsWith('Jarak ke proyek')
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumbnail() {
    if (photo.needsReselect) return _placeholder('Tidak tersimpan');
    final bytes = PhotoBytesCache.get(photo.localRef);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder('Tidak dapat ditampilkan'),
      );
    }
    if (photo.localRef.startsWith('http')) {
      return Image.network(
        photo.localRef,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder('Tidak dapat ditampilkan'),
      );
    }
    return _placeholder('Tidak tersedia');
  }

  Widget _placeholder(String label) {
    return Container(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 20,
            color: AppColors.enterpriseTextMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontSize: 9,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
