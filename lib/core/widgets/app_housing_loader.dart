import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Pilihan ukuran standar untuk [AppHousingLoader]
enum AppHousingLoaderSize {
  /// 64dp — Untuk card loading atau ruang terbatas
  small(64.0),

  /// 96dp — Ukuran default untuk view konten dan dialog
  medium(96.0),

  /// 120dp — Ukuran besar untuk full page loading
  large(120.0);

  final double dimension;

  const AppHousingLoaderSize(this.dimension);
}

/// [AppHousingLoader]
///
/// Indikator loading animasi kluster perumahan SATU RUMAH V2
/// berdasarkan referensi visual dan motion Google Stitch.
///
/// Fitur:
/// - Lapisan 1: Ring progress berputar kontinu searah jarum jam (1500ms, linear)
/// - Lapisan 2: Kluster rumah statis (tidak berputar) dengan perakitan awal (700ms, easeOutCubic)
/// - Warna brand resmi:
///     - Primary Red: #B91C1C
///     - Dark Red: #881337
///     - Soft Red: #FEE2E2
///     - Slate: #64748B
/// - Tiga ukuran standar: small (64dp), medium (96dp), large (120dp)
/// - Latar belakang transparan (kompatibel dengan canvas putih maupun #F8FAFC)
/// - Mendukung reduced-motion untuk aksesibilitas
/// - Pesan loading opsional di bawah animasi
class AppHousingLoader extends StatefulWidget {
  final AppHousingLoaderSize size;
  final double? customDimension;
  final String? message;
  final String? semanticsLabel;

  const AppHousingLoader({
    super.key,
    this.size = AppHousingLoaderSize.medium,
    this.customDimension,
    this.message,
    this.semanticsLabel,
  });

  const AppHousingLoader.small({
    super.key,
    this.message,
    this.semanticsLabel,
  })  : size = AppHousingLoaderSize.small,
        customDimension = null;

  const AppHousingLoader.medium({
    super.key,
    this.message,
    this.semanticsLabel,
  })  : size = AppHousingLoaderSize.medium,
        customDimension = null;

  const AppHousingLoader.large({
    super.key,
    this.message,
    this.semanticsLabel,
  })  : size = AppHousingLoaderSize.large,
        customDimension = null;

  @override
  State<AppHousingLoader> createState() => _AppHousingLoaderState();
}

class _AppHousingLoaderState extends State<AppHousingLoader>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _assemblyController;

  late final Animation<double> _baselineScale;
  late final Animation<double> _baselineOpacity;

  late final Animation<double> _centerHouseTranslate;
  late final Animation<double> _centerHouseOpacity;

  late final Animation<double> _sideHousesTranslate;
  late final Animation<double> _sideHousesOpacity;

  late final Animation<double> _detailsOpacity;

  bool _initializedMotion = false;

  // Cubic(0.33, 1.0, 0.68, 1.0) merepresentasikan cubic-bezier(0.33, 1, 0.68, 1) Stitch
  static const Curve _stitchEaseOut = Cubic(0.33, 1.0, 0.68, 1.0);

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _assemblyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 1. Baseline assembly (0.0s - 0.5s -> 0.0 - 0.714)
    _baselineScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.0, 0.714, curve: _stitchEaseOut),
      ),
    );
    _baselineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.0, 0.714, curve: _stitchEaseOut),
      ),
    );

    // 2. Center house assemble (0.0s - 0.7s -> 0.0 - 1.0)
    _centerHouseTranslate = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.0, 1.0, curve: _stitchEaseOut),
      ),
    );
    _centerHouseOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.0, 1.0, curve: _stitchEaseOut),
      ),
    );

    // 3. Side houses assemble (0.0s - 0.7s dengan delay 35% -> 0.35 - 1.0)
    _sideHousesTranslate = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.35, 1.0, curve: _stitchEaseOut),
      ),
    );
    _sideHousesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.35, 1.0, curve: _stitchEaseOut),
      ),
    );

    // 4. Details fade in (0.0s - 0.7s dengan delay 60% -> 0.60 - 1.0)
    _detailsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _assemblyController,
        curve: const Interval(0.60, 1.0, curve: _stitchEaseOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedMotion) {
      _initializedMotion = true;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _assemblyController.value = 1.0;
      } else {
        _assemblyController.forward();
        _rotationController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _assemblyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDimension = widget.customDimension ?? widget.size.dimension;
    final semanticsText =
        widget.semanticsLabel ?? widget.message ?? 'Memuat data...';

    return Semantics(
      label: semanticsText,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: effectiveDimension,
            height: effectiveDimension,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 512,
                height: 512,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // LAYER 1: ROTATING CIRCULAR PROGRESS RING
                    RotationTransition(
                      turns: _rotationController,
                      child: const CustomPaint(
                        size: Size(512, 512),
                        painter: _HousingRingPainter(),
                      ),
                    ),

                    // LAYER 2: STATIONARY HOUSING CLUSTER (TIDAK BERPUTAR)
                    AnimatedBuilder(
                      animation: _assemblyController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(512, 512),
                          painter: _HousingClusterPainter(
                            baselineScale: _baselineScale.value,
                            baselineOpacity: _baselineOpacity.value,
                            centerHouseTranslate: _centerHouseTranslate.value,
                            centerHouseOpacity: _centerHouseOpacity.value,
                            sideHousesTranslate: _sideHousesTranslate.value,
                            sideHousesOpacity: _sideHousesOpacity.value,
                            detailsOpacity: _detailsOpacity.value,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Painter untuk Lapisan 1: Rotating Ring
class _HousingRingPainter extends CustomPainter {
  const _HousingRingPainter();

  static const Color _primaryRed = Color(0xFFB91C1C);
  static const Color _darkRed = Color(0xFF881337);
  static const Color _softRed = Color(0xFFFEE2E2);

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(256, 256);
    const radius = 216.0;

    // 1. Inactive track ring (dashed, opacity 0.45)
    final trackPaint = Paint()
      ..color = _softRed.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    // Keliling lingkaran: 2 * pi * 216 ≈ 1357.17
    // Dash 8, Gap 16 -> Panjang siklus 24 (~56.5 segmen)
    const totalSegments = 56;
    const sweepAngle = (8.0 / 216.0);
    const stepAngle = (2 * math.pi) / totalSegments;

    final circleRect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < totalSegments; i++) {
      final startAngle = i * stepAngle;
      canvas.drawArc(circleRect, startAngle, sweepAngle, false, trackPaint);
    }

    // 2. Active progress arc (~270 derajat, berakhir di puncak 12 o'clock / (256, 40))
    // Mulai dari 0 rad (3 o'clock) sampai 1.5 * pi (12 o'clock)
    final activePaint = Paint()
      ..color = _primaryRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(circleRect, 0, 1.5 * math.pi, false, activePaint);

    // 3. Leading edge maroon accent dot pada puncak (256, 40)
    final dotPaint = Paint()
      ..color = _darkRed
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(256, 40), 7.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk Lapisan 2: Housing Cluster (Statik, hanya terpengaruh assembly animasi)
class _HousingClusterPainter extends CustomPainter {
  final double baselineScale;
  final double baselineOpacity;
  final double centerHouseTranslate;
  final double centerHouseOpacity;
  final double sideHousesTranslate;
  final double sideHousesOpacity;
  final double detailsOpacity;

  const _HousingClusterPainter({
    required this.baselineScale,
    required this.baselineOpacity,
    required this.centerHouseTranslate,
    required this.centerHouseOpacity,
    required this.sideHousesTranslate,
    required this.sideHousesOpacity,
    required this.detailsOpacity,
  });

  static const Color _primaryRed = Color(0xFFB91C1C);
  static const Color _darkRed = Color(0xFF881337);
  static const Color _softRed = Color(0xFFFEE2E2);
  static const Color _slate = Color(0xFF64748B);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // ─── A. Architectural Ground Baseline (y = 344) ──────────────────────────
    if (baselineOpacity > 0.0) {
      canvas.save();
      // Origin: (256, 344)
      canvas.translate(256, 344);
      canvas.scale(baselineScale, 1.0);
      canvas.translate(-256, -344);

      final baselinePaint = Paint()
        ..color = _darkRed.withValues(alpha: baselineOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        const Offset(120, 344),
        const Offset(392, 344),
        baselinePaint,
      );
      canvas.restore();
    }

    // ─── B. Side Houses (Left & Right) ───────────────────────────────────────
    if (sideHousesOpacity > 0.0) {
      canvas.save();
      canvas.translate(0, sideHousesTranslate);

      final fillPaint = Paint()
        ..color = _white.withValues(alpha: sideHousesOpacity)
        ..style = PaintingStyle.fill;

      final roofPaint = Paint()
        ..color = _primaryRed.withValues(alpha: sideHousesOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final slateLinePaint = Paint()
        ..color = _slate.withValues(alpha: sideHousesOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      // 1. Left House
      // Path: M144 260 L188 224 L232 260 V344 H144 Z
      final leftHousePath = Path()
        ..moveTo(144, 260)
        ..lineTo(188, 224)
        ..lineTo(232, 260)
        ..lineTo(232, 344)
        ..lineTo(144, 344)
        ..close();
      canvas.drawPath(leftHousePath, fillPaint);

      // Roof: M136 266 L188 224 L232 260
      final leftRoofPath = Path()
        ..moveTo(136, 266)
        ..lineTo(188, 224)
        ..lineTo(232, 260);
      canvas.drawPath(leftRoofPath, roofPaint);

      // Slate vertical: x=148, y=264 to 344
      canvas.drawLine(
        const Offset(148, 264),
        const Offset(148, 344),
        slateLinePaint,
      );

      // 2. Right House
      // Path: M280 260 L324 224 L368 260 V344 H280 Z
      final rightHousePath = Path()
        ..moveTo(280, 260)
        ..lineTo(324, 224)
        ..lineTo(368, 260)
        ..lineTo(368, 344)
        ..lineTo(280, 344)
        ..close();
      canvas.drawPath(rightHousePath, fillPaint);

      // Roof: M280 260 L324 224 L376 266
      final rightRoofPath = Path()
        ..moveTo(280, 260)
        ..lineTo(324, 224)
        ..lineTo(376, 266);
      canvas.drawPath(rightRoofPath, roofPaint);

      // Slate vertical: x=364, y=264 to 344
      canvas.drawLine(
        const Offset(364, 264),
        const Offset(364, 344),
        slateLinePaint,
      );

      canvas.restore();
    }

    // ─── C. Center House (Dominant Core) ─────────────────────────────────────
    if (centerHouseOpacity > 0.0) {
      canvas.save();
      canvas.translate(0, centerHouseTranslate);

      final centerFillPaint = Paint()
        ..color = _white.withValues(alpha: centerHouseOpacity)
        ..style = PaintingStyle.fill;

      // Fill: M208 226 L256 182 L304 226 V344 H208 Z
      final centerPath = Path()
        ..moveTo(208, 226)
        ..lineTo(256, 182)
        ..lineTo(304, 226)
        ..lineTo(304, 344)
        ..lineTo(208, 344)
        ..close();
      canvas.drawPath(centerPath, centerFillPaint);

      // Wall outline: M214 230 V344 H298 V230
      final centerWallPaint = Paint()
        ..color = _darkRed.withValues(alpha: centerHouseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeJoin = StrokeJoin.round;

      final wallPath = Path()
        ..moveTo(214, 230)
        ..lineTo(214, 344)
        ..lineTo(298, 344)
        ..lineTo(298, 230);
      canvas.drawPath(wallPath, centerWallPaint);

      // Roof: M196 236 L256 182 L316 236
      final centerRoofPaint = Paint()
        ..color = _primaryRed.withValues(alpha: centerHouseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final centerRoofPath = Path()
        ..moveTo(196, 236)
        ..lineTo(256, 182)
        ..lineTo(316, 236);
      canvas.drawPath(centerRoofPath, centerRoofPaint);

      // Base accent line: x1=234, x2=278, y=344
      final baseAccentPaint = Paint()
        ..color = _darkRed.withValues(alpha: centerHouseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        const Offset(234, 344),
        const Offset(278, 344),
        baseAccentPaint,
      );

      canvas.restore();
    }

    // ─── D. Windows & Doors (Fade-in Details) ─────────────────────────────────
    if (detailsOpacity > 0.0) {
      canvas.save();
      // Ikuti translasi center house untuk details
      canvas.translate(0, centerHouseTranslate);

      final softRedFill = Paint()
        ..color = _softRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.fill;

      // 1. Left House Window: x=168, y=270, w=22, h=22, rx=3
      final leftWindowRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(168, 270, 22, 22),
        const Radius.circular(3),
      );
      canvas.drawRRect(leftWindowRect, softRedFill);

      final leftWindowBorder = Paint()
        ..color = _primaryRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawRRect(leftWindowRect, leftWindowBorder);

      final leftWindowDividers = Paint()
        ..color = _primaryRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(const Offset(179, 270), const Offset(179, 292), leftWindowDividers);
      canvas.drawLine(const Offset(168, 281), const Offset(190, 281), leftWindowDividers);

      // 2. Right House Window: x=322, y=270, w=22, h=22, rx=3
      final rightWindowRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(322, 270, 22, 22),
        const Radius.circular(3),
      );
      canvas.drawRRect(rightWindowRect, softRedFill);

      final rightWindowBorder = Paint()
        ..color = _primaryRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawRRect(rightWindowRect, rightWindowBorder);

      final rightWindowDividers = Paint()
        ..color = _primaryRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(const Offset(333, 270), const Offset(333, 292), rightWindowDividers);
      canvas.drawLine(const Offset(322, 281), const Offset(344, 281), rightWindowDividers);

      // 3. Center House Window: x=242, y=222, w=28, h=28, rx=4
      final centerWindowRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(242, 222, 28, 28),
        const Radius.circular(4),
      );
      canvas.drawRRect(centerWindowRect, softRedFill);

      final centerWindowBorder = Paint()
        ..color = _darkRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5;
      canvas.drawRRect(centerWindowRect, centerWindowBorder);

      final centerWindowDividers = Paint()
        ..color = _darkRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawLine(const Offset(256, 222), const Offset(256, 250), centerWindowDividers);
      canvas.drawLine(const Offset(242, 236), const Offset(270, 236), centerWindowDividers);

      // 4. Center House Door: M243 344 V286 H269 V344
      final doorPath = Path()
        ..moveTo(243, 344)
        ..lineTo(243, 286)
        ..lineTo(269, 286)
        ..lineTo(269, 344);

      final doorFillPaint = Paint()
        ..color = _primaryRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(doorPath, doorFillPaint);

      final doorStrokePaint = Paint()
        ..color = _darkRed.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(doorPath, doorStrokePaint);

      // Door Knob: circle cx=262, cy=316, r=2.5
      final doorKnobPaint = Paint()
        ..color = _white.withValues(alpha: detailsOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(262, 316), 2.5, doorKnobPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HousingClusterPainter oldDelegate) {
    return baselineScale != oldDelegate.baselineScale ||
        baselineOpacity != oldDelegate.baselineOpacity ||
        centerHouseTranslate != oldDelegate.centerHouseTranslate ||
        centerHouseOpacity != oldDelegate.centerHouseOpacity ||
        sideHousesTranslate != oldDelegate.sideHousesTranslate ||
        sideHousesOpacity != oldDelegate.sideHousesOpacity ||
        detailsOpacity != oldDelegate.detailsOpacity;
  }
}
