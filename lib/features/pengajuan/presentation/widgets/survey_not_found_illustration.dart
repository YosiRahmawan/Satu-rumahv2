import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ilustrasi Vektor Custom untuk Empty-State "Jadwal Tidak Ditemukan"
///
/// Menggambarkan blueprint arsitektural kavling perumahan SATU RUMAH
/// yang sedang discan menggunakan lensa pencarian (magnifying glass)
/// dengan nuansa clean, modern, dan profesional.
class SurveyNotFoundIllustration extends StatelessWidget {
  final double width;
  final double height;

  const SurveyNotFoundIllustration({
    super.key,
    this.width = 200,
    this.height = 157,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ilustrasi pencarian jadwal survey tidak ditemukan',
      child: SizedBox(
        width: width,
        height: height,
        child: const CustomPaint(
          size: Size(280, 220),
          painter: _SurveyNotFoundPainter(),
        ),
      ),
    );
  }
}

class _SurveyNotFoundPainter extends CustomPainter {
  const _SurveyNotFoundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Menyesuaikan rasio dan skala dari kanvas dasar 280 x 220
    final scale = math.min(size.width / 280.0, size.height / 220.0);
    canvas.save();
    canvas.translate(
      (size.width - 280.0 * scale) / 2,
      (size.height - 220.0 * scale) / 2,
    );
    canvas.scale(scale, scale);

    // ────────────────────────────────────────────────────────────────────────
    // 1. Subtle Soft Background Atmosphere
    // ────────────────────────────────────────────────────────────────────────
    final atmosphereRect = Rect.fromCenter(
      center: const Offset(140, 180),
      width: 180,
      height: 32,
    );
    final atmospherePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(atmosphereRect, atmospherePaint);

    // ────────────────────────────────────────────────────────────────────────
    // 2. Architectural Grid Blueprint Paper (Opacity 0.85)
    // ────────────────────────────────────────────────────────────────────────
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 280, 220), Paint()..color = const Color(0xD9FFFFFF));

    // Base Blueprint Sheet
    final sheetRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(45, 42, 190, 136),
      const Radius.circular(14),
    );
    final sheetFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final sheetStroke = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(sheetRRect, sheetFill);
    canvas.drawRRect(sheetRRect, sheetStroke);

    // Blueprint Grid Lines (Dashed, strokeWidth: 1.5, color: #F1F5F9)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Horizontal grid lines
    _drawDashedLine(canvas, const Offset(45, 76), const Offset(235, 76), 4, 4, gridPaint);
    _drawDashedLine(canvas, const Offset(45, 110), const Offset(235, 110), 4, 4, gridPaint);
    _drawDashedLine(canvas, const Offset(45, 144), const Offset(235, 144), 4, 4, gridPaint);

    // Vertical grid lines
    _drawDashedLine(canvas, const Offset(82, 42), const Offset(82, 178), 4, 4, gridPaint);
    _drawDashedLine(canvas, const Offset(140, 42), const Offset(140, 178), 4, 4, gridPaint);
    _drawDashedLine(canvas, const Offset(198, 42), const Offset(198, 178), 4, 4, gridPaint);

    canvas.restore();

    // ────────────────────────────────────────────────────────────────────────
    // 3. Housing Cluster (Site Plan Silhouette)
    // ────────────────────────────────────────────────────────────────────────
    // Secondary House (Left)
    final leftHousePath = Path()
      ..moveTo(68, 132)
      ..lineTo(88, 114)
      ..lineTo(108, 132)
      ..lineTo(108, 156)
      ..lineTo(68, 156)
      ..close();
    final secHouseFill = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final secHouseStroke = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(leftHousePath, secHouseFill);
    canvas.drawPath(leftHousePath, secHouseStroke);

    // Window Left House
    final leftWindow = RRect.fromRectAndRadius(
      const Rect.fromLTWH(82, 130, 12, 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftWindow, Paint()..color = const Color(0xFFE2E8F0));

    // Secondary House (Right)
    final rightHousePath = Path()
      ..moveTo(172, 132)
      ..lineTo(192, 114)
      ..lineTo(212, 132)
      ..lineTo(212, 156)
      ..lineTo(172, 156)
      ..close();
    canvas.drawPath(rightHousePath, secHouseFill);
    canvas.drawPath(rightHousePath, secHouseStroke);

    // Window Right House
    final rightWindow = RRect.fromRectAndRadius(
      const Rect.fromLTWH(186, 130, 12, 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(rightWindow, Paint()..color = const Color(0xFFE2E8F0));

    // Center Main House Site Plot (Boundary with red dashed highlight, opacity 0.6)
    final plotRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(105, 96, 70, 66),
      const Radius.circular(8),
    );
    final plotFill = Paint()
      ..color = const Color(0xFFFEF2F2).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(plotRRect, plotFill);

    final plotStroke = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    _drawDashedRRect(canvas, plotRRect, 5, 4, plotStroke);

    // Main Center House (SATU RUMAH Signature Architecture)
    final centerHousePath = Path()
      ..moveTo(116, 124)
      ..lineTo(140, 102)
      ..lineTo(164, 124)
      ..lineTo(164, 156)
      ..lineTo(116, 156)
      ..close();
    final centerHouseStroke = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(centerHousePath, Paint()..color = Colors.white);
    canvas.drawPath(centerHousePath, centerHouseStroke);

    // Center House Roof Accent Line
    final roofAccent = Path()
      ..moveTo(112, 124)
      ..lineTo(140, 99)
      ..lineTo(168, 124);
    final roofAccentPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roofAccent, roofAccentPaint);

    // Attic Circular Window
    canvas.drawCircle(const Offset(140, 116), 4.5, Paint()..color = const Color(0xFFB91C1C));

    // Modern Door Frame
    final doorPath = Path()
      ..moveTo(133, 156)
      ..lineTo(133, 137)
      ..cubicTo(133, 135, 135, 133, 137, 133)
      ..lineTo(143, 133)
      ..cubicTo(145, 133, 147, 135, 147, 137)
      ..lineTo(147, 156);
    final doorStroke = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(doorPath, Paint()..color = const Color(0xFFFEE2E2));
    canvas.drawPath(doorPath, doorStroke);

    // ────────────────────────────────────────────────────────────────────────
    // 4. Modern Magnifying Glass (Search Lens Scanning Over Lot)
    // ────────────────────────────────────────────────────────────────────────
    // Drop Shadow
    final shadowOval = Rect.fromCenter(
      center: const Offset(178, 88),
      width: 52,
      height: 52,
    );
    canvas.drawOval(
      shadowOval,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );

    // Lens Outer Rim
    final outerRimPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(const Offset(174, 84), 30, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(174, 84), 30, outerRimPaint);

    // Lens Reflection Glass Tint
    canvas.drawCircle(
      const Offset(174, 84),
      26,
      Paint()..color = const Color(0xFFFEF2F2).withValues(alpha: 0.8),
    );

    // Lens Reflection Highlight Arc
    final highlightPath = Path()
      ..moveTo(158, 68)
      ..cubicTo(166, 60, 182, 60, 190, 68);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);

    // Crosshair House Silhouette Inside Lens
    final focusHousePath = Path()
      ..moveTo(164, 88)
      ..lineTo(174, 79)
      ..lineTo(184, 88)
      ..lineTo(184, 93)
      ..lineTo(164, 93)
      ..close();
    canvas.drawPath(
      focusHousePath,
      Paint()..color = const Color(0xFFB91C1C).withValues(alpha: 0.15),
    );

    final focusRoofPath = Path()
      ..moveTo(164, 88)
      ..lineTo(174, 79)
      ..lineTo(184, 88);
    final focusRoofPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(focusRoofPath, focusRoofPaint);
    canvas.drawCircle(const Offset(174, 84), 2.5, Paint()..color = const Color(0xFFB91C1C));

    // Crosshair Indicator Dots / Ticks
    final crosshairPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(174, 62), const Offset(174, 67), crosshairPaint);
    canvas.drawLine(const Offset(174, 101), const Offset(174, 106), crosshairPaint);
    canvas.drawLine(const Offset(152, 84), const Offset(157, 84), crosshairPaint);
    canvas.drawLine(const Offset(191, 84), const Offset(196, 84), crosshairPaint);

    // Magnifier Handle
    final handleBasePaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(196, 106), const Offset(224, 134), handleBasePaint);

    final handleInnerPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(198, 108), const Offset(222, 132), handleInnerPaint);

    // Handle End Cap
    canvas.drawCircle(const Offset(224, 134), 2.5, Paint()..color = const Color(0xFF7F1D1D));

    // ────────────────────────────────────────────────────────────────────────
    // 5. Decorative Question Mark Badge & Architectural Markers
    // ────────────────────────────────────────────────────────────────────────
    // Question Mark Badge at (68, 62)
    const badgeCenter = Offset(78, 72);
    final badgeCirclePaint = Paint()
      ..color = const Color(0xFFFEE2E2)
      ..style = PaintingStyle.fill;
    final badgeStrokePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(badgeCenter, 11, badgeCirclePaint);
    canvas.drawCircle(badgeCenter, 11, badgeStrokePaint);

    // Text "?" in badge
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB91C1C),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );

    // Tiny decorative survey markers
    final markerPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawCircle(const Offset(220, 56), 2.5, markerPaint);
    canvas.drawCircle(const Offset(228, 62), 1.5, markerPaint);

    // Cross marker at (59, 166)
    final crossMarkerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(56, 166), const Offset(62, 166), crossMarkerPaint);
    canvas.drawLine(const Offset(59, 163), const Offset(59, 169), crossMarkerPaint);

    canvas.restore();
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;
    final unitX = dx / distance;
    final unitY = dy / distance;
    double current = 0.0;
    while (current < distance) {
      final len = math.min(dashWidth, distance - current);
      final start = Offset(p1.dx + unitX * current, p1.dy + unitY * current);
      final end = Offset(p1.dx + unitX * (current + len), p1.dy + unitY * (current + len));
      canvas.drawLine(start, end, paint);
      current += dashWidth + dashSpace;
    }
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    double dashWidth,
    double dashSpace,
    Paint paint,
  ) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
