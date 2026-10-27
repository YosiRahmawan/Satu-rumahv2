import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pengajuan/data/models/pengajuan_model.dart';
import '../../../pengajuan/presentation/providers/pengajuan_form_controller.dart';
import '../../data/models/geo_stamp.dart';
import '../../data/models/kamera_context.dart';
import '../../data/models/report_photo.dart';
import '../../services/camera_gateway.dart';
import '../../services/location_service.dart';
import '../../services/stamp_renderer.dart';
import '../providers/camera_providers.dart';
import '../providers/monitoring_form_provider.dart';
import '../providers/monitoring_list_provider.dart';
import '../widgets/kamera_flow.dart';

/// Jumlah foto maksimum per laporan.
const int kMaxReportPhotos = 10;

class _Pending {
  final Uint8List bytes;
  final GeoStamp stamp;
  const _Pending(this.bytes, this.stamp);
}

/// Kamera Lapangan fullscreen: memotret dengan kamera perangkat, mengunci GPS,
/// menempelkan watermark geotag di piksel foto, lalu menyimpannya ke draf
/// Berita Acara tugas survei (dipilih dulu bila dibuka dari mode mandiri).
class KameraLapanganScreen extends ConsumerStatefulWidget {
  final KameraContext contextData;

  const KameraLapanganScreen({
    super.key,
    this.contextData = const KameraContext.mandiri(),
  });

  @override
  ConsumerState<KameraLapanganScreen> createState() =>
      _KameraLapanganScreenState();
}

class _KameraLapanganScreenState extends ConsumerState<KameraLapanganScreen> {
  CameraSession? _session;
  CameraFailure? _cameraFailure;
  String? _cameraDetail;
  bool _opening = true;

  LocationFix? _fix;
  LocationFailure? _locationFailure;
  bool _locating = true;

  bool _isGridVisible = true;
  bool _isFlashOn = false;

  bool _busy = false;
  String _busyLabel = '';
  _Pending? _pending;
  int _savedCount = 0;
  final _noteController = TextEditingController();

  // Alamat dan peta untuk posisi terakhir, diambil lebih dulu agar overlay
  // di viewfinder sama dengan watermark pada foto dan shutter tidak menunggu.
  String? _geoKey;
  String? _liveAddress;
  Uint8List? _liveMap;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    unawaited(_openCamera());
    unawaited(_refreshLocation());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _pending == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _noteController.dispose();
    unawaited(_session?.dispose());
    super.dispose();
  }

  Future<void> _openCamera() async {
    setState(() {
      _opening = true;
      _cameraFailure = null;
      _cameraDetail = null;
    });
    try {
      final session = await ref.read(cameraGatewayProvider).open();
      if (!mounted) {
        await session.dispose();
        return;
      }
      setState(() {
        _session = session;
        _isFlashOn = false;
        _opening = false;
      });
    } on CameraUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraFailure = e.failure;
        _cameraDetail = e.detail;
        _opening = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraFailure = CameraFailure.failed;
        _cameraDetail = '$e';
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
    if (result.fix != null) unawaited(_loadGeo(result.fix!));
  }

  static String _geoKeyOf(LocationFix f) =>
      '${f.latitude.toStringAsFixed(4)},${f.longitude.toStringAsFixed(4)}';

  Future<void> _loadGeo(LocationFix fix) async {
    final key = _geoKeyOf(fix);
    if (key == _geoKey) return;
    _geoKey = key;
    setState(() {
      _liveAddress = null;
      _liveMap = null;
    });
    final address = await ref
        .read(geocodingServiceProvider)
        .reverse(fix.latitude, fix.longitude);
    final map = await ref
        .read(mapThumbnailProvider)
        .thumbnail(fix.latitude, fix.longitude);
    if (!mounted || _geoKey != key) return;
    setState(() {
      _liveAddress = address;
      _liveMap = map;
    });
  }

  Future<void> _toggleFlash() async {
    final session = _session;
    if (session == null) return;
    final next = !_isFlashOn;
    final ok = await session.setFlash(next);
    if (!mounted) return;
    if (ok) {
      setState(() => _isFlashOn = next);
    } else {
      _snack('Flash tidak tersedia di perangkat ini.');
    }
  }

  Future<void> _shoot() async {
    final session = _session;
    if (_busy || session == null) return;
    setState(() {
      _busy = true;
      _busyLabel = 'Mengunci lokasi…';
    });
    try {
      // Posisi diambil ulang saat memotret agar cap sesuai tempat petugas
      // berdiri, bukan posisi saat layar dibuka.
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
      final reuse =
          _geoKeyOf(fix) == _geoKey &&
          (_liveAddress != null || _liveMap != null);
      final address = reuse
          ? _liveAddress
          : await ref
                .read(geocodingServiceProvider)
                .reverse(fix.latitude, fix.longitude);
      final map = reuse
          ? _liveMap
          : await ref
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

  Pengajuan? _findTask(String id) {
    for (final p in ref.read(surveyAktifProvider)) {
      if (p.id == id) return p;
    }
    for (final p in ref.read(pengajuanListProvider)) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _save() async {
    final pending = _pending;
    if (pending == null) return;
    final ctx = widget.contextData;
    final notifier = ref.read(monitoringFormProvider.notifier);

    if (!ctx.usesActiveForm) {
      final task = ctx.isTaskFlow
          ? _findTask(ctx.taskId ?? '')
          : await _pickTask();
      if (task == null) {
        if (ctx.isTaskFlow && mounted) {
          _snack('Tugas survei tidak ditemukan. Foto belum disimpan.');
        }
        return;
      }
      prepareFormForPengajuan(ref, task);
    }

    if (ref.read(monitoringFormProvider).photos.length >= kMaxReportPhotos) {
      _snack('Maksimal $kMaxReportPhotos foto per laporan.');
      return;
    }
    notifier.addPhoto(
      ReportPhoto.create(source: PhotoSource.camera, stamp: pending.stamp),
      pending.bytes,
    );
    final saved = notifier.saveDraft();
    if (!mounted) return;
    setState(() {
      _pending = null;
      _savedCount++;
      _noteController.clear();
    });
    final count = ref.read(monitoringFormProvider).photos.length;
    _snack(
      saved == null
          ? 'Foto ditambahkan, tetapi draf belum tersimpan.'
          : 'Foto $count tersimpan di draf Berita Acara.',
    );
  }

  /// Mode mandiri: foto harus punya tujuan, yaitu draf sebuah tugas survei.
  Future<Pengajuan?> _pickTask() async {
    final tasks = ref.read(surveyAktifProvider);
    if (tasks.isEmpty) {
      _snack(
        'Belum ada tugas survei aktif, jadi foto belum bisa disimpan ke draf.',
      );
      return null;
    }
    if (tasks.length == 1) return tasks.first;
    return showModalBottomSheet<Pengajuan>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Simpan foto ke tugas mana?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final task in tasks)
              ListTile(
                title: Text(task.namaPerumahan),
                subtitle: Text(task.namaPt),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheetContext).pop(task),
              ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _pending != null
                  ? _buildPhotoReviewLayout(_pending!)
                  : _buildLiveCameraLayout(),
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
                        const SizedBox(height: 16),
                        Text(
                          _busyLabel,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
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

  // ==========================================
  // LIVE CAMERA
  // ==========================================
  Widget _buildLiveCameraLayout() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF0F172A)),
              if (_session != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: _session!.aspectRatio,
                    child: _session!.buildPreview(),
                  ),
                ),
              if (_session != null && _isGridVisible)
                const IgnorePointer(
                  child: CustomPaint(painter: _GridPainter()),
                ),
              if (_session != null) _buildCenterFocusBracket(),
              if (_session != null && _fix != null)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: _LiveStampOverlay(
                      fix: _fix!,
                      address: _liveAddress,
                      map: _liveMap,
                      note: _noteController,
                    ),
                  ),
                ),
              if (_opening)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (_session == null)
                _buildCameraProblemCard(),
            ],
          ),
        ),
        _buildInfoCard(),
        _buildShutterControlsBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    final isTask = widget.contextData.isTaskFlow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withValues(alpha: 0.85),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              minimumSize: const Size(48, 48),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isTask
                            ? AppColors.primaryRed
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isTask
                            ? 'Tugas: ${widget.contextData.taskTitle}'
                            : 'Dokumentasi Mandiri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildGpsChip(),
        ],
      ),
    );
  }

  Widget _buildGpsChip() {
    final String text;
    final IconData icon;
    final Color color;
    if (_locating) {
      text = 'Mencari GPS…';
      icon = Icons.gps_not_fixed_rounded;
      color = const Color(0xFFFBBF24);
    } else if (_fix != null) {
      text = 'GPS ±${_fix!.accuracyMeters.round()} m';
      icon = Icons.gps_fixed_rounded;
      color = const Color(0xFF34D399);
    } else {
      text = 'GPS belum siap';
      icon = Icons.location_off_outlined;
      color = const Color(0xFFF87171);
    }
    return InkWell(
      onTap: _locating ? null : _refreshLocation,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFocusBracket() {
    return Center(
      child: IgnorePointer(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.75),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraProblemCard() {
    final failure = _cameraFailure;
    final message = switch (failure) {
      CameraFailure.denied =>
        kIsWeb
            ? 'Izin kamera ditolak. Klik ikon gembok di address bar browser, izinkan Kamera dan Lokasi, lalu tekan Coba lagi.'
            : 'Izin kamera ditolak. Buka Pengaturan > Aplikasi > Satu Rumah > Izin, aktifkan Kamera dan Lokasi.',
      CameraFailure.notFound => 'Perangkat ini tidak memiliki kamera.',
      _ =>
        'Kamera tidak dapat dibuka. Tutup aplikasi lain yang memakai kamera lalu coba lagi.',
    };
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (_cameraDetail != null) ...[
              const SizedBox(height: 8),
              Text(
                _cameraDetail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 10.5),
              ),
            ],
            const SizedBox(height: 14),
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

  /// Kartu informasi: konteks tugas, posisi terkini, dan catatan foto.
  Widget _buildInfoCard() {
    final ctx = widget.contextData;
    final contextLabel = ctx.isTaskFlow
        ? 'Tugas: ${ctx.taskTitle}'
        : 'Mode Mandiri (pilih tugas saat menyimpan)';
    final fix = _fix;
    final locationLine = fix != null
        ? '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)} · ±${fix.accuracyMeters.round()} m'
        : (_locationFailure != null
              ? _locationMessage(_locationFailure!)
              : 'Mencari lokasi GPS…');
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (fix == null) const SizedBox(height: 4),
          if (fix == null)
            Row(
              children: [
                Icon(
                  fix != null
                      ? Icons.location_on_outlined
                      : Icons.location_off_outlined,
                  size: 13,
                  color: fix != null
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      color: fix != null
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFCA5A5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_locationFailure == LocationFailure.deniedForever)
                  TextButton(
                    onPressed: () =>
                        ref.read(locationServiceProvider).openSettings(),
                    child: const Text('Pengaturan'),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Catatan foto (opsional, ikut dicetak)',
              hintStyle: const TextStyle(color: Colors.white54),
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_savedCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$_savedCount foto tersimpan dari sesi ini',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShutterControlsBar() {
    final canShoot = _session != null && !_busy;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      color: Colors.black.withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Flash',
                onPressed: _session == null ? null : _toggleFlash,
                icon: Icon(
                  _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isFlashOn ? const Color(0xFFFBBF24) : Colors.white70,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  minimumSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Garis bantu grid',
                onPressed: () =>
                    setState(() => _isGridVisible = !_isGridVisible),
                icon: Icon(
                  _isGridVisible
                      ? Icons.grid_on_rounded
                      : Icons.grid_off_rounded,
                  color: _isGridVisible
                      ? const Color(0xFF60A5FA)
                      : Colors.white70,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
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
          // Penyeimbang agar shutter tetap di tengah.
          const SizedBox(width: 104),
        ],
      ),
    );
  }

  // ==========================================
  // PHOTO REVIEW
  // ==========================================
  Widget _buildPhotoReviewLayout(_Pending pending) {
    final isTask = widget.contextData.isTaskFlow;
    final saveLabel = isTask ? 'Simpan ke Draf BA' : 'Pilih tugas & simpan';
    final stamp = pending.stamp;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black.withValues(alpha: 0.85),
          width: double.infinity,
          child: const Text(
            'Pratinjau Bukti Lapangan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF0F172A),
            alignment: Alignment.center,
            child: Image.memory(
              pending.bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          color: Colors.black.withValues(alpha: 0.95),
          child: Text(
            '${StampRenderer.formatStampTime(stamp.capturedAt)}\n'
            '${StampRenderer.formatStampCoordinates(stamp)}'
            '${stamp.address == null ? '\nAlamat tidak tersedia (offline), hanya koordinat.' : '\n${stamp.address}'}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          color: Colors.black.withValues(alpha: 0.95),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _pending = null),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Foto Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    saveLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Garis bantu 3x3 (rule of thirds).
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pratinjau watermark langsung di viewfinder: tata letak sama dengan cap
/// yang ditempel ke foto (peta kiri bawah, teks rata kanan).
class _LiveStampOverlay extends StatelessWidget {
  final LocationFix fix;
  final String? address;
  final Uint8List? map;
  final TextEditingController note;

  const _LiveStampOverlay({
    required this.fix,
    required this.address,
    required this.map,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    const shadows = [
      Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(0, 1)),
    ];
    TextStyle style(double size, FontWeight weight) => TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      color: Colors.white,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      shadows: shadows,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 28, 6, 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x99000000)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (map != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(map!, fit: BoxFit.cover),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Icon(
                          Icons.location_on,
                          color: Color(0xFFB91C1C),
                          size: 26,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 3,
                      bottom: 1,
                      child: Text(
                        '© OpenStreetMap',
                        style: TextStyle(
                          fontSize: 7,
                          color: Color(0xFF222222),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ListenableBuilder(
              listenable: note,
              builder: (context, _) {
                final text = note.text.trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (text.isNotEmpty)
                      Text(
                        text,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style(13, FontWeight.w800),
                      ),
                    Text(
                      StampRenderer.formatStampTime(DateTime.now()),
                      textAlign: TextAlign.right,
                      style: style(13, FontWeight.w800),
                    ),
                    if (address != null)
                      Text(
                        address!,
                        textAlign: TextAlign.right,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: style(11, FontWeight.w700),
                      ),
                    Text(
                      '${fix.latitude.toStringAsFixed(6)}, '
                      '${fix.longitude.toStringAsFixed(6)} · '
                      '±${fix.accuracyMeters.round()} m',
                      textAlign: TextAlign.right,
                      style: style(10.5, FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
