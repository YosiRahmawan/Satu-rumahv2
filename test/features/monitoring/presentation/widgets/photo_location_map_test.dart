import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/project_reference.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/photo_location_map.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/photo_location_sheet.dart';

/// Ubin kosong 1x1 agar tes tidak memakai jaringan.
class _BlankTileProvider extends TileProvider {
  static final Uint8List _png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

void main() {
  late ValueNotifier<({double latitude, double longitude})?> point;
  late List<(double, double)> moves;

  PhotoLocationMapController controller({ProjectReference? reference}) =>
      PhotoLocationMapController(
        point: point,
        reference: reference,
        onMapMoved: (lat, lng) => moves.add((lat, lng)),
      );

  Future<void> pump(
    WidgetTester tester, {
    ProjectReference? reference,
    double width = 360,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoLocationMap(
              controller: controller(reference: reference),
              tileProvider: _BlankTileProvider(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    point = ValueNotifier(null);
    moves = [];
  });

  tearDown(() => point.dispose());

  testWidgets('tampil dengan penanda tengah dan petunjuk internet', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.textContaining('membutuhkan internet'), findsOneWidget);
    expect(find.byType(CircleLayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('titik proyek digambar hanya-baca bersama lingkaran 50 m', (
    tester,
  ) async {
    await pump(
      tester,
      reference: const ProjectReference(latitude: -7.3274, longitude: 108.2207),
    );
    expect(find.byType(CircleLayer), findsOneWidget);
    expect(find.textContaining('50 m (hanya-baca)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menggeser peta melaporkan titik tengah baru', (tester) async {
    await pump(tester);
    await tester.drag(find.byType(FlutterMap), const Offset(-80, -60));
    await tester.pump(const Duration(milliseconds: 400));
    expect(moves, isNotEmpty);
    expect(moves.last.$1, isNot(-7.3274));
  });

  testWidgets('tombol Tandai titik di tengah peta melaporkan pusat peta', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Tandai titik di tengah peta'));
    await tester.pump();
    expect(moves, hasLength(1));
    expect(moves.single.$1, closeTo(-7.3274, 1e-6));
    expect(moves.single.$2, closeTo(108.2207, 1e-6));
  });

  testWidgets('koordinat yang diketik memindahkan peta tanpa memanggil balik', (
    tester,
  ) async {
    await pump(tester);
    point.value = (latitude: -6.9, longitude: 107.6);
    await tester.pump(const Duration(milliseconds: 100));
    expect(moves, isEmpty);
    await tester.tap(find.text('Tandai titik di tengah peta'));
    expect(moves.single.$1, closeTo(-6.9, 1e-6));
    expect(moves.single.$2, closeTo(107.6, 1e-6));
  });

  testWidgets('tersusun tanpa overflow di 320dp', (tester) async {
    await pump(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
