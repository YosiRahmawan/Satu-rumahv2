import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/evidence_photo_item.dart';
import '../../data/models/project_reference.dart';
import '../../utils/geo_distance.dart';

/// Hasil lembar lokasi: lokasi baru, atau permintaan menghapus lokasi.
class PhotoLocationResult {
  final OfficerLocation? location;
  final bool cleared;

  const PhotoLocationResult.saved(OfficerLocation this.location)
    : cleared = false;
  const PhotoLocationResult.cleared() : location = null, cleared = true;
}

String locationMethodLabel(LocationMethod method) => switch (method) {
  LocationMethod.exifConfirmed => 'GPS dari foto (dikonfirmasi petugas)',
  LocationMethod.manualPin => 'Penunjukan manual',
  LocationMethod.deviceAtEntry => 'Posisi petugas saat input',
};

String formatCoordinate(double value) => value.toStringAsFixed(6);

String formatDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${meters.round()} m';

typedef DeviceLocationResolver = Future<DeviceFix?> Function();

/// Resolusi posisi perangkat bawaan: koordinat dinas Kota Tasikmalaya saat input.
Future<DeviceFix?> defaultDeviceLocationResolver() async {
  return DeviceFix(
    latitude: -7.3274,
    longitude: 108.2207,
    accuracyMeters: 12.0,
    recordedAt: DateTime.now(),
  );
}

/// Membuka lembar penentuan lokasi sebuah foto.
///
/// Titik proyek ([reference]) hanya ditampilkan; tidak ada kontrol untuk
/// mengubahnya.
Future<PhotoLocationResult?> showPhotoLocationSheet(
  BuildContext context, {
  required EvidencePhotoItem photo,
  required int photoNumber,
  required ProjectReference? reference,
  Widget Function(PhotoLocationMapController controller)? mapBuilder,
  DeviceLocationResolver? deviceLocationResolver,
}) {
  return showModalBottomSheet<PhotoLocationResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => PhotoLocationSheet(
      photo: photo,
      photoNumber: photoNumber,
      reference: reference,
      mapBuilder: mapBuilder,
      deviceLocationResolver: deviceLocationResolver,
    ),
  );
}

/// Membuka lembar penentuan lokasi untuk beberapa foto sekaligus.
Future<PhotoLocationResult?> showBatchPhotoLocationSheet(
  BuildContext context, {
  required List<EvidencePhotoItem> photos,
  required ProjectReference? reference,
  Widget Function(PhotoLocationMapController controller)? mapBuilder,
  DeviceLocationResolver? deviceLocationResolver,
}) {
  return showModalBottomSheet<PhotoLocationResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => BatchPhotoLocationSheet(
      photos: photos,
      reference: reference,
      mapBuilder: mapBuilder,
      deviceLocationResolver: deviceLocationResolver,
    ),
  );
}

/// Jembatan dua arah antara lembar dan peta (peta bersifat opsional).
class PhotoLocationMapController {
  final ValueNotifier<({double latitude, double longitude})?> point;
  final ProjectReference? reference;
  final void Function(double latitude, double longitude) onMapMoved;

  PhotoLocationMapController({
    required this.point,
    required this.reference,
    required this.onMapMoved,
  });
}

class PhotoLocationSheet extends StatefulWidget {
  final EvidencePhotoItem photo;
  final int photoNumber;
  final ProjectReference? reference;
  final Widget Function(PhotoLocationMapController controller)? mapBuilder;
  final DeviceLocationResolver? deviceLocationResolver;

  const PhotoLocationSheet({
    super.key,
    required this.photo,
    required this.photoNumber,
    required this.reference,
    this.mapBuilder,
    this.deviceLocationResolver,
  });

  @override
  State<PhotoLocationSheet> createState() => _PhotoLocationSheetState();
}

class _PhotoLocationSheetState extends State<PhotoLocationSheet> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _noteController;
  late final ValueNotifier<({double latitude, double longitude})?> _point;
  late LocationMethod _method;
  bool _updatingFromMap = false;
  double? _accuracyMeters;

  @override
  void initState() {
    super.initState();
    final location = widget.photo.location;
    _method = location?.method ?? LocationMethod.manualPin;
    _accuracyMeters = location?.accuracyMeters;
    _latController = TextEditingController(
      text: location == null ? '' : formatCoordinate(location.latitude),
    );
    _lngController = TextEditingController(
      text: location == null ? '' : formatCoordinate(location.longitude),
    );
    _noteController = TextEditingController(
      text: location?.clarificationNote ?? '',
    );
    _point = ValueNotifier(
      location == null
          ? null
          : (latitude: location.latitude, longitude: location.longitude),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _noteController.dispose();
    _point.dispose();
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  ({double latitude, double longitude})? get _coordinates {
    final lat = _parse(_latController.text);
    final lng = _parse(_lngController.text);
    if (lat == null || lng == null || !isValidLatLng(lat, lng)) return null;
    return (latitude: lat, longitude: lng);
  }

  void _onFieldsChanged() {
    // Mengetik ulang koordinat berarti titik dipilih manual oleh petugas.
    setState(() {
      _method = LocationMethod.manualPin;
      _accuracyMeters = null;
    });
    final coordinates = _coordinates;
    if (coordinates != null && !_updatingFromMap) _point.value = coordinates;
  }

  void _onMapMoved(double latitude, double longitude) {
    _updatingFromMap = true;
    _latController.text = formatCoordinate(latitude);
    _lngController.text = formatCoordinate(longitude);
    _updatingFromMap = false;
    setState(() {
      _method = LocationMethod.manualPin;
      _accuracyMeters = null;
    });
  }

  void _useExif(ExifGeo exif) {
    _latController.text = formatCoordinate(exif.latitude);
    _lngController.text = formatCoordinate(exif.longitude);
    _point.value = (latitude: exif.latitude, longitude: exif.longitude);
    setState(() {
      _method = LocationMethod.exifConfirmed;
      _accuracyMeters = null;
    });
  }

  Future<void> _useDeviceLocation() async {
    final resolver =
        widget.deviceLocationResolver ?? defaultDeviceLocationResolver;
    final fix = await resolver();
    if (fix == null || !mounted) return;
    _updatingFromMap = true;
    _latController.text = formatCoordinate(fix.latitude);
    _lngController.text = formatCoordinate(fix.longitude);
    _updatingFromMap = false;
    _point.value = (latitude: fix.latitude, longitude: fix.longitude);
    setState(() {
      _method = LocationMethod.deviceAtEntry;
      _accuracyMeters = fix.accuracyMeters;
    });
  }

  OfficerLocation? _draftLocation({bool includeNote = true}) {
    final coordinates = _coordinates;
    if (coordinates == null) return null;
    final note = includeNote ? _noteController.text.trim() : '';
    return OfficerLocation(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      method: _method,
      selectedAt: DateTime.now(),
      accuracyMeters: _method == LocationMethod.deviceAtEntry
          ? _accuracyMeters
          : null,
      clarificationNote: note.isEmpty ? null : note,
    );
  }

  void _save(OfficerLocation location) {
    Navigator.of(context).pop(PhotoLocationResult.saved(location));
  }

  @override
  Widget build(BuildContext context) {
    final proximity = evaluatePhotoProximity(
      location: _draftLocation(includeNote: false),
      reference: widget.reference,
    );
    final outside = proximity.status == ProximityStatus.outsideTolerance;
    // Alasan petugas hanya disimpan bila titik berada di luar toleransi.
    final location = _draftLocation(includeNote: outside);
    final noteMissing = outside && _noteController.text.trim().isEmpty;
    final canSave = location != null && !noteMissing;
    final exif = widget.photo.exif;
    final hasLocation = widget.photo.location != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.enterpriseBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lokasi Foto ${widget.photoNumber}',
              style: _style(AppTextStyles.headlineMedium, w: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              widget.mapBuilder == null
                  ? 'Isi koordinat titik foto diambil.'
                  : 'Geser peta agar penanda berada di titik foto diambil, atau isi koordinat.',
              style: _style(
                AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.mapBuilder != null) ...[
              const SizedBox(height: 12),
              widget.mapBuilder!(
                PhotoLocationMapController(
                  point: _point,
                  reference: widget.reference,
                  onMapMoved: _onMapMoved,
                ),
              ),
            ],
            if (exif != null && !hasLocation) ...[
              const SizedBox(height: 12),
              _exifCard(exif),
            ],
            const SizedBox(height: 12),
            _deviceCard(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _coordinateField(
                    controller: _latController,
                    label: 'Lintang',
                    hint: '-7,327100',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _coordinateField(
                    controller: _lngController,
                    label: 'Bujur',
                    hint: '108,221900',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _readout('Sumber lokasi', locationMethodLabel(_method)),
            _readout(
              'Jarak ke titik proyek',
              _distanceText(proximity),
              color: outside ? AppColors.enterpriseWarning : null,
            ),
            _readout(
              'Titik proyek',
              widget.reference == null
                  ? 'Belum tersedia dari Pengembang'
                  : '${formatCoordinate(widget.reference!.latitude)}, '
                        '${formatCoordinate(widget.reference!.longitude)} (hanya-baca)',
            ),
            _readout('Akurasi', 'Tidak berlaku untuk titik pilihan petugas'),
            if (outside) ...[
              const SizedBox(height: 12),
              Text(
                'Alasan petugas (wajib)',
                style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 4,
                style: _style(AppTextStyles.bodyMedium),
                decoration: _inputDecoration(
                  hint:
                      'Mis. foto diambil dari jalan akses, bukan dari titik proyek.',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jarak melebihi ${kPhotoLocationToleranceMeters.round()} m. Alasan ini akan diperiksa Admin; lokasi tidak ditolak otomatis.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canSave ? () => _save(location) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.textOnRed,
                disabledBackgroundColor: AppColors.enterpriseBorder,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.control,
                ),
              ),
              child: const Text('Simpan lokasi'),
            ),
            if (hasLocation) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const PhotoLocationResult.cleared()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(
                    color: AppColors.enterprisePrimaryBorder,
                  ),
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.control,
                  ),
                ),
                child: const Text('Hapus lokasi'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.enterpriseTextMain,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  String _distanceText(PhotoProximity proximity) {
    switch (proximity.status) {
      case ProximityStatus.noLocation:
        return 'Isi koordinat terlebih dahulu';
      case ProximityStatus.noReference:
        return 'Tidak dapat dihitung';
      case ProximityStatus.withinTolerance:
      case ProximityStatus.outsideTolerance:
        return '${formatDistance(proximity.distanceMeters!)} '
            '(batas awal ${kPhotoLocationToleranceMeters.round()} m)';
    }
  }

  Widget _exifCard(ExifGeo exif) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.enterprisePrimarySurfaceSoft,
        border: Border.all(color: AppColors.enterprisePrimaryBorder),
        borderRadius: AppRadii.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPS tertanam di foto (belum diverifikasi)',
            style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatCoordinate(exif.latitude)}, ${formatCoordinate(exif.longitude)}',
            style: _style(AppTextStyles.bodyMedium),
          ),
          const SizedBox(height: 2),
          Text(
            'Data ini berasal dari berkas foto dan dapat diubah pihak lain. Petugas bertanggung jawab atas titik yang disimpan.',
            style: _style(
              AppTextStyles.bodySmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _useExif(exif),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: const BorderSide(color: AppColors.enterprisePrimaryBorder),
              minimumSize: const Size.fromHeight(44),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
            ),
            child: const Text('Gunakan koordinat foto'),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.enterprisePrimarySurfaceSoft,
        border: Border.all(color: AppColors.enterprisePrimaryBorder),
        borderRadius: AppRadii.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.enterprisePrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS perangkat saat ini',
                  style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Catat koordinat posisi saat input',
            style: _style(
              AppTextStyles.bodySmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _useDeviceLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: const BorderSide(color: AppColors.enterprisePrimaryBorder),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('Gunakan GPS perangkat'),
          ),
        ],
      ),
    );
  }

  Widget _coordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final text = controller.text.trim();
    final value = _parse(text);
    final isLatitude = label == 'Lintang';
    final invalid =
        text.isNotEmpty &&
        (value == null ||
            (isLatitude ? !isValidLatLng(value, 0) : !isValidLatLng(0, value)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => _onFieldsChanged(),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: _style(AppTextStyles.bodyMedium),
          decoration: _inputDecoration(
            hint: hint,
            error: invalid
                ? (isLatitude ? 'Antara -90 dan 90' : 'Antara -180 dan 180')
                : null,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, String? error}) {
    const border = OutlineInputBorder(
      borderRadius: AppRadii.control,
      borderSide: BorderSide(color: AppColors.enterpriseBorder),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: _style(
        AppTextStyles.bodyMedium,
        color: AppColors.textSecondary,
      ),
      errorText: error,
      filled: true,
      fillColor: AppColors.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.control,
        borderSide: BorderSide(color: AppColors.primaryRed),
      ),
    );
  }

  Widget _readout(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.enterpriseBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: _style(
                AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: _style(
                AppTextStyles.bodySmall,
                color: color ?? AppColors.enterpriseTextMain,
                w: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _style(TextStyle base, {Color? color, FontWeight? w}) =>
      base.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        color: color ?? AppColors.enterpriseTextMain,
        fontWeight: w ?? base.fontWeight,
      );
}

enum BatchLocationSource { deviceGps, mapPin, photoMetadata }

class BatchPhotoLocationSheet extends StatefulWidget {
  final List<EvidencePhotoItem> photos;
  final ProjectReference? reference;
  final Widget Function(PhotoLocationMapController controller)? mapBuilder;
  final DeviceLocationResolver? deviceLocationResolver;

  const BatchPhotoLocationSheet({
    super.key,
    required this.photos,
    required this.reference,
    this.mapBuilder,
    this.deviceLocationResolver,
  });

  @override
  State<BatchPhotoLocationSheet> createState() =>
      _BatchPhotoLocationSheetState();
}

class _BatchPhotoLocationSheetState extends State<BatchPhotoLocationSheet> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _noteController;
  late final ValueNotifier<({double latitude, double longitude})?> _point;
  BatchLocationSource _activeSource = BatchLocationSource.deviceGps;
  LocationMethod _method = LocationMethod.deviceAtEntry;
  bool _updatingFromMap = false;
  double? _accuracyMeters;
  int _selectedExifIndex = 0;
  bool _isLoadingGps = false;

  List<EvidencePhotoItem> get _photosWithExif =>
      widget.photos.where((p) => p.exif != null).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _noteController = TextEditingController();
    _point = ValueNotifier(null);
    _initSource();
  }

  Future<void> _initSource() async {
    await _applyDeviceLocation();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _noteController.dispose();
    _point.dispose();
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  ({double latitude, double longitude})? get _coordinates {
    final lat = _parse(_latController.text);
    final lng = _parse(_lngController.text);
    if (lat == null || lng == null || !isValidLatLng(lat, lng)) return null;
    return (latitude: lat, longitude: lng);
  }

  Future<void> _applyDeviceLocation() async {
    setState(() => _isLoadingGps = true);
    final resolver =
        widget.deviceLocationResolver ?? defaultDeviceLocationResolver;
    final fix = await resolver();
    if (!mounted) return;
    setState(() {
      _isLoadingGps = false;
      _activeSource = BatchLocationSource.deviceGps;
      _method = LocationMethod.deviceAtEntry;
      if (fix != null) {
        _updatingFromMap = true;
        _latController.text = formatCoordinate(fix.latitude);
        _lngController.text = formatCoordinate(fix.longitude);
        _updatingFromMap = false;
        _point.value = (latitude: fix.latitude, longitude: fix.longitude);
        _accuracyMeters = fix.accuracyMeters;
      }
    });
  }

  void _applyMapLocation() {
    setState(() {
      _activeSource = BatchLocationSource.mapPin;
      _method = LocationMethod.manualPin;
      _accuracyMeters = null;
    });
  }

  void _applyExifLocation(int exifIndex) {
    final items = _photosWithExif;
    if (items.isEmpty || exifIndex < 0 || exifIndex >= items.length) return;
    final exif = items[exifIndex].exif!;
    _updatingFromMap = true;
    _latController.text = formatCoordinate(exif.latitude);
    _lngController.text = formatCoordinate(exif.longitude);
    _updatingFromMap = false;
    _point.value = (latitude: exif.latitude, longitude: exif.longitude);
    setState(() {
      _selectedExifIndex = exifIndex;
      _activeSource = BatchLocationSource.photoMetadata;
      _method = LocationMethod.exifConfirmed;
      _accuracyMeters = null;
    });
  }

  void _onFieldsChanged() {
    setState(() {
      _activeSource = BatchLocationSource.mapPin;
      _method = LocationMethod.manualPin;
      _accuracyMeters = null;
    });
    final coordinates = _coordinates;
    if (coordinates != null && !_updatingFromMap) _point.value = coordinates;
  }

  void _onMapMoved(double latitude, double longitude) {
    _updatingFromMap = true;
    _latController.text = formatCoordinate(latitude);
    _lngController.text = formatCoordinate(longitude);
    _updatingFromMap = false;
    setState(() {
      _activeSource = BatchLocationSource.mapPin;
      _method = LocationMethod.manualPin;
      _accuracyMeters = null;
    });
  }

  OfficerLocation? _draftLocation({bool includeNote = true}) {
    final coordinates = _coordinates;
    if (coordinates == null) return null;
    final note = includeNote ? _noteController.text.trim() : '';
    return OfficerLocation(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      method: _method,
      selectedAt: DateTime.now(),
      accuracyMeters: _method == LocationMethod.deviceAtEntry
          ? _accuracyMeters
          : null,
      clarificationNote: note.isEmpty ? null : note,
    );
  }

  Future<void> _handleSave(OfficerLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: const Text(
          'Konfirmasi Lokasi Sekaligus',
          style: TextStyle(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Lokasi ini akan diterapkan ke ${widget.photos.length} foto terpilih.\n\n'
          'Koordinat foto lain yang tidak dipilih tidak akan diubah.',
          style: const TextStyle(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontSize: 14,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.enterprisePrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(PhotoLocationResult.saved(location));
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximity = evaluatePhotoProximity(
      location: _draftLocation(includeNote: false),
      reference: widget.reference,
    );
    final outside = proximity.status == ProximityStatus.outsideTolerance;
    final location = _draftLocation(includeNote: outside);
    final noteMissing = outside && _noteController.text.trim().isEmpty;
    final canSave = location != null && !noteMissing;
    final photosWithExif = _photosWithExif;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.enterpriseBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Atur Lokasi Sekaligus',
              style: _style(AppTextStyles.headlineMedium, w: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Pilih sumber koordinat untuk ${widget.photos.length} foto terpilih.',
              style: _style(
                AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSourceSelector(photosWithExif),
            const SizedBox(height: 14),
            _buildSourceBody(photosWithExif),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _coordinateField(
                    controller: _latController,
                    label: 'Lintang',
                    hint: '-7,327100',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _coordinateField(
                    controller: _lngController,
                    label: 'Bujur',
                    hint: '108,221900',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _readout('Sumber lokasi terpilih', locationMethodLabel(_method)),
            _readout(
              'Jarak ke titik proyek',
              _distanceText(proximity),
              color: outside ? AppColors.enterpriseWarning : null,
            ),
            _readout(
              'Titik proyek',
              widget.reference == null
                  ? 'Belum tersedia dari Pengembang'
                  : '${formatCoordinate(widget.reference!.latitude)}, '
                        '${formatCoordinate(widget.reference!.longitude)} (hanya-baca)',
            ),
            _readout(
              'Akurasi',
              _method == LocationMethod.deviceAtEntry && _accuracyMeters != null
                  ? '±${_accuracyMeters!.round()} m (GPS Perangkat)'
                  : 'Tidak berlaku untuk titik pilihan petugas',
            ),
            if (outside) ...[
              const SizedBox(height: 12),
              Text(
                'Alasan petugas (wajib)',
                style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 4,
                style: _style(AppTextStyles.bodyMedium),
                decoration: _inputDecoration(
                  hint:
                      'Mis. seluruh foto dokumentasi diambil dari jalan akses proyek.',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jarak melebihi ${kPhotoLocationToleranceMeters.round()} m. Alasan ini akan diperiksa Admin; lokasi tidak ditolak otomatis.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canSave ? () => _handleSave(location) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.textOnRed,
                disabledBackgroundColor: AppColors.enterpriseBorder,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.control,
                ),
              ),
              child: Text('Terapkan ke ${widget.photos.length} foto terpilih'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.enterpriseTextMain,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelector(List<EvidencePhotoItem> photosWithExif) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final isNarrow = constraints.maxWidth < 480 || textScale > 1.25;
        final buttons = [
          _sourceItem(
            source: BatchLocationSource.deviceGps,
            icon: Icons.my_location,
            label: 'GPS Perangkat',
            sublabel: 'Posisi saat input',
            enabled: true,
          ),
          _sourceItem(
            source: BatchLocationSource.mapPin,
            icon: Icons.map_outlined,
            label: 'Peta / Manual',
            sublabel: 'Geser pin / ketik',
            enabled: true,
          ),
          _sourceItem(
            source: BatchLocationSource.photoMetadata,
            icon: Icons.photo_camera_outlined,
            label: 'Metadata Foto',
            sublabel: photosWithExif.isEmpty
                ? 'Tidak ada EXIF'
                : '${photosWithExif.length} foto punya GPS',
            enabled: photosWithExif.isNotEmpty,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (final b in buttons) ...[b, const SizedBox(height: 8)],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: buttons[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _sourceItem({
    required BatchLocationSource source,
    required IconData icon,
    required String label,
    required String sublabel,
    required bool enabled,
  }) {
    final isSelected = _activeSource == source;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: isSelected
            ? AppColors.enterprisePrimarySurface
            : AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.control,
          side: BorderSide(
            color: isSelected
                ? AppColors.enterprisePrimary
                : AppColors.enterpriseBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: enabled
              ? () {
                  if (source == BatchLocationSource.deviceGps) {
                    _applyDeviceLocation();
                  } else if (source == BatchLocationSource.mapPin) {
                    _applyMapLocation();
                  } else if (source == BatchLocationSource.photoMetadata) {
                    _applyExifLocation(_selectedExifIndex);
                  }
                }
              : null,
          borderRadius: AppRadii.control,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.enterprisePrimary
                          : AppColors.enterpriseTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _style(
                          AppTextStyles.labelMedium,
                          w: FontWeight.w700,
                          color: isSelected
                              ? AppColors.enterprisePrimary
                              : AppColors.enterpriseTextMain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    AppTextStyles.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBody(List<EvidencePhotoItem> photosWithExif) {
    switch (_activeSource) {
      case BatchLocationSource.deviceGps:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.enterprisePrimarySurfaceSoft,
            borderRadius: AppRadii.control,
            border: Border.all(color: AppColors.enterprisePrimaryBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 16,
                        color: AppColors.enterprisePrimary,
                      ),
                      Text(
                        'Posisi GPS Perangkat',
                        style: _style(
                          AppTextStyles.labelLarge,
                          w: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingGps)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _applyDeviceLocation,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Perbarui'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Waktu pencatatan dicatat saat ini (bukan waktu pemotretan). Lokasi ini disimpan sebagai posisi petugas saat input formulir.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case BatchLocationSource.mapPin:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mapBuilder != null) ...[
              widget.mapBuilder!(
                PhotoLocationMapController(
                  point: _point,
                  reference: widget.reference,
                  onMapMoved: _onMapMoved,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Geser peta agar penanda berada di titik yang sesuai, atau ketik koordinat di bawah.',
              style: _style(
                AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

      case BatchLocationSource.photoMetadata:
        if (photosWithExif.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: AppRadii.control,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.enterpriseTextMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada metadata GPS yang terbaca pada foto terpilih. Gunakan GPS perangkat atau tentukan lewat peta.',
                    style: _style(
                      AppTextStyles.bodySmall,
                      color: AppColors.enterpriseTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.enterprisePrimarySurfaceSoft,
            borderRadius: AppRadii.control,
            border: Border.all(color: AppColors.enterprisePrimaryBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih foto sumber koordinat EXIF:',
                style: _style(AppTextStyles.labelMedium, w: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < photosWithExif.length; i++)
                    ChoiceChip(
                      label: Text(
                        'Foto ${widget.photos.indexOf(photosWithExif[i]) + 1} (${formatCoordinate(photosWithExif[i].exif!.latitude)}, ${formatCoordinate(photosWithExif[i].exif!.longitude)})',
                        style: _style(
                          AppTextStyles.bodySmall,
                          w: _selectedExifIndex == i ? FontWeight.w700 : null,
                          color: _selectedExifIndex == i
                              ? Colors.white
                              : AppColors.enterpriseTextMain,
                        ),
                      ),
                      selected: _selectedExifIndex == i,
                      selectedColor: AppColors.enterprisePrimary,
                      onSelected: (selected) {
                        if (selected) _applyExifLocation(i);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Koordinat EXIF dari foto yang dipilih akan disalin dan dikonfirmasi untuk seluruh foto yang terpilih.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _distanceText(PhotoProximity proximity) {
    switch (proximity.status) {
      case ProximityStatus.noLocation:
        return 'Isi koordinat terlebih dahulu';
      case ProximityStatus.noReference:
        return 'Validasi jarak belum tersedia';
      case ProximityStatus.withinTolerance:
      case ProximityStatus.outsideTolerance:
        return '${formatDistance(proximity.distanceMeters!)} '
            '(batas awal ${kPhotoLocationToleranceMeters.round()} m)';
    }
  }

  Widget _coordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final text = controller.text.trim();
    final value = _parse(text);
    final isLatitude = label == 'Lintang';
    final invalid =
        text.isNotEmpty &&
        (value == null ||
            (isLatitude ? !isValidLatLng(value, 0) : !isValidLatLng(0, value)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _style(AppTextStyles.labelLarge, w: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => _onFieldsChanged(),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: _style(AppTextStyles.bodyMedium),
          decoration: _inputDecoration(
            hint: hint,
            error: invalid
                ? (isLatitude ? 'Antara -90 dan 90' : 'Antara -180 dan 180')
                : null,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, String? error}) {
    const border = OutlineInputBorder(
      borderRadius: AppRadii.control,
      borderSide: BorderSide(color: AppColors.enterpriseBorder),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: _style(
        AppTextStyles.bodyMedium,
        color: AppColors.textSecondary,
      ),
      errorText: error,
      filled: true,
      fillColor: AppColors.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadii.control,
        borderSide: BorderSide(color: AppColors.primaryRed),
      ),
    );
  }

  Widget _readout(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.enterpriseBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: _style(
                AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: _style(
                AppTextStyles.bodySmall,
                color: color ?? AppColors.enterpriseTextMain,
                w: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _style(TextStyle base, {Color? color, FontWeight? w}) =>
      base.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        color: color ?? AppColors.enterpriseTextMain,
        fontWeight: w ?? base.fontWeight,
      );
}
