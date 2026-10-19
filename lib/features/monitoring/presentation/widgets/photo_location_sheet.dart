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

  const PhotoLocationSheet({
    super.key,
    required this.photo,
    required this.photoNumber,
    required this.reference,
    this.mapBuilder,
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

  @override
  void initState() {
    super.initState();
    final location = widget.photo.location;
    _method = location?.method ?? LocationMethod.manualPin;
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
    setState(() => _method = LocationMethod.manualPin);
    final coordinates = _coordinates;
    if (coordinates != null && !_updatingFromMap) _point.value = coordinates;
  }

  void _onMapMoved(double latitude, double longitude) {
    _updatingFromMap = true;
    _latController.text = formatCoordinate(latitude);
    _lngController.text = formatCoordinate(longitude);
    _updatingFromMap = false;
    setState(() => _method = LocationMethod.manualPin);
  }

  void _useExif(ExifGeo exif) {
    _latController.text = formatCoordinate(exif.latitude);
    _lngController.text = formatCoordinate(exif.longitude);
    _point.value = (latitude: exif.latitude, longitude: exif.longitude);
    setState(() => _method = LocationMethod.exifConfirmed);
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
