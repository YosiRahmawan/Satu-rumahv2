import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pengendali kanvas tanda tangan: hapus, cek isi, dan ekspor PNG transparan.
class SignaturePadController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  bool get hasInk => _strokes.any((s) => s.length > 1);

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  void _start(Offset p) {
    _strokes.add([p]);
    notifyListeners();
  }

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    notifyListeners();
  }

  /// PNG berlatar transparan (tinta hitam), diskalakan ke 600 px lebar.
  Future<Uint8List?> toPng() async {
    if (!hasInk || _size.isEmpty) return null;
    const width = 600.0;
    final scale = width / _size.width;
    final height = _size.height * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    SignaturePainter(
      _strokes,
      scale: scale,
      strokeWidth: 5,
    ).paint(canvas, Size(width, height));
    final image = await recorder.endRecording().toImage(
      width.round(),
      height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.strokes, {this.scale = 1, this.strokeWidth = 2.5});

  final List<List<Offset>> strokes;
  final double scale;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter old) => true;
}

/// Area menggambar tanda tangan dengan jari atau stylus.
class SignaturePad extends StatelessWidget {
  const SignaturePad({
    super.key,
    required this.controller,
    this.height = 180,
    this.onChanged,
  });

  final SignaturePadController controller;
  final double height;

  /// Dipanggil saat goresan selesai, untuk memperbarui pratinjau.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('signature-pad'),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, c) {
            controller._size = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => controller._start(d.localPosition),
              onPanUpdate: (d) => controller._extend(d.localPosition),
              onPanEnd: (_) => onChanged?.call(),
              child: ListenableBuilder(
                listenable: controller,
                builder: (_, _) => CustomPaint(
                  size: Size.infinite,
                  painter: SignaturePainter(controller._strokes),
                  child: controller.hasInk
                      ? const SizedBox.expand()
                      : const Center(
                          child: Text(
                            'Tanda tangan di sini',
                            style: TextStyle(
                              color: AppColors.enterpriseTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
