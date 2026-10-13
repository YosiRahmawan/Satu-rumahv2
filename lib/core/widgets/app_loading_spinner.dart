import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ukuran standar untuk [AppLoadingSpinner]
enum AppSpinnerSize {
  /// 18dp — Untuk tombol kecil, badge, atau inline indikator
  small(18.0, 2.0),

  /// 24dp — Ukuran standar untuk tombol utama dan form action
  medium(24.0, 2.5),

  /// 32dp — Ukuran besar untuk preview dokumen atau aksi modal
  large(32.0, 3.0);

  final double dimension;
  final double strokeWidth;

  const AppSpinnerSize(this.dimension, this.strokeWidth);
}

/// [AppLoadingSpinner]
///
/// Indikator loading melingkar (Circular Progress Indicator) yang reusable
/// untuk tombol dan aksi ringan di aplikasi SATU RUMAH V2.
///
/// Fitur:
/// - Warna default Primary Red (#B91C1C)
/// - Mendukung spinner putih untuk tombol berlatar merah
/// - Stroke caps melengkung (StrokeCap.round)
/// - Rotasi kontinu yang halus tanpa gradient, glow, shadow, atau bounce
/// - Tiga ukuran standar: small (18dp), medium (24dp), large (32dp)
/// - Aksesibilitas (screen reader semantics)
class AppLoadingSpinner extends StatelessWidget {
  final AppSpinnerSize size;
  final double? customDimension;
  final Color? color;
  final double? strokeWidth;
  final String semanticsLabel;

  const AppLoadingSpinner({
    super.key,
    this.size = AppSpinnerSize.medium,
    this.customDimension,
    this.color,
    this.strokeWidth,
    this.semanticsLabel = 'Memuat...',
  });

  const AppLoadingSpinner.small({
    super.key,
    this.customDimension,
    this.color,
    this.strokeWidth,
    this.semanticsLabel = 'Memuat...',
  }) : size = AppSpinnerSize.small;

  const AppLoadingSpinner.medium({
    super.key,
    this.customDimension,
    this.color,
    this.strokeWidth,
    this.semanticsLabel = 'Memuat...',
  }) : size = AppSpinnerSize.medium;

  const AppLoadingSpinner.large({
    super.key,
    this.customDimension,
    this.color,
    this.strokeWidth,
    this.semanticsLabel = 'Memuat...',
  }) : size = AppSpinnerSize.large;

  /// Spinner putih khusus untuk digunakan di dalam tombol bertema merah.
  const AppLoadingSpinner.buttonWhite({
    super.key,
    this.size = AppSpinnerSize.small,
    this.customDimension,
    this.strokeWidth,
    this.semanticsLabel = 'Memproses...',
  }) : color = Colors.white;

  @override
  Widget build(BuildContext context) {
    final effectiveDimension = customDimension ?? size.dimension;
    final effectiveStrokeWidth = strokeWidth ?? size.strokeWidth;
    final effectiveColor = color ?? AppColors.primaryRed;

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: effectiveDimension,
        height: effectiveDimension,
        child: CircularProgressIndicator(
          strokeWidth: effectiveStrokeWidth,
          strokeCap: StrokeCap.round,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
        ),
      ),
    );
  }
}
