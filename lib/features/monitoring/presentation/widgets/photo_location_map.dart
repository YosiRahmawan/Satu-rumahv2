import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../utils/geo_distance.dart';
import 'photo_location_sheet.dart';

/// Pusat peta bila belum ada titik foto maupun titik proyek (Kota Tasikmalaya).
const LatLng _fallbackCenter = LatLng(-7.3274, 108.2207);

/// Peta penentu titik foto: penanda tetap di tengah, peta digeser di bawahnya.
///
/// Titik proyek (jika ada) hanya digambar sebagai referensi hanya-baca beserta
/// lingkaran toleransi; tidak ada kontrol untuk mengubahnya.
class PhotoLocationMap extends StatefulWidget {
  final PhotoLocationMapController controller;
  final double height;

  /// Bawaannya mengambil ubin OpenStreetMap lewat jaringan; tes dapat
  /// menggantinya.
  final TileProvider? tileProvider;

  const PhotoLocationMap({
    super.key,
    required this.controller,
    this.height = 240,
    this.tileProvider,
  });

  @override
  State<PhotoLocationMap> createState() => _PhotoLocationMapState();
}

class _PhotoLocationMapState extends State<PhotoLocationMap> {
  final MapController _mapController = MapController();
  bool _ready = false;

  PhotoLocationMapController get _bridge => widget.controller;

  @override
  void initState() {
    super.initState();
    _bridge.point.addListener(_syncFromFields);
  }

  @override
  void dispose() {
    _bridge.point.removeListener(_syncFromFields);
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter {
    final point = _bridge.point.value;
    if (point != null) return LatLng(point.latitude, point.longitude);
    final reference = _bridge.reference;
    if (reference != null) {
      return LatLng(reference.latitude, reference.longitude);
    }
    return _fallbackCenter;
  }

  /// Koordinat yang diketik atau dipilih dari EXIF menggeser peta.
  void _syncFromFields() {
    final point = _bridge.point.value;
    if (!_ready || point == null) return;
    _mapController.move(
      LatLng(point.latitude, point.longitude),
      _mapController.camera.zoom,
    );
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    // Hanya geseran pengguna yang mengubah isian; perpindahan terprogram tidak.
    if (!hasGesture) return;
    _bridge.onMapMoved(camera.center.latitude, camera.center.longitude);
  }

  void _markCenter() {
    final center = _mapController.camera.center;
    _bridge.onMapMoved(center.latitude, center.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final reference = _bridge.reference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadii.control,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 17,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                    onMapReady: () => _ready = true,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'satu_rumah',
                      tileProvider: widget.tileProvider,
                    ),
                    if (reference != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(
                              reference.latitude,
                              reference.longitude,
                            ),
                            radius: kPhotoLocationToleranceMeters,
                            useRadiusInMeter: true,
                            color: AppColors.primaryRed.withValues(alpha: 0.10),
                            borderColor: AppColors.primaryRed,
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    if (reference != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              reference.latitude,
                              reference.longitude,
                            ),
                            width: 16,
                            height: 16,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.enterpriseTextMain,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('© OpenStreetMap')],
                    ),
                  ],
                ),
                // Penanda tetap: ujung bawah ikon berada tepat di tengah peta.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: Icon(
                        Icons.location_on,
                        size: 36,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _markCenter,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Tandai titik di tengah peta'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        Text(
          'Peta dasar membutuhkan internet. Koordinat dapat diisi manual.',
          style: AppTextStyles.bodySmall.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        if (reference != null) ...[
          const SizedBox(height: 4),
          Text(
            'Titik gelap dan lingkaran merah: titik proyek dan batas awal '
            '${kPhotoLocationToleranceMeters.round()} m (hanya-baca).',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
