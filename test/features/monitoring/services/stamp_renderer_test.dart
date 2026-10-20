import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:satu_rumah/features/monitoring/data/models/geo_stamp.dart';
import 'package:satu_rumah/features/monitoring/services/stamp_renderer.dart';
import 'package:satu_rumah/features/monitoring/utils/geo_stamp_signer.dart';

import '../../../support/camera_fakes.dart';

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
}
