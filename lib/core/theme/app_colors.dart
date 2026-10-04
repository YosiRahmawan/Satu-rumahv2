import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - Rustic Indulgence
  static const Color chilliDust = Color(0xFFB92216); // Primary
  static const Color champagneToast = Color(
    0xFFE7E6C2,
  ); // Secondary / Highlight
  static const Color cocoaBeanRoast = Color(0xFF402D18); // Dark Text
  static const Color pistachioCream = Color(0xFFB7C688); // Success / Accent

  // Support / Neutrals
  static const Color background = Color(0xFFFDFDFB); // Warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Greys
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Semantic aliases keep role screens on one visual contract.
  static const Color brandPrimary = chilliDust;
  static const Color actionPrimary = chilliDust;
  static const Color statusAttention = chilliDust;
  static const Color statusSuccess = Color(0xFF4B6B16);
  static const Color statusInfo = Color(0xFF0288D1);
  static const Color statusTechnical = Color(0xFF7B1FA2);
  static const Color statusSurvey = Color(0xFFE65100);
  static const Color statusApproved = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFF388E3C);
  static const Color notificationUnread = chilliDust;
  static const Color textPrimary = cocoaBeanRoast;
  static const Color textMuted = grey700;
  static const Color surfaceSubtle = grey50;
  static const Color borderSubtle = grey200;
  static const Color surfaceWarm = Color(0xFFF7F5EE);
  static const Color surfaceAttention = Color(0xFFF9EAE8);
  static const Color surfaceSuccess = Color(0xFFE2EED7);
  static const Color surfaceInfo = Color(0xFFE8E3CB);
  // Red & White Balanced Enterprise Tokens (design.md)
  static const Color primaryRed = Color(0xFFB91C1C);
  static const Color primaryDark = Color(0xFF881337);
  static const Color primaryMaroon = Color(0xFF991B1B);
  static const Color primarySurface = Color(0xFFFEE2E2);
  static const Color primarySurfaceSoft = Color(0xFFFFF1F2);
  static const Color primarySurfaceBorder = Color(0xFFFECDD3);
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color borderNeutral = Color(0xFFE2E8F0);
  static const Color dividerLine = Color(0xFFF1F5F9);

  // Semantic Status Tokens
  static const Color semanticSuccessText = Color(0xFF16A34A);
  static const Color semanticSuccessSurface = Color(0xFFDCFCE7);
  static const Color semanticSuccessBorder = Color(0xFFBBF7D0);
  static const Color semanticWarningText = Color(0xFFB45309);
  static const Color semanticWarningSurface = Color(0xFFFEF3C7);
  static const Color semanticDangerText = Color(0xFFB91C1C);
  static const Color semanticDangerSurface = Color(0xFFFEE2E2);
  static const Color semanticInfoText = Color(0xFF1D4ED8);
  static const Color semanticInfoSurface = Color(0xFFEFF6FF);
}
