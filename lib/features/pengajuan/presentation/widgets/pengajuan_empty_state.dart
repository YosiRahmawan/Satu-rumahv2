import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_illustration.dart';

/// Professional Housing & Site Plan Architectural Illustration
/// Faithful vector representation of Google Stitch design.
class HousingSitePlanIllustration extends StatelessWidget {
  const HousingSitePlanIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial glow behind the blueprint
          Container(
            width: 140,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x33FEE2E2), // soft rose tint
                  Color(0x1AF1F5F9), // subtle slate tint
                  Colors.transparent,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          // Custom Painted Architectural Blueprint & House Vector
          const CustomPaint(
            size: Size(150, 120),
            painter: _HousingSitePlanPainter(),
          ),
        ],
      ),
    );
  }
}

class _HousingSitePlanPainter extends CustomPainter {
  const _HousingSitePlanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 160.0, size.height / 128.0);
    canvas.save();
    canvas.translate(
      (size.width - 160.0 * scale) / 2,
      (size.height - 128.0 * scale) / 2,
    );
    canvas.scale(scale, scale);

    // 1. Foundation Sheet (Rect with rounded corners at x:22, y:24, w:116, h:84)
    final foundationRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 24, 116, 84),
      const Radius.circular(8),
    );
    final foundationFill = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final foundationStroke = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(foundationRect, foundationFill);
    canvas.drawRRect(foundationRect, foundationStroke);

    // 2. Blueprint Coordinate Grid (Dashed Lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedLine(
      canvas,
      const Offset(42, 24),
      const Offset(42, 108),
      3,
      3,
      gridPaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(80, 24),
      const Offset(80, 108),
      3,
      3,
      gridPaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(118, 24),
      const Offset(118, 108),
      3,
      3,
      gridPaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(22, 52),
      const Offset(138, 52),
      3,
      3,
      gridPaint,
    );
    _drawDashedLine(
      canvas,
      const Offset(22, 80),
      const Offset(138, 80),
      3,
      3,
      gridPaint,
    );

    // 3. Folded Corner Sheet Detail (M126 24 V36 H138)
    final foldPath = Path()
      ..moveTo(126, 24)
      ..lineTo(126, 36)
      ..lineTo(138, 36)
      ..close();
    final foldFill = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final foldStroke = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(foldPath, foldFill);
    canvas.drawPath(foldPath, foldStroke);

    // 4. Plot Land Subdivision Boundary 1 (Red Plot at x:34, y:44, w:46, h:52)
    final plot1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 44, 46, 52),
      const Radius.circular(4),
    );
    final plot1Fill = Paint()
      ..color = const Color(0x40FEE2E2)
      ..style = PaintingStyle.fill;
    final plot1Stroke = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(plot1, plot1Fill);
    _drawDashedRRect(canvas, plot1, 2, 2, plot1Stroke);

    // 5. Plot Land Subdivision Boundary 2 (Slate Plot at x:86, y:58, w:40, h:38)
    final plot2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(86, 58, 40, 38),
      const Radius.circular(4),
    );
    final plot2Fill = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    final plot2Stroke = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(plot2, plot2Fill);
    _drawDashedRRect(canvas, plot2, 2, 2, plot2Stroke);

    // 6. House Silhouette 1 (Main Gable Civic Housing at x:44-70, y:51-76)
    final house1Path = Path()
      ..moveTo(44, 76)
      ..lineTo(44, 62)
      ..lineTo(57, 51)
      ..lineTo(70, 62)
      ..lineTo(70, 76)
      ..close();
    final house1Fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final house1Stroke = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(house1Path, house1Fill);
    canvas.drawPath(house1Path, house1Stroke);

    // House 1 Door & Attic Detail
    final doorPath = Path()
      ..moveTo(54, 76)
      ..lineTo(54, 69)
      ..lineTo(60, 69)
      ..lineTo(60, 76);
    final doorPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(doorPath, doorPaint);

    final atticPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(57, 59), 2.5, atticPaint);

    // 7. House Silhouette 2 (Secondary Residential Unit at x:92-116, y:63-84)
    final house2Path = Path()
      ..moveTo(92, 84)
      ..lineTo(92, 73)
      ..lineTo(104, 63)
      ..lineTo(116, 73)
      ..lineTo(116, 84)
      ..close();
    final house2Stroke = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(house2Path, house1Fill);
    canvas.drawPath(house2Path, house2Stroke);

    // House 2 Window Detail
    final windowPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(100, 75, 8, 9), windowPaint);

    // 8. Cad Scale Ruler Motif at Bottom (x:40, y:99, w:34)
    final rulerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(40, 99, 34, 2), rulerPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(40, 97), const Offset(40, 101), tickPaint);
    canvas.drawLine(const Offset(57, 98), const Offset(57, 101), tickPaint);
    canvas.drawLine(const Offset(74, 97), const Offset(74, 101), tickPaint);

    // 9. Search Marker / Magnifying Glass with Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33B91C1C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(114, 45), 14, shadowPaint);

    // Outer Glass Circle
    final glassFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final glassStroke = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(const Offset(114, 42), 14, glassFill);
    canvas.drawCircle(const Offset(114, 42), 14, glassStroke);

    // Inner Lens Circle
    final innerLensPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(111, 39), 5.0, innerLensPaint);

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(115, 43), const Offset(120, 48), handlePaint);

    // Question Mark Micro-Indicator inside Glass
    final qMarkPath = Path()
      ..moveTo(110, 37.5)
      ..cubicTo(110, 36.8, 110.5, 36.2, 111.2, 36.2)
      ..cubicTo(111.9, 36.2, 112.4, 36.7, 112.4, 37.3)
      ..cubicTo(112.4, 38.0, 111.5, 38.3, 111.5, 39.0);
    final qMarkPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(qMarkPath, qMarkPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(111.5, 40.5), 0.6, dotPaint);

    canvas.restore();
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    double dashLen,
    double gapLen,
    Paint paint,
  ) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final unitX = dx / distance;
    final unitY = dy / distance;

    double current = 0.0;
    while (current < distance) {
      final startX = p1.dx + unitX * current;
      final startY = p1.dy + unitY * current;
      final endDistance = math.min(current + dashLen, distance);
      final endX = p1.dx + unitX * endDistance;
      final endY = p1.dy + unitY * endDistance;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      current += dashLen + gapLen;
    }
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    double dashLen,
    double gapLen,
    Paint paint,
  ) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashLen, metric.length - distance);
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Google Stitch Redesigned Empty State for Developer Pengajuan
class PengajuanEmptyState extends StatefulWidget {
  final bool isFilteredEmpty;
  final int totalRegistered;
  final FutureOr<void> Function()? onReset;
  final VoidCallback? onCreateNew;

  const PengajuanEmptyState({
    super.key,
    required this.isFilteredEmpty,
    this.totalRegistered = 0,
    this.onReset,
    this.onCreateNew,
  });

  @override
  State<PengajuanEmptyState> createState() => _PengajuanEmptyStateState();
}

class _PengajuanEmptyStateState extends State<PengajuanEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;
    if (widget.onReset == null) return;

    try {
      final dynamic result = widget.onReset!();
      if (result is Future) {
        setState(() => _isLoading = true);
        _rotationController.repeat();
        await result;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mereset pencarian dan filter: $e')),
        );
      }
    } finally {
      if (mounted) {
        if (_isLoading) {
          _rotationController.stop();
          _rotationController.reset();
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _handleCreateNew() {
    if (widget.onCreateNew != null) {
      widget.onCreateNew!();
    } else {
      context.push('/pengajuan/step1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFilteredEmpty
        ? 'Tidak ada pengajuan ditemukan'
        : 'Belum ada pengajuan';

    final message = widget.isFilteredEmpty
        ? 'Coba ubah kata kunci, status, atau filter tahun untuk melihat hasil lainnya.'
        : 'Mulai pengajuan pertama Anda untuk mengajukan site plan dan dokumen perumahan.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. White Card (Rounded 16dp, subtle border & shadow, clean padding)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // B. Empty State Illustration
              if (widget.isFilteredEmpty)
                Semantics(
                  label:
                      'Maskot SATU RUMAH memeriksa dokumen tidak ada pengajuan ditemukan',
                  child: const AppIllustration(AppIllustration.hasilSurvey),
                )
              else
                Semantics(
                  label: 'Maskot SATU RUMAH mengajak membuat pengajuan pertama',
                  child: const AppIllustration(AppIllustration.tugasLapangan),
                ),
              const SizedBox(height: 20),

              // C. Headline
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // D. Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // E. Action Button (Filtered: Reset / Zero Submissions: Buat Pengajuan)
              if (widget.isFilteredEmpty && widget.onReset != null) ...[
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          disabledBackgroundColor: Colors.white,
                          disabledForegroundColor: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.6),
                          elevation: 1,
                          shadowColor: const Color(0x1A0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              RotationTransition(
                                turns: _rotationController,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            else
                              const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: Color(0xFF0F172A),
                              ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Reset pencarian dan filter',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Semua data pengajuan akan ditampilkan kembali.',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.slate400,
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (!widget.isFilteredEmpty) ...[
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    onPressed: _handleCreateNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.textOnRed,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: AppColors.textOnRed,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Buat Pengajuan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: AppColors.textOnRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
