import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/report_photo.dart';
import '../../data/photo_bytes_cache.dart';

/// Daftar foto dokumentasi bergeotag di Berita Acara: dua kolom, tiap foto
/// bernomor dengan keterangan waktu, alamat, dan koordinat.
class BaPhotoGallery extends StatelessWidget {
  final List<ReportPhoto> photos;

  const BaPhotoGallery({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.lg,
          children: [
            for (var i = 0; i < photos.length; i++)
              SizedBox(
                width: width,
                child: _BaPhoto(photo: photos[i], number: i + 1),
              ),
          ],
        );
      },
    );
  }
}

class _BaPhoto extends StatelessWidget {
  final ReportPhoto photo;
  final int number;

  const _BaPhoto({required this.photo, required this.number});

  @override
  Widget build(BuildContext context) {
    final bytes = photo.needsReselect ? null : PhotoBytesCache.get(photo.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto ditampilkan utuh: watermark geotag sudah menempel di pikselnya,
        // jadi tidak boleh dipotong dan tidak perlu keterangan terpisah.
        ClipRRect(
          borderRadius: AppRadii.small,
          child: bytes == null
              ? Container(
                  height: 120,
                  color: AppColors.enterpriseSurface,
                  alignment: Alignment.center,
                  child: Text(
                    'Foto tidak tersedia',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
                )
              : Image.memory(
                  bytes,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  semanticLabel: 'Foto dokumentasi $number',
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Foto $number',
          style: AppTextStyles.labelSmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.enterpriseTextMain,
          ),
        ),
      ],
    );
  }
}
