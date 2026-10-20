import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/geo_stamp.dart';
import '../../data/models/report_photo.dart';
import '../../services/camera_gateway.dart';
import '../../services/location_service.dart';
import '../providers/camera_providers.dart';
import '../providers/monitoring_form_provider.dart';

/// Jumlah foto maksimum per laporan.
const int kMaxReportPhotos = 10;

/// Kamera dokumentasi: memotret, menempelkan watermark geotag langsung ke
/// piksel foto, lalu menyimpannya ke draf laporan yang sedang aktif.
class KameraLapanganScreen extends ConsumerStatefulWidget {
  const KameraLapanganScreen({super.key});

  @override
  ConsumerState<KameraLapanganScreen> createState() =>
      _KameraLapanganScreenState();
}

class _Pending {
  final Uint8List bytes;
  final GeoStamp stamp;
  const _Pending(this.bytes, this.stamp);
}

class _KameraLapanganScreenState extends ConsumerState<KameraLapanganScreen> {
  CameraSession? _session;
  CameraFailure? _cameraFailure;
  bool _opening = true;

  LocationFix? _fix;
  LocationFailure? _locationFailure;
  bool _locating = true;

  bool _busy = false;
  String _busyLabel = '';
  _Pending? _pending;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_openCamera());
    unawaited(_refreshLocation());
  }

  @override
  void dispose() {
    _noteController.dispose();
    unawaited(_session?.dispose());
    super.dispose();
  }

  Future<void> _openCamera() async {
    setState(() {
      _opening = true;
      _cameraFailure = null;
    });
    try {
      final session = await ref.read(cameraGatewayProvider).open();
      if (!mounted) {
        await session.dispose();
        return;
      }
      setState(() {
        _session = session;
        _opening = false;
      });
    } on CameraUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraFailure = e.failure;
        _opening = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraFailure = CameraFailure.failed;
        _opening = false;
      });
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    final result = await ref.read(locationServiceProvider).currentFix();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _fix = result.fix;
      _locationFailure = result.failure;
    });
  }

  bool get _photoLimitReached =>
      ref.read(monitoringFormProvider).photos.length >= kMaxReportPhotos;

  Future<void> _shoot() async {
    final session = _session;
    if (_busy || session == null) return;
    if (_photoLimitReached) {
      _snack('Maksimal $kMaxReportPhotos foto per laporan.');
      return;
    }
    setState(() {
      _busy = true;
      _busyLabel = 'Mengunci lokasi…';
    });
    try {
      // Posisi diambil ulang saat memotret agar cap sesuai dengan tempat
      // petugas berdiri, bukan posisi saat layar dibuka.
      final located = await ref.read(locationServiceProvider).currentFix();
      if (!mounted) return;
      final fix = located.fix;
      if (fix == null) {
        setState(() {
          _fix = null;
          _locationFailure = located.failure;
        });
        _snack(_locationMessage(located.failure!));
        return;
      }
      setState(() {
        _fix = fix;
        _locationFailure = null;
        _busyLabel = 'Memotret…';
      });
      final raw = await session.capture();
      final capturedAt = DateTime.now();
      if (!mounted) return;
      setState(() => _busyLabel = 'Menempelkan geotag…');

      final note = _noteController.text.trim();
      final address = await ref
          .read(geocodingServiceProvider)
          .reverse(fix.latitude, fix.longitude);
      final map = await ref
          .read(mapThumbnailProvider)
          .thumbnail(fix.latitude, fix.longitude);
      final stamp = GeoStamp(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracyMeters,
        capturedAt: capturedAt,
        address: address,
        note: note.isEmpty ? null : note,
      );
      final stamped = await ref.read(stampRenderFnProvider)(
        photoBytes: raw,
        stamp: stamp,
        map: map,
      );
      if (!mounted) return;
      setState(() => _pending = _Pending(stamped, stamp));
    } catch (_) {
      if (mounted) _snack('Foto gagal diproses. Coba potret lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _accept() {
    final pending = _pending;
    if (pending == null) return;
    final notifier = ref.read(monitoringFormProvider.notifier);
    notifier.addPhoto(
      ReportPhoto.create(source: PhotoSource.camera, stamp: pending.stamp),
      pending.bytes,
    );
    final saved = notifier.saveDraft();
    setState(() {
      _pending = null;
      _noteController.clear();
    });
    final count = ref.read(monitoringFormProvider).photos.length;
    _snack(
      saved == null
          ? 'Foto ditambahkan, tetapi draf belum tersimpan.'
          : 'Foto $count tersimpan di draf.',
    );
  }

  void _retake() => setState(() => _pending = null);

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _locationMessage(LocationFailure failure) => switch (failure) {
    LocationFailure.serviceOff =>
      'GPS perangkat mati. Aktifkan lokasi lalu coba lagi.',
    LocationFailure.denied => 'Izin lokasi ditolak. Geotag membutuhkan lokasi.',
    LocationFailure.deniedForever =>
      'Izin lokasi diblokir. Buka pengaturan aplikasi untuk mengizinkan.',
    LocationFailure.timeout =>
      'Lokasi belum terkunci. Pindah ke area terbuka lalu coba lagi.',
    LocationFailure.mocked =>
      'Lokasi palsu terdeteksi. Matikan aplikasi lokasi palsu.',
    LocationFailure.unknown => 'Lokasi tidak dapat dibaca. Coba lagi.',
  };

  @override
  Widget build(BuildContext context) {
    final photoCount = ref.watch(monitoringFormProvider).photos.length;
    final housing = ref.watch(monitoringFormProvider).namaPerumahan;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildViewfinder()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                housing: housing,
                photoCount: photoCount,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (_pending == null)
              Positioned(left: 0, right: 0, bottom: 0, child: _buildControls()),
            if (_pending != null)
              Positioned.fill(
                child: _ReviewPanel(
                  pending: _pending!,
                  onRetake: _retake,
                  onAccept: _accept,
                ),
              ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x99000000),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _busyLabel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontFamily: AppTextStyles.enterpriseFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    if (_opening) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final failure = _cameraFailure;
    if (failure != null || _session == null) {
      final message = switch (failure) {
        CameraFailure.denied =>
          'Izin kamera ditolak. Izinkan kamera di pengaturan aplikasi untuk memotret.',
        CameraFailure.notFound => 'Perangkat ini tidak memiliki kamera.',
        _ =>
          'Kamera tidak dapat dibuka. Tutup aplikasi lain yang memakai kamera.',
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontFamily: AppTextStyles.enterpriseFontFamily,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: _openCamera,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final session = _session!;
    return Center(
      child: AspectRatio(
        aspectRatio: session.aspectRatio,
        child: session.buildPreview(),
      ),
    );
  }

  Widget _buildControls() {
    final cameraReady = _session != null && _cameraFailure == null;
    final canShoot = cameraReady && !_busy;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xCC000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GpsStatus(
            locating: _locating,
            fix: _fix,
            failure: _locationFailure,
            message: _locationFailure == null
                ? null
                : _locationMessage(_locationFailure!),
            onRetry: _refreshLocation,
            onOpenSettings: () =>
                ref.read(locationServiceProvider).openSettings(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: AppTextStyles.enterpriseFontFamily,
            ),
            decoration: InputDecoration(
              hintText: 'Catatan foto (opsional)',
              hintStyle: const TextStyle(color: Colors.white60),
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: const Color(0x33FFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadii.control,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            button: true,
            enabled: canShoot,
            label: 'Ambil foto bergeotag',
            child: GestureDetector(
              onTap: canShoot ? _shoot : null,
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canShoot ? Colors.white : Colors.white38,
                    width: 4,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canShoot ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String housing;
  final int photoCount;
  final VoidCallback onClose;

  const _TopBar({
    required this.housing,
    required this.photoCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tutup kamera',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamera Lapangan',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (housing.trim().isNotEmpty)
                  Text(
                    housing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$photoCount/$kMaxReportPhotos foto',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontFamily: AppTextStyles.enterpriseFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsStatus extends StatelessWidget {
  final bool locating;
  final LocationFix? fix;
  final LocationFailure? failure;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _GpsStatus({
    required this.locating,
    required this.fix,
    required this.failure,
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    if (locating) {
      text = 'Mencari lokasi GPS…';
      icon = Icons.gps_not_fixed_rounded;
    } else if (fix != null) {
      text = 'GPS siap · akurasi ±${fix!.accuracyMeters.round()} m';
      icon = Icons.gps_fixed_rounded;
    } else {
      text = message ?? 'Lokasi belum tersedia.';
      icon = Icons.location_off_outlined;
    }
    final action = failure == LocationFailure.deniedForever
        ? ('Buka pengaturan', onOpenSettings)
        : (failure != null ? ('Coba lagi', onRetry) : null);
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontFamily: AppTextStyles.enterpriseFontFamily,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action.$2,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: Text(action.$1),
          ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  final _Pending pending;
  final VoidCallback onRetake;
  final VoidCallback onAccept;

  const _ReviewPanel({
    required this.pending,
    required this.onRetake,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 56),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Image.memory(
                pending.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Ulangi'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Pakai foto ini'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
