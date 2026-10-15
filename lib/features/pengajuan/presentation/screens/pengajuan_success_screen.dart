import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class PengajuanSuccessScreen extends ConsumerWidget {
  final String pengajuanId;

  const PengajuanSuccessScreen({super.key, required this.pengajuanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Icon dengan animasi pulse
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Center(
                    child: Semantics(
                      label:
                          'Maskot rumah tersenyum menandakan pengajuan berhasil',
                      child: SizedBox(
                        width: 220,
                        height: 181,
                        child: CustomPaint(painter: _MascotPainter()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Berhasil Disimpan!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Data dan dokumen pengajuan tersimpan secara lokal pada sesi demo ini untuk simulasi verifikasi berkas.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 24),

                // ID Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ID PENGAJUAN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pengajuanId,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primaryRed,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Banner notifikasi muncul
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccessSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.statusSuccessText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: AppColors.statusSuccessText,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Notifikasi simulasi telah ditambahkan ke tab Notifikasi Anda.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Lihat Notifikasi (navigasi ke tab Notifikasi = index 2)
                AppButton.primary(
                  text: 'Lihat Notifikasi',
                  onPressed: () {
                    ref.read(dashboardTabProvider.notifier).state = 2;
                    context.go('/dashboard');
                  },
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  text: 'Lihat Detail Pengajuan',
                  onPressed: () =>
                      context.push('/pengajuan/detail/$pengajuanId'),
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  text: 'Lihat Status Pengajuan',
                  onPressed: () {
                    ref.read(dashboardTabProvider.notifier).state = 1;
                    context.go('/dashboard');
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(dashboardTabProvider.notifier).state = 0;
                    context.go('/dashboard');
                  },
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maskot "Si Rumah": badan manusia berjas merah dengan kepala berbentuk
/// rumah yang tersenyum, plus lencana centang hijau tanda sukses.
class _MascotPainter extends CustomPainter {
  _MascotPainter();

  static const _slate = Color(0xFF1E293B);
  static const _skin = Color(0xFFF6C9A8);
  static const _blush = Color(0xFFFECDD3);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 260);

    Paint fill(Color c) => Paint()..color = c;
    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void box(double x, double y, double w, double h, double r, Paint p) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          p,
        );
    void oval(double cx, double cy, double rx, double ry, Paint p) =>
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: rx * 2,
            height: ry * 2,
          ),
          p,
        );
    void confetti(double cx, double cy, double angle, Color c) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      box(-3.5, -3.5, 7, 7, 2, fill(c));
      canvas.restore();
    }

    // Bayangan, kaki, dan sepatu.
    oval(124, 204, 58, 6, fill(AppColors.borderSubtle));
    box(100, 172, 15, 26, 4, fill(_slate));
    box(125, 172, 15, 26, 4, fill(_slate));
    oval(105, 199, 13, 5, fill(AppColors.textMain));
    oval(135, 199, 13, 5, fill(AppColors.textMain));

    // Lengan kiri turun, lengan kanan terangkat.
    canvas.drawLine(
      const Offset(92, 130),
      const Offset(74, 160),
      line(AppColors.primaryRed, 14),
    );
    canvas.drawCircle(const Offset(72, 164), 8, fill(_skin));
    canvas.drawLine(
      const Offset(148, 130),
      const Offset(176, 100),
      line(AppColors.primaryRed, 14),
    );
    canvas.drawCircle(const Offset(180, 95), 8, fill(_skin));

    // Badan berjas merah dengan kerah putih.
    box(88, 120, 64, 62, 14, fill(AppColors.primaryRed));
    canvas.drawPath(
      Path()
        ..moveTo(112, 120)
        ..lineTo(120, 134)
        ..lineTo(128, 120)
        ..close(),
      fill(Colors.white),
    );
    box(116, 146, 8, 8, 4, fill(AppColors.primarySurface));

    // Kepala berbentuk rumah: dinding, atap, cerobong.
    box(80, 56, 80, 68, 4, fill(Colors.white));
    box(80, 56, 80, 68, 4, line(AppColors.borderSubtle, 1));
    canvas.drawPath(
      Path()
        ..moveTo(66, 60)
        ..lineTo(120, 14)
        ..lineTo(174, 60)
        ..close(),
      fill(AppColors.primaryDark),
    );
    canvas.drawPath(
      Path()
        ..moveTo(78, 60)
        ..lineTo(120, 24)
        ..lineTo(162, 60)
        ..close(),
      fill(AppColors.primaryRed),
    );
    box(142, 20, 12, 26, 2, fill(AppColors.primaryDark));

    // Wajah: mata senang, pipi, senyum.
    final face = line(AppColors.textMain, 3);
    canvas.drawPath(
      Path()
        ..moveTo(96, 88)
        ..quadraticBezierTo(103, 80, 110, 88),
      face,
    );
    canvas.drawPath(
      Path()
        ..moveTo(130, 88)
        ..quadraticBezierTo(137, 80, 144, 88),
      face,
    );
    canvas.drawCircle(const Offset(94, 102), 6, fill(_blush));
    canvas.drawCircle(const Offset(146, 102), 6, fill(_blush));
    canvas.drawPath(
      Path()
        ..moveTo(104, 102)
        ..quadraticBezierTo(120, 118, 136, 102),
      face,
    );

    // Lencana centang hijau.
    canvas.drawCircle(
      const Offset(204, 62),
      20,
      fill(AppColors.statusSuccessText),
    );
    canvas.drawPath(
      Path()
        ..moveTo(194, 62)
        ..lineTo(201, 70)
        ..lineTo(215, 54),
      line(Colors.white, 5),
    );

    // Konfeti kecil.
    confetti(40, 52, 0.35, _blush);
    confetti(216, 116, -0.26, _blush);
    confetti(61, 23, 0.61, AppColors.primaryRed);
    canvas.drawCircle(const Offset(48, 92), 4, fill(AppColors.primaryRed));
    canvas.drawCircle(const Offset(30, 132), 3, fill(_blush));
    canvas.drawCircle(const Offset(234, 26), 3.5, fill(AppColors.primaryRed));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
