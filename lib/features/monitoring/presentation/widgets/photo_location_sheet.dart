import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/evidence_photo_item.dart';
import '../../data/models/project_reference.dart';
import '../../utils/geo_distance.dart';
import 'evidence_photo_picker.dart';

export '../../utils/geo_distance.dart' show formatCoordinate, formatDistance;

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

typedef PhotoLocationMapBuilder =
    Widget Function(PhotoLocationMapController controller);

Future<PhotoLocationResult?> _showSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<PhotoLocationResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => child,
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
  PhotoLocationMapBuilder? mapBuilder,
}) => _showSheet(
  context,
  PhotoLocationSheet(
    photo: photo,
    photoNumber: photoNumber,
    reference: reference,
    mapBuilder: mapBuilder,
  ),
);

/// Membuka lembar penentuan lokasi untuk beberapa foto sekaligus.
Future<PhotoLocationResult?> showBatchPhotoLocationSheet(
  BuildContext context, {
  required List<EvidencePhotoItem> photos,
  required ProjectReference? reference,
  PhotoLocationMapBuilder? mapBuilder,
}) => _showSheet(
  context,
  BatchPhotoLocationSheet(
    photos: photos,
    reference: reference,
    mapBuilder: mapBuilder,
  ),
);

class PhotoLocationSheet extends StatelessWidget {
  final EvidencePhotoItem photo;
  final int photoNumber;
  final ProjectReference? reference;
  final PhotoLocationMapBuilder? mapBuilder;

  const PhotoLocationSheet({
    super.key,
    required this.photo,
    required this.photoNumber,
    required this.reference,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _LocationSheetBody(
      photos: [photo],
      title: 'Lokasi Foto $photoNumber',
      reference: reference,
      mapBuilder: mapBuilder,
      initial: photo.location,
      primaryLabel: 'Simpan lokasi',
      allowClear: photo.location != null,
      outsideHint:
          'Mis. foto diambil dari jalan akses, bukan dari titik proyek.',
    );
  }
}

class BatchPhotoLocationSheet extends StatelessWidget {
  final List<EvidencePhotoItem> photos;
  final ProjectReference? reference;
  final PhotoLocationMapBuilder? mapBuilder;

  const BatchPhotoLocationSheet({
    super.key,
    required this.photos,
    required this.reference,
    this.mapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _LocationSheetBody(
      photos: photos,
      title: 'Atur lokasi ${photos.length} foto',
      reference: reference,
      mapBuilder: mapBuilder,
      initial: null,
      primaryLabel: 'Terapkan ke ${photos.length} foto',
      allowClear: false,
      confirmOverwrite: true,
      outsideHint:
          'Mis. seluruh foto dokumentasi diambil dari jalan akses proyek.',
    );
  }
}

enum _Source { map, photo }

/// Isi lembar lokasi yang dipakai bersama oleh satu foto maupun banyak foto.
class _LocationSheetBody extends StatefulWidget {
  final List<EvidencePhotoItem> photos;
  final String title;
  final ProjectReference? reference;
  final PhotoLocationMapBuilder? mapBuilder;
  final OfficerLocation? initial;
  final String primaryLabel;
  final bool allowClear;
  final bool confirmOverwrite;
  final String outsideHint;

  const _LocationSheetBody({
    required this.photos,
    required this.title,
    required this.reference,
    required this.mapBuilder,
    required this.initial,
    required this.primaryLabel,
    required this.allowClear,
    required this.outsideHint,
    this.confirmOverwrite = false,
  });

  @override
  State<_LocationSheetBody> createState() => _LocationSheetBodyState();
}

class _LocationSheetBodyState extends State<_LocationSheetBody> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _noteController;
  late final ValueNotifier<({double latitude, double longitude})?> _point;
  late LocationMethod _method;
  _Source _source = _Source.map;
  bool _updatingFromMap = false;
  int _exifChoice = 0;

  List<EvidencePhotoItem> get _withExif =>
      widget.photos.where((p) => p.exif != null).toList(growable: false);

  @override
  void initState() {
    super.initState();
    final location = widget.initial;
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

  void _setFields(double latitude, double longitude) {
    _updatingFromMap = true;
    _latController.text = formatCoordinate(latitude);
    _lngController.text = formatCoordinate(longitude);
    _updatingFromMap = false;
  }

  void _onFieldsChanged() {
    // Mengetik ulang koordinat berarti titik dipilih manual oleh petugas.
    setState(() => _method = LocationMethod.manualPin);
    final coordinates = _coordinates;
    if (coordinates != null && !_updatingFromMap) _point.value = coordinates;
  }

  void _onMapMoved(double latitude, double longitude) {
    _setFields(latitude, longitude);
    setState(() => _method = LocationMethod.manualPin);
  }

  void _useExif(EvidencePhotoItem photo) {
    final exif = photo.exif!;
    _setFields(exif.latitude, exif.longitude);
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

  Future<void> _save(OfficerLocation location) async {
    final overwritten = widget.photos.where((p) => p.hasLocation).length;
    if (widget.confirmOverwrite && overwritten > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
          title: Text(
            'Ganti lokasi yang sudah ada?',
            style: _style(AppTextStyles.titleMedium, w: FontWeight.w700),
          ),
          content: Text(
            '$overwritten dari ${widget.photos.length} foto sudah punya lokasi. '
            'Lokasi tersebut akan diganti dengan titik ini.',
            style: _style(AppTextStyles.bodyMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
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
    final exifPhotos = _withExif;
    final showMap = _source == _Source.map && widget.mapBuilder != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
            const SizedBox(height: 16),
            _header(),
            if (exifPhotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sourceSwitch(),
            ],
            const SizedBox(height: 16),
            if (_source == _Source.photo && exifPhotos.isNotEmpty)
              _exifPanel(exifPhotos)
            else if (showMap)
              widget.mapBuilder!(
                PhotoLocationMapController(
                  point: _point,
                  reference: widget.reference,
                  onMapMoved: _onMapMoved,
                ),
              )
            else
              _hint(
                'Isi koordinat titik foto diambil. Peta tidak tersedia di sini.',
              ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _summary(proximity, outside),
            if (outside) ...[
              const SizedBox(height: 16),
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
                decoration: _inputDecoration(hint: widget.outsideHint),
              ),
              const SizedBox(height: 6),
              Text(
                'Jarak melebihi ${kPhotoLocationToleranceMeters.round()} m. '
                'Alasan ini akan diperiksa Admin; lokasi tidak ditolak otomatis.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
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
              child: Text(widget.primaryLabel),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (widget.allowClear)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const PhotoLocationResult.cleared()),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryRed,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Hapus lokasi'),
                    ),
                  ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.enterpriseTextMuted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final count = widget.photos.length;
    final thumbs = widget.photos.take(4).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: _style(AppTextStyles.headlineMedium, w: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                count > 1
                    ? 'Satu titik untuk semua foto yang dipilih.'
                    : 'Tentukan titik foto ini diambil.',
                style: _style(
                  AppTextStyles.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _thumbStack(thumbs, extra: count - thumbs.length),
      ],
    );
  }

  Widget _thumbStack(List<EvidencePhotoItem> thumbs, {required int extra}) {
    const size = 40.0;
    const overlap = 26.0;
    final width = size + overlap * (thumbs.length - 1) + (extra > 0 ? 0 : 0);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < thumbs.length; i++)
              Positioned(
                left: i * overlap,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.small,
                    border: Border.all(color: Colors.white, width: 2),
                    color: AppColors.surfaceMuted,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _thumb(thumbs[i]),
                ),
              ),
            if (extra > 0)
              Positioned(
                left: (thumbs.length - 1) * overlap,
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.small,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(EvidencePhotoItem photo) {
    final bytes = EvidencePhotoPicker.getCachedBytes(photo.localRef);
    if (bytes == null) {
      return const Icon(
        Icons.image_outlined,
        size: 18,
        color: AppColors.enterpriseTextMuted,
      );
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.image_outlined,
        size: 18,
        color: AppColors.enterpriseTextMuted,
      ),
    );
  }

  Widget _sourceSwitch() {
    Widget segment(_Source source, IconData icon, String label) {
      final selected = _source == source;
      return Expanded(
        child: Material(
          color: selected ? AppColors.cardSurface : Colors.transparent,
          borderRadius: AppRadii.small,
          elevation: selected ? 1 : 0,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: AppRadii.small,
            onTap: () => setState(() => _source = source),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.enterpriseTextMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(
                        AppTextStyles.labelMedium,
                        w: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.enterpriseTextMain
                            : AppColors.enterpriseTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadii.control,
      ),
      child: Row(
        children: [
          segment(_Source.map, Icons.map_outlined, 'Peta / manual'),
          segment(_Source.photo, Icons.photo_camera_outlined, 'Dari foto'),
        ],
      ),
    );
  }

  Widget _exifPanel(List<EvidencePhotoItem> exifPhotos) {
    final chosen = exifPhotos[_exifChoice.clamp(0, exifPhotos.length - 1)];
    final exif = chosen.exif!;
    final used =
        _method == LocationMethod.exifConfirmed &&
        _coordinates != null &&
        (_coordinates!.latitude - exif.latitude).abs() < 1e-6 &&
        (_coordinates!.longitude - exif.longitude).abs() < 1e-6;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPS tertanam di foto (belum diverifikasi)',
            style: _style(AppTextStyles.labelLarge, w: FontWeight.w700),
          ),
          if (exifPhotos.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < exifPhotos.length; i++)
                  ChoiceChip(
                    label: Text(
                      'Foto ${widget.photos.indexOf(exifPhotos[i]) + 1}',
                    ),
                    selected: _exifChoice == i,
                    showCheckmark: false,
                    selectedColor: AppColors.enterprisePrimarySurface,
                    labelStyle: _style(
                      AppTextStyles.labelMedium,
                      w: _exifChoice == i ? FontWeight.w700 : FontWeight.w500,
                      color: _exifChoice == i
                          ? AppColors.primaryRed
                          : AppColors.enterpriseTextMain,
                    ),
                    side: BorderSide(
                      color: _exifChoice == i
                          ? AppColors.enterprisePrimaryBorder
                          : AppColors.enterpriseBorder,
                    ),
                    onSelected: (_) => setState(() => _exifChoice = i),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${formatCoordinate(exif.latitude)}, ${formatCoordinate(exif.longitude)}',
            style: _style(AppTextStyles.titleMedium, w: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Data ini berasal dari berkas foto dan dapat diubah pihak lain. '
            'Petugas bertanggung jawab atas titik yang disimpan.',
            style: _style(
              AppTextStyles.bodySmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: used ? null : () => _useExif(chosen),
            icon: Icon(used ? Icons.check_circle : Icons.south_east, size: 18),
            label: Text(used ? 'Koordinat dipakai' : 'Gunakan koordinat foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: const BorderSide(color: AppColors.enterprisePrimaryBorder),
              minimumSize: const Size.fromHeight(44),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.control,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Text(
        text,
        style: _style(AppTextStyles.bodySmall, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _summary(PhotoProximity proximity, bool outside) {
    final reference = widget.reference;
    final rows = <Widget>[
      _summaryRow('Sumber', locationMethodLabel(_method)),
      if (reference == null)
        _summaryRow(
          'Jarak ke proyek',
          'Tidak dihitung: titik proyek belum tersedia',
          muted: true,
        )
      else ...[
        _summaryRow(
          'Jarak ke proyek',
          _distanceText(proximity),
          color: outside ? AppColors.enterpriseWarning : null,
        ),
        _summaryRow(
          'Titik proyek',
          '${formatCoordinate(reference.latitude)}, '
              '${formatCoordinate(reference.longitude)} (hanya-baca)',
        ),
      ],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadii.control,
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(children: rows),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: muted
                    ? AppColors.textSecondary
                    : (color ?? AppColors.enterpriseTextMain),
                w: muted ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceText(PhotoProximity proximity) {
    switch (proximity.status) {
      case ProximityStatus.noLocation:
        return 'Isi koordinat terlebih dahulu';
      case ProximityStatus.noReference:
        return 'Tidak dihitung';
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

  TextStyle _style(TextStyle base, {Color? color, FontWeight? w}) =>
      base.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        color: color ?? AppColors.enterpriseTextMain,
        fontWeight: w ?? base.fontWeight,
      );
}
