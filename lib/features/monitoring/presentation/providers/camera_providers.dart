import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/geo_stamp.dart';
import '../../services/camera_gateway.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../services/photo_import.dart';
import '../../services/stamp_renderer.dart';

final cameraGatewayProvider = Provider<CameraGateway>(
  (ref) => const DeviceCameraGateway(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => NominatimGeocodingService(),
);

final mapThumbnailProvider = Provider<MapThumbnailProvider>(
  (ref) => OsmMapThumbnailProvider(),
);

/// Merender watermark. Dapat diganti pada tes agar tidak memakai dart:ui.
typedef StampRenderFn =
    Future<Uint8List> Function({
      required Uint8List photoBytes,
      required GeoStamp stamp,
      Uint8List? map,
    });

final stampRenderFnProvider = Provider<StampRenderFn>(
  (ref) => StampRenderer.render,
);

final photoPickerProvider = Provider<PhotoPickerGateway>(
  (ref) => const FilePhotoPickerGateway(),
);
