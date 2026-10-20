import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/report_photo.dart';
import '../../data/photo_bytes_cache.dart';
import '../../services/stamp_renderer.dart';

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
    final stamp = photo.stamp;
    final note = stamp.note?.trim();
    final address = stamp.address?.trim();
    final small = AppTextStyles.bodySmall.copyWith(
      fontFamily: AppTextStyles.enterpriseFontFamily,
      color: AppColors.enterpriseTextMuted,
      fontSize: 11,
      height: 1.35,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: AppRadii.small,
            child: bytes == null
                ? Container(
                    color: AppColors.enterpriseSurface,
                    alignment: Alignment.center,
                    child: Text('Foto tidak tersedia', style: small),
                  )
                : Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    semanticLabel: 'Foto dokumentasi $number',
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Foto $number${note == null || note.isEmpty ? '' : ' · $note'}',
          style: AppTextStyles.labelSmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        Text(StampRenderer.formatStampTime(stamp.capturedAt), style: small),
        if (address != null && address.isNotEmpty)
          Text(
            address,
            style: small,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        Text(StampRenderer.formatStampCoordinates(stamp), style: small),
      ],
    );
  }
}
