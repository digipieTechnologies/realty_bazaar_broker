// File: lib/app/app_colors.dart
// Purpose: Design system color tokens.
//
// RULE: Absolutely NO hardcoded hex codes (Color(0xFF...)) should ever appear
// outside this file. All features must reference these centralized constants.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette (Indigo based for professional modern trust)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700

  // Secondary Palette (Teal based for accents & dynamic highlights)
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color secondaryLight = Color(0xFFF0FDFA); // Teal 50
  static const Color secondaryDark = Color(0xFF0F766E); // Teal 700

  // Neutral Palette (Backgrounds, Surfaces, Borders)
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Slate 50 (App background)
  static const Color surface = Color(
    0xFFFFFFFF,
  ); // White (Card/Container background)
  static const Color surfaceLight = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200 (Common borders)
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // Text Colors
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Slate 900 (Headings, titles)
  static const Color textSecondary = Color(
    0xFF475569,
  ); // Slate 600 (Subtitles, body text)
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Slate 400 (Captions, placeholder text)

  // Icon Colors
  static const Color iconDefault = Color(
    0xFF475569,
  ); // Slate 600 (Crisp form field & action icons)

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEF2F2); // Red 50

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 50

  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFEFF6FF); // Blue 50

  // Shimmer Effects
  static const Color shimmerBase = Color(0xFFE2E8F0); // Slate 200
  static const Color shimmerHighlight = Color(0xFFF1F5F9); // Slate 100

  // Gradients
  static const List<Color> primaryGradient = [
    primary,
    Color(0xFF4F46E5), // Indigo 600
  ];

  static const List<Color> secondaryGradient = [secondary, Color(0xFF0D9488)];

  static const List<Color> glassGradient = [
    Color(0x33FFFFFF),
    Color(0x0FFFFFFF),
  ];
}
