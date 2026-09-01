// File: lib/app/app_colors.dart
// Purpose: Design system color tokens for The Realty Bazaar (#397BCF).

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // Primary Palette (#397BCF Brand Ecosystem)
  // ==========================================
  static const Color primary50 = Color(0xFFF3F8FE);
  static const Color primary100 = Color(0xFFEAF3FF);
  static const Color primary200 = Color(0xFFD4E6FC);
  static const Color primary300 = Color(0xFFA6CBF7);
  static const Color primary400 = Color(0xFF6FA5E5);
  static const Color primary500 = Color(0xFF397BCF); // Core Brand
  static const Color primary600 = Color(0xFF245FA8);
  static const Color primary700 = Color(0xFF1C4D8B);
  static const Color primary800 = Color(0xFF174A86);
  static const Color primary900 = Color(0xFF0F325E);

  // Aliases for component compatibility
  static const Color primary = primary500;

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ==========================================
  // Secondary & Dynamic Accents
  // ==========================================

  // ==========================================
  // Neutral Palette (Backgrounds, Surfaces, Borders)
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas (#F8FAFC)
  static const Color surface = Color(0xFFFFFFFF); // Surface / Card white
  static const Color surfaceLight = Color(0xFFF1F5F9); // Muted input background
  static const Color border = Color(0xFFE4EAF2); // Global border
  static const Color divider = Color(0xFFEEF2F6); // Soft divider
  static const Color shadow = Color(0xFF0F172A); // Card shadow base (#0F172A)
  static const Color shadowDark = Color(0xFF0B111E);

  // Soft Banner & Card Tints
  static const Color consultationBannerBgEnd = Color(0xFFDBEAFE);
  static const Color consultationBannerBorder = Color(0xFFBFDBFE);
  static const Color consultationBannerText = Color(0xFF1E3A8A);
  static const Color consultationBannerSubtext = Color(0xFF3B82F6);

  // Hero Card Accent Tokens
  static const Color heroDarkBgEnd = Color(0xFF1E3A8A);
  static const Color heroDarkBorder = Color(0xFF3B82F6);
  static const Color heroAccentBlue = Color(0xFF60A5FA);
  static const Color heroSubtextBlue = Color(0xFF93C5FD);
  static const Color emeraldTextLight = Color(0xFF34D399);

  // ==========================================
  // Typography Colors
  // ==========================================
  static const Color textPrimary = Color(
    0xFF172033,
  ); // High-contrast navy (#172033)
  static const Color textSecondary = Color(0xFF667085); // Slate (#667085)
  static const Color textMuted = Color(0xFF98A2B3); // Muted / Hint (#98A2B3)

  // ==========================================
  // Icon Colors
  // ==========================================

  // ==========================================
  // Status & Feedback Colors
  // ==========================================
  static const Color success = Color(0xFF10B981); // Emerald / Closed
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  // Brand Social Colors
  static const Color whatsapp = Color(0xFF25D366);
  static const Color whatsappDark = Color(0xFF1EBE5D);
  static const Color facebook = Color(0xFF1877F2);
  static const Color facebookDark = Color(0xFF0056C6);
  static const Color facebookLightBg = Color(0xFFF2F7FE);
  static const Color facebookLightBorder = Color(0xFFD6E4FF);
  static const Color instagram = Color(0xFFE1306C);
  static const Color instagramStart = Color(0xFF833AB4);
  static const Color instagramMiddle = Color(0xFFFD1D1D);
  static const Color instagramEnd = Color(0xFFFCB045);
  static const Color instagramAlt = Color(0xFFE4405F);
  static const Color instagramLightBg = Color(0xFFFDF2F7);
  static const Color instagramLightBorder = Color(0xFFFAD2E6);
  static const List<Color> instagramGradient = [
    Color(0xFFFCAF45),
    Color(0xFFC13584),
  ];

  // Demo Accent Palette (Card Highlights)
  static const Color accentCoral = Color(0xFFFF5252);
  static const Color accentCoralLight = Color(0xFFFFEBEE);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentGoldLight = Color(0xFFFFF8E1);
  static const Color accentTeal = Color(0xFF00BFA5);
  static const Color accentTealLight = Color(0xFFE0F7F4);

  // Status & Tag Color Tokens
  static const Color statusSuccessText = Color(0xFF059669);
  static const Color statusSuccessDarkText = Color(0xFF047857);
  static const Color statusWarningDarkText = Color(0xFF92400E);
  static const Color tagTeal = Color(0xFF0D9488);
  static const Color tagIndigo = Color(0xFF6366F1);

  // Dark Canvas & Chat Neutrals
  static const Color darkCanvas = Color(0xFF1E1E1E);
  static const Color darkCanvasLight = Color(0xFFD4D4D4);
  static const Color textDarkSlate = Color(0xFF374151);
  static const Color textDarkGray = Color(0xFF1F2937);

  // Poster Template Theme Tokens
  static const Color posterGoldLight = Color(0xFFFEF3C7);
  static const Color posterGoldBrown = Color(0xFF78350F);
  static const Color posterBlueSoft = Color(0xFF4A76A8);
  static const Color posterIndigoSoft = Color(0xFF5C6BC0);
  static const Color posterBurgundy = Color(0xFF991B1B);
  static const Color posterRoseRed = Color(0xFF881337);
  static const Color posterNeutralLight = Color(0xFFF5F5F5);
  static const Color posterNeutralDark = Color(0xFF212121);

  // ==========================================
  // Dark Mode Surface & Text Tokens
  // ==========================================
  static const Color darkBackground = Color(0xFF0B111E); // Deep Navy Canvas
  static const Color darkSurface = Color(0xFF131D31); // Level 1 Surface
  static const Color darkSurfaceElevated = Color(0xFF1C2A44); // Level 2 Surface
  static const Color darkBorder = Color(0xFF233554);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ==========================================
  // Shimmer & Utility Colors
  // ==========================================
  static const Color shimmerBase = Color(0xFFE2E8F0);

  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);

  // ==========================================
  // Gradients & Setup Tile Tokens
  // ==========================================
  static const List<Color> primaryGradient = [primary500, primary700];
  static const List<Color> nexusGradient = [primary400, primary500, primary800];
  static const List<Color> secondaryGradient = [primary800, primary900];
  static const List<Color> popularCardGradient = [
    Color(0xFF0B1A3B),
    Color(0xFF132D5E),
    Color(0xFF1A3F7A),
  ];
  static const List<Color> glassGradient = [
    Color(0x33FFFFFF),
    Color(0x0FFFFFFF),
  ];

  static const Color setupTileSuccessBg = Color(0xFFF0FDF4);
  static const Color setupTileSuccessBorder = Color(0xFFBBF7D0);

  static const List<Color> gradientEmerald = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];
  static const List<Color> gradientCyan = [
    Color(0xFF06B6D4),
    Color(0xFF0891B2),
  ];
  static const List<Color> gradientFacebook = [
    Color(0xFF1877F2),
    Color(0xFF0055FF),
  ];
  static const List<Color> gradientInstagramTile = [
    Color(0xFFE1306C),
    Color(0xFFF58529),
  ];
  static const List<Color> gradientAmber = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];
  static const List<Color> gradientIndigo = [
    Color(0xFF6366F1),
    Color(0xFF4F46E5),
  ];
}
