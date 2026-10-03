import 'package:flutter/material.dart';

/// Palet Warna Resmi SATU RUMAH (Red & White Balanced Enterprise)
/// Berdasarkan `design.md` Bagian 3 (Single Source of Truth).
///
/// Pantangan Mutlak: Tidak menggunakan warna cokelat tua (#231916, #1c1917, #402D18),
/// nuansa kayu/earth-tone kusam, atau dark-mode abu-abu arang pada header.
class AppColors {
  // ─── A. Warna Inti (Primary Brand Colors) ──────────────────────────────────
  /// Merah Dinas: tombol utama, ikon aktif, tab aktif, border aksen (#B91C1C)
  static const Color primaryRed = Color(0xFFB91C1C);

  /// Merah Marun Pekat: gradasi penutup hero banner dan app bar (#881337)
  static const Color primaryDark = Color(0xFF881337);

  /// Merah Marun Alternatif (#991B1B)
  static const Color primaryDarkAlt = Color(0xFF991B1B);

  /// Linear gradient standar hero banner (135deg #B91C1C -> #881337)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryDark],
  );

  // ─── B. Permukaan & Aksen (Surfaces & Accents) ────────────────────────────
  /// Wadah ikon, menu aktif, chip filter aktif, pill ID (#FEE2E2)
  static const Color primarySurface = Color(0xFFFEE2E2);

  /// Latar form peringatan, header tabel, kotak catatan revisi (#FFF1F2)
  static const Color primarySurfaceSoft = Color(0xFFFFF1F2);

  /// Garis pembatas kontainer merah muda (#FECDD3)
  static const Color primarySurfaceBorder = Color(0xFFFECDD3);

  // ─── C. Latar Belakang Netral (Canvas & Neutrals) ─────────────────────────
  /// Abu-abu terang bersih, bukan krem / bukan cokelat (#F8FAFC)
  static const Color backgroundCanvas = Color(0xFFF8FAFC);

  /// Putih murni kartu dan modal (#FFFFFF)
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Latar sidebar putih bersih (#FFFFFF)
  static const Color sidebarBackground = Color(0xFFFFFFFF);

  /// Garis pemisah netral (#E2E8F0)
  static const Color borderSubtle = Color(0xFFE2E8F0);

  /// Garis divider halus (#F1F5F9)
  static const Color dividerLine = Color(0xFFF1F5F9);

  // ─── D. Skala Netral Slate (Tailwind / Enterprise Slate) ──────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ─── E. Warna Teks (Typography Colors) ────────────────────────────────────
  /// Slate 900: Judul utama, heading, angka metrik (kontras tinggi, #0F172A)
  static const Color textMain = Color(0xFF0F172A);

  /// Slate 500: Subtitle deskriptif, teks muted, label sekunder (WCAG AA #64748B)
  static const Color textSecondary = Color(0xFF64748B);

  /// Slate 400: Metadata sekunder, timestamp (#94A3B8)
  static const Color textTertiary = Color(0xFF94A3B8);

  /// Putih murni di atas banner merah (#FFFFFF)
  static const Color textOnRed = Color(0xFFFFFFFF);

  /// Merah muda lembut untuk sub-teks di atas banner (#FECDD3)
  static const Color textOnRedSubtle = Color(0xFFFECDD3);

  // ─── F. Status Semantik Kedinasan (Semantic Status Badges) ─────────────────
  /// Sesuai / Disetujui (Hijau #16A34A / #DCFCE7)
  static const Color statusSuccessText = Color(0xFF16A34A);
  static const Color statusSuccessSurface = Color(0xFFDCFCE7);

  /// Perlu Perbaikan (Amber #B45309 / #FEF3C7)
  static const Color statusWarningText = Color(0xFFB45309);
  static const Color statusWarningSurface = Color(0xFFFEF3C7);

  /// Peringatan / Urgent / Ditolak (Merah #B91C1C / #FEE2E2)
  static const Color statusUrgentText = Color(0xFFB91C1C);
  static const Color statusUrgentSurface = Color(0xFFFEE2E2);

  /// Survey Lapangan (Biru #1D4ED8 / #EFF6FF)
  static const Color statusSurveyText = Color(0xFF1D4ED8);
  static const Color statusSurveySurface = Color(0xFFEFF6FF);

  // ─── G. Dukungan & Kompatibilitas Sistem Tema ──────────────────────────────
  static const Color background = backgroundCanvas;
  static const Color surface = cardSurface;
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1D4ED8);

  // Kompatibilitas alias lama agar tidak merusak screen atau test yang sudah ada
  static const Color chilliDust = primaryRed;
  static const Color champagneToast = textOnRedSubtle;
  static const Color cocoaBeanRoast = textMain;
  static const Color pistachioCream = Color(0xFF86EFAC);

  static const Color brandPrimary = primaryRed;
  static const Color actionPrimary = primaryRed;
  static const Color statusAttention = primaryRed;
  static const Color statusSuccess = statusSuccessText;
  static const Color statusInfo = Color(0xFF0288D1);
  static const Color statusTechnical = Color(0xFF7B1FA2);
  static const Color statusSurvey = statusSurveyText;
  static const Color statusApproved = statusSuccessText;
  static const Color statusCompleted = statusSuccessText;
  static const Color notificationUnread = primaryRed;
  static const Color textPrimary = textMain;
  static const Color textMuted = textSecondary;
  static const Color surfaceSubtle = slate50;
  static const Color surfaceWarm = primarySurfaceSoft;
  static const Color surfaceAttention = primarySurface;
  static const Color surfaceSuccess = statusSuccessSurface;
  static const Color surfaceInfo = statusSurveySurface;
  static const Color surfaceMuted = slate100;

  // Greys mapping ke Slate bersih
  static const Color grey50 = slate50;
  static const Color grey100 = slate100;
  static const Color grey200 = slate200;
  static const Color grey300 = slate300;
  static const Color grey400 = slate400;
  static const Color grey500 = slate500;
  static const Color grey600 = slate600;
  static const Color grey700 = slate700;
  static const Color grey800 = slate800;
  static const Color grey900 = slate900;

  // ─── H. Palet Peran Resmi (Role Palettes) ──────────────────────────────────
  static const Color roleDeveloperPrimary = primaryRed;
  static const Color roleDeveloperPrimaryLight = Color(0xFFDC2626);
  static const Color roleDeveloperAccent = primarySurface;
  static const Color roleDeveloperHeaderTitle = Colors.white;
  static const Color roleDeveloperHeaderSubtitle = textOnRedSubtle;

  static const Color roleAdminPrimary = primaryRed;
  static const Color roleAdminPrimaryDark = primaryDark;
  static const Color roleAdminAccent = primarySurface;
  static const Color roleAdminHeaderSubtitle = textOnRedSubtle;

  static const Color roleFieldPrimary = primaryRed;
  static const Color roleFieldPrimaryLight = Color(0xFFDC2626);
  static const Color roleFieldAccent = primarySurface;
  static const Color roleFieldHeaderSubtitle = textOnRedSubtle;

  static const Color roleNavUnselected = slate400;
}
