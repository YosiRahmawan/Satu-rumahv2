import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/report_photo.dart';
import '../../data/photo_bytes_cache.dart';
import '../../services/photo_import.dart';
import '../../services/stamp_renderer.dart';
import '../providers/camera_providers.dart';
import '../providers/monitoring_form_provider.dart';
import '../screens/kamera_lapangan_screen.dart' show kMaxReportPhotos;

/// Bagian foto di Langkah 3: ambil lewat kamera aplikasi atau pilih dari
/// galeri (hanya foto yang sudah bergeotag Satu Rumah), lalu daftar fotonya.
class FotoDokumentasiSection extends ConsumerWidget {
  /// Membuka kamera. Dipegang layar pemanggil agar status "tersimpan"-nya
  /// ikut diperbarui sepulang dari kamera.
  final VoidCallback onOpenCamera;

  const FotoDokumentasiSection({super.key, required this.onOpenCamera});

  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(monitoringFormProvider.notifier);
    final picked = await ref.read(photoPickerProvider).pickImages();
    if (picked.isEmpty || !context.mounted) return;

    final rejected = <PhotoImportResult>[];
    var accepted = 0;
    for (final file in picked) {
      final current = ref.read(monitoringFormProvider).photos;
      if (current.length >= kMaxReportPhotos) {
        rejected.add(
          PhotoImportResult.rejected(
            file.name,
            'Batas $kMaxReportPhotos foto per laporan tercapai.',
          ),
        );
        continue;
      }
      final result = verifyGalleryPhoto(file.name, file.bytes);
      if (!result.isAccepted) {
        rejected.add(result);
        continue;
      }
      if (current.any((p) => p.stamp == result.stamp)) {
        rejected.add(
          PhotoImportResult.rejected(
            file.name,
            'Foto ini sudah ada di laporan.',
          ),
        );
        continue;
      }
      notifier.addPhoto(
        ReportPhoto.create(source: PhotoSource.gallery, stamp: result.stamp!),
        file.bytes,
      );
      accepted++;
    }
    if (accepted > 0) notifier.saveDraft();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (accepted > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('$accepted foto bergeotag ditambahkan.')),
      );
    }
    if (rejected.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => _RejectedDialog(rejected: rejected),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(monitoringFormProvider.select((s) => s.photos));
    final notifier = ref.read(monitoringFormProvider.notifier);
    final full = photos.length >= kMaxReportPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: full ? null : onOpenCamera,
                icon: const Icon(Icons.photo_camera_rounded, size: 20),
                label: const Text('Kamera'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.enterprisePrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: full ? null : () => _pickFromGallery(context, ref),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.enterpriseTextMain,
                  side: const BorderSide(color: AppColors.enterpriseBorder),
                  minimumSize: const Size(0, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Galeri hanya menerima foto yang sudah bergeotag dari kamera '
          'aplikasi. Foto tanpa geotag ditolak.',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (photos.isEmpty)
          const _EmptyPhotos()
        else ...[
          Text(
            '${photos.length} dari $kMaxReportPhotos foto',
            style: AppTextStyles.labelLarge.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.md;
              final columns = constraints.maxWidth >= 560 ? 3 : 2;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    SizedBox(
                      width: width,
                      child: _PhotoTile(
                        photo: photos[i],
                        index: i + 1,
                        onDelete: () => notifier.removePhoto(photos[i].id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  const _EmptyPhotos();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.control,
      ),
      child: Text(
        'Belum ada foto. Laporan tetap dapat dikirim tanpa foto.',
        style: AppTextStyles.bodySmall.copyWith(
          fontFamily: AppTextStyles.enterpriseFontFamily,
          color: AppColors.enterpriseTextMuted,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ReportPhoto photo;
  final int index;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.photo,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = PhotoBytesCache.get(photo.id);
    final stamp = photo.stamp;
    final note = stamp.note?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: AppRadii.control,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null && !photo.needsReselect)
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    semanticLabel: 'Foto dokumentasi $index',
                  )
                else
                  Container(
                    color: AppColors.enterpriseSurface,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    alignment: Alignment.center,
                    child: Text(
                      'Berkas foto tidak tersimpan. Hapus lalu potret ulang.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterprisePrimary,
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Semantics(
                    button: true,
                    label: 'Hapus foto $index',
                    child: InkWell(
                      onTap: onDelete,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xB3000000),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          note == null || note.isEmpty ? 'Foto $index' : note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMain,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${StampRenderer.formatStampTime(stamp.capturedAt)}'
          '${photo.source == PhotoSource.gallery ? ' · Galeri' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMuted,
          ),
        ),
      ],
    );
  }
}

class _RejectedDialog extends StatelessWidget {
  final List<PhotoImportResult> rejected;
  const _RejectedDialog({required this.rejected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${rejected.length} foto ditolak'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in rejected)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(item.error ?? ''),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}
