import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';

typedef PhotoPathPicker = Future<List<String>> Function();
typedef CameraPhotoPicker = Future<String?> Function();

class EvidencePhotoPicker extends StatefulWidget {
  final List<String> photoPaths;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;
  final PhotoPathPicker? pickPhotoPaths;
  final CameraPhotoPicker? pickCameraPhoto;

  const EvidencePhotoPicker({
    super.key,
    required this.photoPaths,
    required this.onPhotosChanged,
    this.maxPhotos = 10,
    this.pickPhotoPaths,
    this.pickCameraPhoto,
  });

  @override
  State<EvidencePhotoPicker> createState() => _EvidencePhotoPickerState();
}

class _EvidencePhotoPickerState extends State<EvidencePhotoPicker> {
  int _pickRequestId = 0;
  bool _isPicking = false;

  @override
  void didUpdateWidget(covariant EvidencePhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.photoPaths, widget.photoPaths)) {
      // A parent update supersedes any picker result that is still pending.
      _pickRequestId++;
    }
  }

  @override
  void dispose() {
    // Invalidate callbacks awaiting the native file picker before disposal.
    _pickRequestId++;
    super.dispose();
  }

  Future<List<String>> _pickFromDevice() async {
    final pickedFiles = await FilePickerUtil.pickMultipleFiles(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
    );
    return pickedFiles.map((file) => file.path ?? file.name).toList();
  }

  Future<String?> _pickFromCamera() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    return photo?.path;
  }

  Future<void> _pickPhotos({required bool camera}) async {
    final requestId = ++_pickRequestId;
    setState(() => _isPicking = true);
    try {
      final cameraPath = camera
          ? await (widget.pickCameraPhoto ?? _pickFromCamera)()
          : null;
      final pickedPaths = camera
          ? (cameraPath == null ? <String>[] : [cameraPath])
          : await (widget.pickPhotoPaths ?? _pickFromDevice)();

      if (!mounted || requestId != _pickRequestId || pickedPaths.isEmpty) {
        return;
      }

      final updated = List<String>.from(widget.photoPaths);
      for (final path in pickedPaths.where((path) => path.trim().isNotEmpty)) {
        if (updated.length >= widget.maxPhotos) break;
        if (!updated.contains(path)) updated.add(path);
      }
      if (updated.length != widget.photoPaths.length) {
        widget.onPhotosChanged(updated);
      }
    } catch (error) {
      if (mounted && requestId == _pickRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              camera
                  ? 'Kamera tidak dapat digunakan. Periksa izin kamera lalu coba lagi.'
                  : 'Berkas foto tidak dapat dipilih. Coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _pickRequestId) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _showPickerOptions() async {
    if (widget.photoPaths.length >= widget.maxPhotos) return;
    if (widget.pickCameraPhoto == null && widget.pickPhotoPaths != null) {
      await _pickPhotos(camera: false);
      return;
    }
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil Foto Langsung'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri / Berkas'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) await _pickPhotos(camera: choice);
  }

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: const Text('Foto ini akan dihapus dari dokumentasi sesi ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _pickRequestId++;
    final updated = List<String>.from(widget.photoPaths)..removeAt(index);
    widget.onPhotosChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final photoPaths = widget.photoPaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Foto dokumentasi',
                style: AppTextStyles.titleMedium.copyWith(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  color: AppColors.enterpriseTextMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${photoPaths.length}/${widget.maxPhotos}',
              style: AppTextStyles.labelMedium.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                color: AppColors.enterpriseTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: photoPaths.isEmpty ? 0 : photoPaths.length / widget.maxPhotos,
          minHeight: 6,
          borderRadius: AppRadii.pill,
          backgroundColor: AppColors.enterprisePrimarySurface,
          valueColor: const AlwaysStoppedAnimation(AppColors.enterprisePrimary),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: (photoPaths.length < widget.maxPhotos)
              ? photoPaths.length + 1
              : photoPaths.length,
          itemBuilder: (context, index) {
            if (index == photoPaths.length &&
                photoPaths.length < widget.maxPhotos) {
              return Semantics(
                button: true,
                label: 'Tambah foto dokumentasi',
                hint: 'Pilih kamera atau galeri',
                child: InkWell(
                  onTap: _showPickerOptions,
                  borderRadius: AppRadii.control,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.enterprisePrimarySurfaceSoft,
                      borderRadius: AppRadii.control,
                      border: Border.all(
                        color: AppColors.enterprisePrimaryBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.enterprisePrimary,
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tambah foto',
                          style: TextStyle(
                            color: AppColors.enterprisePrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final path = photoPaths[index];
            final isUrl = path.startsWith('http');

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: AppRadii.control,
                  child: isUrl
                      ? Image.network(
                          path,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildImageError(),
                        )
                      : Image.file(
                          File(path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildImageError(),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Semantics(
                    button: true,
                    label: 'Hapus foto ${index + 1}',
                    child: IconButton(
                      tooltip: 'Hapus foto ${index + 1}',
                      onPressed: () => _confirmDelete(index),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.enterprisePrimary,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (_isPicking) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(
            'Memproses foto…',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageError() {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, color: AppColors.grey600, size: 24),
            SizedBox(height: 2),
            Text(
              'Foto Evidence',
              style: TextStyle(fontSize: 9, color: AppColors.grey700),
            ),
          ],
        ),
      ),
    );
  }
}
