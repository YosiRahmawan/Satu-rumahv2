import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

import '../data/models/geo_stamp.dart';
import '../utils/geo_stamp_signer.dart';

/// Peta kecil (potongan ubin OpenStreetMap) yang berpusat di sebuah titik.
abstract class MapThumbnailProvider {
  /// PNG persegi dengan titik di tengahnya, atau null bila gagal/offline.
  Future<Uint8List?> thumbnail(double latitude, double longitude);
}

/// Mengambil beberapa ubin OSM (zoom 17) dan memotong jendela 256x256 di
/// sekitar titik. Hanya dipanggil saat memotret; gagal berarti cap tanpa peta.
class OsmMapThumbnailProvider implements MapThumbnailProvider {
  final Dio _dio;
  static const int _zoom = 17;
  static const int _tile = 256;

  OsmMapThumbnailProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 5),
              responseType: ResponseType.bytes,
            ),
          );

  @override
  Future<Uint8List?> thumbnail(double latitude, double longitude) async {
    try {
      final n = math.pow(2, _zoom).toDouble();
      final x = (longitude + 180) / 360 * n * _tile;
      final latRad = latitude * math.pi / 180;
      final y =
          (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
          2 *
          n *
          _tile;
      final left = x - _tile / 2;
      final top = y - _tile / 2;
      final x0 = (left / _tile).floor();
      final x1 = ((left + _tile - 1) / _tile).floor();
      final y0 = (top / _tile).floor();
      final y1 = ((top + _tile - 1) / _tile).floor();

      final fetches = <Future<(int, int, Uint8List)?>>[];
      for (var tx = x0; tx <= x1; tx++) {
        for (var ty = y0; ty <= y1; ty++) {
          fetches.add(_fetchTile(tx, ty));
        }
      }
      final tiles = (await Future.wait(
        fetches,
      )).whereType<(int, int, Uint8List)>();
      if (tiles.isEmpty) return null;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, _tile.toDouble(), _tile.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFE5E3DF),
      );
      for (final (tx, ty, bytes) in tiles) {
        final image = await _decode(bytes);
        canvas.drawImage(
          image,
          ui.Offset(tx * _tile - left, ty * _tile - top),
          ui.Paint(),
        );
        image.dispose();
      }
      final picture = recorder.endRecording();
      final result = await picture.toImage(_tile, _tile);
      final data = await result.toByteData(format: ui.ImageByteFormat.png);
      result.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<(int, int, Uint8List)?> _fetchTile(int x, int y) async {
    try {
      final response = await _dio.get<List<int>>(
        'https://tile.openstreetmap.org/$_zoom/$x/$y.png',
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return (x, y, Uint8List.fromList(data));
    } catch (_) {
      return null;
    }
  }
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

/// Menempelkan watermark geotag ke piksel foto lalu menanam tanda tangannya.
class StampRenderer {
  StampRenderer._();

  /// Sisi terpanjang foto hasil (px). Foto kamera 12 MP diperkecil agar
  /// proses dan penyimpanan tetap ringan.
  static const int maxSide = 1280;

  static const String _font = 'Plus Jakarta Sans';

  /// Mengembalikan JPEG berwatermark + bertanda tangan untuk [photoBytes].
  ///
  /// [map] adalah PNG peta kecil (opsional) yang digambar di panel keterangan.
  static Future<Uint8List> render({
    required Uint8List photoBytes,
    required GeoStamp stamp,
    Uint8List? map,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(photoBytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longSide = math.max(descriptor.width, descriptor.height);
    final scale = longSide > maxSide ? maxSide / longSide : 1.0;
    final targetWidth = (descriptor.width * scale).round();
    final targetHeight = (descriptor.height * scale).round();
    final codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final base = frame.image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();

    final width = base.width;
    final height = base.height;
    final mapImage = map == null ? null : await _decode(map);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(base, ui.Offset.zero, ui.Paint());
    _paintOverlay(canvas, width.toDouble(), height.toDouble(), stamp, mapImage);
    final picture = recorder.endRecording();
    final composed = await picture.toImage(width, height);
    final raw = await composed.toByteData(format: ui.ImageByteFormat.rawRgba);
    base.dispose();
    mapImage?.dispose();
    composed.dispose();
    if (raw == null) throw StateError('Gagal merender foto.');

    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: raw.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    final jpeg = Uint8List.fromList(img.encodeJpg(image, quality: 80));
    return GeoStampSigner.embed(jpeg, stamp);
  }

  static void _paintOverlay(
    ui.Canvas canvas,
    double w,
    double h,
    GeoStamp stamp,
    ui.Image? map,
  ) {
    final u = math.min(w, h) / 1000;
    final margin = 24 * u;
    const white = ui.Color(0xFFFFFFFF);

    // Gradasi tipis di bawah agar teks putih tetap terbaca di foto terang.
    final scrimHeight = h * 0.34;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, h - scrimHeight, w, scrimHeight),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, h - scrimHeight),
          ui.Offset(0, h),
          const [ui.Color(0x00000000), ui.Color(0x8C000000)],
        ),
    );

    // Lencana kiri atas.
    final badge = _text(
      'SATU RUMAH',
      size: 30 * u,
      weight: FontWeight.w800,
      color: white,
      shadow: true,
    );
    final badgeSub = _text(
      'Geotag Dokumentasi',
      size: 20 * u,
      weight: FontWeight.w600,
      color: const ui.Color(0xE6FFFFFF),
      shadow: true,
    );
    badge.paint(canvas, ui.Offset(margin, margin));
    badgeSub.paint(canvas, ui.Offset(margin, margin + badge.height));

    // Peta kiri bawah (tanpa kotak), teks rata kanan di sebelahnya.
    final hasMap = map != null;
    final mapSize = math.min(w * 0.30, h * 0.22);
    final gap = 18 * u;
    final textLeft = hasMap ? margin + mapSize + gap : margin;
    final textWidth = w - margin - textLeft;

    final lines = <TextPainter>[];
    final note = stamp.note?.trim();
    if (note != null && note.isNotEmpty) {
      lines.add(
        _text(
          note,
          size: 32 * u,
          weight: FontWeight.w800,
          color: white,
          maxLines: 2,
          maxWidth: textWidth,
          shadow: true,
          alignRight: true,
        ),
      );
    }
    lines.add(
      _text(
        formatStampTime(stamp.capturedAt),
        size: 30 * u,
        weight: FontWeight.w800,
        color: white,
        maxWidth: textWidth,
        shadow: true,
        alignRight: true,
      ),
    );
    final address = stamp.address?.trim();
    if (address != null && address.isNotEmpty) {
      lines.add(
        _text(
          address,
          size: 26 * u,
          weight: FontWeight.w700,
          color: white,
          maxLines: 4,
          maxWidth: textWidth,
          shadow: true,
          alignRight: true,
        ),
      );
    }
    lines.add(
      _text(
        formatStampCoordinates(stamp),
        size: 24 * u,
        weight: FontWeight.w600,
        color: const ui.Color(0xF2FFFFFF),
        maxWidth: textWidth,
        shadow: true,
        alignRight: true,
      ),
    );

    final lineGap = 4 * u;
    final textHeight =
        lines.fold<double>(0, (sum, p) => sum + p.height) +
        lineGap * (lines.length - 1);
    final blockHeight = math.max(hasMap ? mapSize : 0.0, textHeight);
    final bottom = h - margin;

    if (hasMap) {
      final mapRect = ui.Rect.fromLTWH(
        margin,
        bottom - mapSize,
        mapSize,
        mapSize,
      );
      final rrect = ui.RRect.fromRectAndRadius(
        mapRect,
        ui.Radius.circular(8 * u),
      );
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawImageRect(
        map,
        ui.Rect.fromLTWH(0, 0, map.width.toDouble(), map.height.toDouble()),
        mapRect,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      canvas.restore();
      canvas.drawRRect(
        rrect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2 * u
          ..color = const ui.Color(0xCCFFFFFF),
      );
      _paintPin(canvas, mapRect.center, 26 * u);
    }

    var y = bottom - blockHeight + (blockHeight - textHeight);
    for (final line in lines) {
      line.paint(canvas, ui.Offset(textLeft, y));
      y += line.height + lineGap;
    }
  }

  static void _paintPin(ui.Canvas canvas, ui.Offset center, double size) {
    // Ujung runcing pin berada tepat di titik koordinat (tengah peta).
    final tip = center;
    final headCenter = ui.Offset(tip.dx, tip.dy - size * 1.1);
    final path = ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        tip.dx - size * 0.55,
        tip.dy - size * 0.55,
        headCenter.dx - size * 0.5,
        headCenter.dy + size * 0.1,
        headCenter.dx - size * 0.5,
        headCenter.dy,
      )
      ..arcToPoint(
        ui.Offset(headCenter.dx + size * 0.5, headCenter.dy),
        radius: ui.Radius.circular(size * 0.5),
      )
      ..cubicTo(
        headCenter.dx + size * 0.5,
        headCenter.dy + size * 0.1,
        tip.dx + size * 0.55,
        tip.dy - size * 0.55,
        tip.dx,
        tip.dy,
      )
      ..close();
    canvas.drawPath(path, ui.Paint()..color = const ui.Color(0xFFB91C1C));
    canvas.drawCircle(
      headCenter,
      size * 0.2,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  }

  static TextPainter _text(
    String text, {
    required double size,
    required FontWeight weight,
    required ui.Color color,
    int maxLines = 1,
    double maxWidth = double.infinity,
    bool shadow = false,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _font,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.25,
          shadows: shadow
              ? [
                  Shadow(
                    color: const ui.Color(0xCC000000),
                    blurRadius: size * 0.18,
                    offset: ui.Offset(0, size * 0.05),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      maxLines: maxLines,
      ellipsis: '…',
    );
    if (alignRight && maxWidth.isFinite) {
      painter.layout(minWidth: maxWidth, maxWidth: maxWidth);
    } else {
      painter.layout(maxWidth: maxWidth);
    }
    return painter;
  }

  /// "20/10/2026 09:30:15 WIB" (zona waktu dari perangkat).
  static String formatStampTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    final offset = time.timeZoneOffset.inHours;
    final zone = switch (offset) {
      7 => 'WIB',
      8 => 'WITA',
      9 => 'WIT',
      _ => 'UTC${offset >= 0 ? '+' : ''}$offset',
    };
    return '${two(time.day)}/${two(time.month)}/${time.year} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)} $zone';
  }

  /// "-7.327400, 108.220700 · ±12 m"
  static String formatStampCoordinates(GeoStamp stamp) {
    final coords =
        '${stamp.latitude.toStringAsFixed(6)}, ${stamp.longitude.toStringAsFixed(6)}';
    final acc = stamp.accuracyMeters;
    return acc == null ? coords : '$coords · ±${acc.round()} m';
  }
}
