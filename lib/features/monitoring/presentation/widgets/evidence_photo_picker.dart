import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../data/models/evidence_photo_item.dart';
import '../../utils/exif_geo_reader.dart';

typedef PhotoPathPicker = Future<List<String>> Function();
typedef CameraPhotoPicker = Future<String?> Function();

class EvidencePhotoPicker extends StatefulWidget {
  final List<String> photoPaths;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;
  final PhotoPathPicker? pickPhotoPaths;
  final CameraPhotoPicker? pickCameraPhoto;

  /// Baris status lokasi di bagian bawah kartu foto (indeks mengikuti
  /// [photoPaths]). Bila null, kartu tidak menampilkan status.
  final Widget Function(int index)? photoStatusBuilder;

  /// Dipanggil untuk setiap foto yang baru ditambahkan: pertama dengan asal
  /// foto saja, lalu sekali lagi bila berkas memuat GPS tertanam (EXIF).
  /// Hanya melaporkan; tidak pernah menentukan lokasi petugas.
  final void Function(String path, PhotoOrigin origin, ExifGeo? exif)?
  onPhotoPicked;

  /// Dipanggil saat kartu foto diketuk (mis. membuka lembar lokasi).
  final ValueChanged<int>? onPhotoTap;

  /// Apakah mode pemilihan foto aktif.
  final bool isSelectionMode;

  /// Set indeks foto yang dipilih.
  final Set<int> selectedIndices;

  /// Callback ketika pilihan foto di-toggle.
  final ValueChanged<int>? onToggleSelect;

  const EvidencePhotoPicker({
    super.key,
    required this.photoPaths,
    required this.onPhotosChanged,
    this.maxPhotos = 10,
    this.pickPhotoPaths,
    this.pickCameraPhoto,
    this.photoStatusBuilder,
    this.onPhotoTap,
    this.onPhotoPicked,
    this.isSelectionMode = false,
    this.selectedIndices = const {},
    this.onToggleSelect,
  });

  static final Map<String, Uint8List> _bytesCache = {};

  static Uint8List? getCachedBytes(String path) => _bytesCache[path];

  static void cacheBytes(String path, Uint8List bytes) {
    _bytesCache[path] = bytes;
  }

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
      _pickRequestId++;
    }
  }

  @override
  void dispose() {
    _pickRequestId++;
    super.dispose();
  }

  Future<List<String>> _pickFromDevice() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final paths = <String>[];
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final key = file.path.isNotEmpty ? file.path : file.name;
          EvidencePhotoPicker.cacheBytes(key, bytes);
          paths.add(key);
        }
        return paths;
      }
    } catch (e) {
      debugPrint('ImagePicker.pickMultiImage: $e');
    }

    try {
      final pickedFiles = await FilePickerUtil.pickMultipleFiles(
        allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
      );
      final paths = <String>[];
      for (final file in pickedFiles) {
        final key = file.path ?? file.name;
        if (file.bytes != null) {
          EvidencePhotoPicker.cacheBytes(key, file.bytes!);
        } else if (file.path != null) {
          try {
            final xFile = XFile(file.path!);
            final bytes = await xFile.readAsBytes();
            EvidencePhotoPicker.cacheBytes(key, bytes);
          } catch (_) {}
        }
        paths.add(key);
      }
      return paths;
    } catch (_) {
      return [];
    }
  }

  Future<String?> _pickFromCamera() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final key = photo.path.isNotEmpty ? photo.path : photo.name;
      EvidencePhotoPicker.cacheBytes(key, bytes);
      return key;
    }
    return null;
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
      final added = updated
          .where((path) => !widget.photoPaths.contains(path))
          .toList();
      if (updated.length != widget.photoPaths.length) {
        widget.onPhotosChanged(updated);
        await _reportPicked(
          added,
          camera ? PhotoOrigin.camera : PhotoOrigin.gallery,
        );
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

  Future<void> _reportPicked(List<String> paths, PhotoOrigin origin) async {
    final report = widget.onPhotoPicked;
    if (report == null) return;
    for (final path in paths) {
      report(path, origin, null);
    }
    for (final path in paths) {
      final bytes = EvidencePhotoPicker.getCachedBytes(path);
      if (bytes == null) continue;
      final exif = await readExifGeo(bytes);
      if (exif == null || !mounted) continue;
      report(path, origin, exif);
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tambah Dokumentasi',
                style: TextStyle(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.enterpriseTextMain,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Pilih sumber foto bukti fisik monitoring lapangan',
                style: TextStyle(
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                  fontSize: 12,
                  color: AppColors.enterpriseTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              _buildPickerOption(
                context: context,
                icon: Icons.photo_camera_outlined,
                iconColor: AppColors.enterprisePrimary,
                iconBgColor: AppColors.enterprisePrimarySurface,
                title: 'Ambil Foto Langsung',
                subtitle: 'Gunakan kamera perangkat secara langsung',
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 12),
              _buildPickerOption(
                context: context,
                icon: Icons.photo_library_outlined,
                iconColor: AppColors.enterprisePrimaryDark,
                iconBgColor: AppColors.enterprisePrimarySurfaceSoft,
                title: 'Pilih dari Galeri / Berkas',
                subtitle: 'Upload foto yang sudah tersedia di memori',
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) await _pickPhotos(camera: choice);
  }

  Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.enterpriseTextMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        fontSize: 11,
                        color: AppColors.enterpriseTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
    final removed = widget.photoPaths[index];
    EvidencePhotoPicker._bytesCache.remove(removed);
    final updated = List<String>.from(widget.photoPaths)..removeAt(index);
    widget.onPhotosChanged(updated);
  }

  Future<Uint8List?> _loadPhotoBytes(String path) async {
    final cached = EvidencePhotoPicker.getCachedBytes(path);
    if (cached != null) return cached;

    if (path.isEmpty ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return null;
    }

    try {
      final xFile = XFile(path);
      final bytes = await xFile.readAsBytes();
      EvidencePhotoPicker.cacheBytes(path, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _buildPhotoPreview(String path) {
    final cachedBytes = EvidencePhotoPicker.getCachedBytes(path);
    if (cachedBytes != null) {
      return Image.memory(
        cachedBytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildImageError(),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildImageError(),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _loadPhotoBytes(path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _buildImageError(),
          );
        }
        return _buildImageError();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoPaths = widget.photoPaths;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Foto dokumentasi',
                        style: TextStyle(
                          fontFamily: AppTextStyles.enterpriseFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.enterpriseTextMain,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.enterprisePrimarySurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${photoPaths.length}/${widget.maxPhotos}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.enterpriseFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.enterprisePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Maks. 10MB/foto',
                    style: TextStyle(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: photoPaths.isEmpty
                      ? 0
                      : photoPaths.length / widget.maxPhotos,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.enterprisePrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: (photoPaths.length < widget.maxPhotos)
                    ? photoPaths.length + 1
                    : photoPaths.length,
                itemBuilder: (context, index) {
                  if (index == photoPaths.length &&
                      photoPaths.length < widget.maxPhotos) {
                    return _buildAddPhotoCard();
                  }

                  final path = photoPaths[index];
                  return _buildPhotoCard(path, index);
                },
              ),
              if (_isPicking) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.enterprisePrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Memproses foto…',
                  style: TextStyle(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    fontSize: 11,
                    color: AppColors.enterpriseTextMuted,
                  ),
                ),
              ],
            ],
          ),
        );

        if (constraints.hasBoundedHeight) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }

  Widget _buildPhotoCard(String path, int index) {
    final isSelected = widget.selectedIndices.contains(index);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animValue),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.isSelectionMode) {
            widget.onToggleSelect?.call(index);
          } else {
            widget.onPhotoTap?.call(index);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.enterprisePrimary
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.enterprisePrimary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhotoPreview(path),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          widget.onToggleSelect?.call(index);
                        },
                        child: Semantics(
                          label: 'Pilih foto ${index + 1}',
                          checked: isSelected,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.enterprisePrimary
                                  : (widget.isSelectionMode
                                        ? Colors.black.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.3)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : (widget.isSelectionMode
                                          ? Colors.white
                                          : Colors.white70),
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (!widget.isSelectionMode)
                        IconButton(
                          tooltip: 'Hapus foto ${index + 1}',
                          onPressed: () => _confirmDelete(index),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.enterprisePrimary,
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black45,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dokumentasi ${index + 1}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.enterpriseFontFamily,
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.photoStatusBuilder != null) ...[
                        const SizedBox(height: 2),
                        widget.photoStatusBuilder!(index),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return Semantics(
      button: true,
      label: 'Tambah foto dokumentasi',
      hint: 'Pilih kamera atau galeri',
      child: Material(
        color: const Color(0xFFFFF1F2).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _showPickerOptions,
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: const DashedRRectPainter(
              color: Color(0xFFFCA5A5),
              strokeWidth: 2,
              radius: 16,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.enterprisePrimarySurface.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 24,
                        color: AppColors.enterprisePrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambah foto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterprisePrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ambil kamera atau dari galeri',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const DashedRRectPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.radius = 16.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}
