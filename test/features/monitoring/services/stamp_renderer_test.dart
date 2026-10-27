import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/services/stamp_renderer.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

import '../../../support/camera_fakes.dart';
import 'package:satu_rumah/features/monitoring/services/osm_client.dart';

class _TileAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Uint8List png;
  _TileAdapter(this.png);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromBytes(png, 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stamp = GeoStamp(
    latitude: -7.3274,
    longitude: 108.2207,
    accuracyMeters: 8.4,
    capturedAt: DateTime(2026, 10, 20, 9, 30, 15),
    address: 'Jl. Contoh No. 1, Tasikmalaya',
    note: 'Saluran drainase',
  );

  test('format koordinat memuat akurasi', () {
    expect(
      StampRenderer.formatStampCoordinates(stamp),
      '-7.327400, 108.220700 · ±8 m',
    );
  });

  testWidgets('render menghasilkan JPEG berwatermark dengan geotag sah', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final output = await StampRenderer.render(
        photoBytes: plainJpeg(width: 640, height: 480),
        stamp: stamp,
      );
      final verified = GeoStampSigner.verify(output);
      expect(verified.stamp, stamp);

      final decoded = img.decodeJpg(output)!;
      expect(decoded.width, 640);
      expect(decoded.height, 480);
      // Gradasi gelap menutup bagian bawah foto polos berwarna biru.
      final bottom = decoded.getPixel(320, 477);
      final top = decoded.getPixel(20, 200);
      expect(bottom.r + bottom.g + bottom.b, lessThan(top.r + top.g + top.b));
    });
  });

  testWidgets('foto besar diperkecil ke sisi maksimum', (tester) async {
    await tester.runAsync(() async {
      final output = await StampRenderer.render(
        photoBytes: plainJpeg(width: 2560, height: 1920),
        stamp: stamp,
      );
      final decoded = img.decodeJpg(output)!;
      expect(decoded.width, StampRenderer.maxSide);
      expect(decoded.height, 960);
    });
  });

  testWidgets('render dengan peta (atribusi OSM) tetap sah dan terbaca', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final map = Uint8List.fromList(
        img.encodePng(img.Image(width: 256, height: 256)),
      );
      final output = await StampRenderer.render(
        photoBytes: plainJpeg(width: 640, height: 480),
        stamp: stamp,
        map: map,
      );
      expect(GeoStampSigner.verify(output).stamp, stamp);
      expect(img.decodeJpg(output)!.width, 640);
    });
  });

  testWidgets('peta: tile membawa User-Agent dan dipakai ulang dari cache', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final png = Uint8List.fromList(
        img.encodePng(img.Image(width: 256, height: 256)),
      );
      final adapter = _TileAdapter(png);
      final dio = newOsmDio(responseType: ResponseType.bytes)
        ..httpClientAdapter = adapter;
      final provider = OsmMapThumbnailProvider(dio: dio);

      expect(await provider.thumbnail(-7.4101, 108.3303), isNotNull);
      final first = adapter.requests.length;
      expect(first, inInclusiveRange(1, 4));
      expect(adapter.requests.first.headers['User-Agent'], kOsmUserAgent);

      expect(await provider.thumbnail(-7.4101, 108.3303), isNotNull);
      expect(adapter.requests.length, first);
    });
  });
}
