import 'package:flutter/material.dart';

/// Tombol tengah yang menempel di bar bawah dan tidak ikut naik saat SnackBar/notifikasi
/// muncul (bawaan Scaffold menggesernya ke atas SnackBar).
class FabTetapDocked extends FloatingActionButtonLocation {
  const FabTetapDocked();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    final tanpaSnackBar = ScaffoldPrelayoutGeometry(
      bottomSheetSize: g.bottomSheetSize,
      contentBottom: g.contentBottom,
      contentTop: g.contentTop,
      floatingActionButtonSize: g.floatingActionButtonSize,
      materialBannerSize: g.materialBannerSize,
      minInsets: g.minInsets,
      minViewPadding: g.minViewPadding,
      scaffoldSize: g.scaffoldSize,
      snackBarSize: Size.zero,
      textDirection: g.textDirection,
    );
    return FloatingActionButtonLocation.centerDocked.getOffset(tanpaSnackBar);
  }
}
