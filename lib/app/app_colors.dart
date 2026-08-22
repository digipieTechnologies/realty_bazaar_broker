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
  static const Color primaryLight = primary100;
  static const Color primaryDark = primary700;

  // ==========================================
  // Secondary & Dynamic Accents
  // ==========================================
  static const Color secondary = Color(0xFF174A86); // Deep Nexus Blue
  static const Color secondaryLight = Color(0xFFEAF3FF);
  static const Color secondaryDark = Color(0xFF0F325E);

  // ==========================================
  // Neutral Palette (Backgrounds, Surfaces, Borders)
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas (#F8FAFC)
  static const Color surface = Color(0xFFFFFFFF); // Surface / Card white
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9); // Muted input background
  static const Color border = Color(0xFFE4EAF2); // Global border
  static const Color divider = Color(0xFFEEF2F6); // Soft divider

  // ==========================================
  // Typography Colors
  // ==========================================
  static const Color textPrimary = Color(0xFF172033); // High-contrast navy (#172033)
  static const Color textSecondary = Color(0xFF667085); // Slate (#667085)
  static const Color textMuted = Color(0xFF98A2B3); // Muted / Hint (#98A2B3)
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ==========================================
  // Icon Colors
  // ==========================================
  static const Color iconDefault = Color(0xFF667085);
  static const Color iconActive = Color(0xFF397BCF);

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
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color info = Color(0xFF397BCF); // Primary Blue
  static const Color infoLight = Color(0xFFEAF3FF);
  static const Color infoBorder = Color(0xFFD4E6FC);

  // Brand Social Colors
  static const Color whatsapp = Color(0xFF25D366);
  static const Color whatsappDark = Color(0xFF1EBE5D);
  static const Color facebook = Color(0xFF1877F2);
  static const Color facebookLightBg = Color(0xFFF2F7FE);
  static const Color facebookLightBorder = Color(0xFFD6E4FF);
  static const Color instagram = Color(0xFFE1306C);
  static const Color instagramAlt = Color(0xFFE4405F);
  static const Color instagramLightBg = Color(0xFFFDF2F7);
  static const Color instagramLightBorder = Color(0xFFFAD2E6);
  static const List<Color> instagramGradient = [Color(0xFFFCAF45), Color(0xFFC13584)];

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
  static const Color statusSuccessBgLight = Color(0xFFECFDF5);
  static const Color statusSuccessBorderLight = Color(0xFFA7F3D0);
  static const Color statusWarningText = Color(0xFFB45309);
  static const Color statusWarningDarkText = Color(0xFF92400E);
  static const Color statusWarningBgLight = Color(0xFFFFFBEB);
  static const Color statusWarningBorderLight = Color(0xFFFDE68A);
  static const Color tagAmber = Color(0xFFD97706);
  static const Color tagTeal = Color(0xFF0D9488);
  static const Color tagIndigo = Color(0xFF6366F1);

  // Dark Canvas & Chat Neutrals
  static const Color darkCanvas = Color(0xFF1E1E1E);
  static const Color darkCanvasLight = Color(0xFFD4D4D4);
  static const Color textDarkSlate = Color(0xFF374151);
  static const Color textDarkGray = Color(0xFF1F2937);

  // Poster Template Theme Tokens
  static const Color posterGold = Color(0xFFD97706);
  static const Color posterGoldDark = Color(0xFFB45309);
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
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ==========================================
  // Shimmer & Utility Colors
  // ==========================================
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);

  // ==========================================
  // Gradients
  // ==========================================
  static const List<Color> primaryGradient = [primary500, primary700];
  static const List<Color> nexusGradient = [primary400, primary500, primary800];
  static const List<Color> secondaryGradient = [secondary, secondaryDark];
  static const List<Color> glassGradient = [Color(0x33FFFFFF), Color(0x0FFFFFFF)];
}
