// File: lib/widgets/common/app_3d_badge.dart
// Purpose: Reusable 3D colorful badge widget with glassmorphism effects and confetti.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/app_colors.dart';

class App3DBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color shadowDarkColor;
  final List<Color> innerGradientColors;
  final bool showConfetti;
  final double size;

  const App3DBadge({
    super.key,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.shadowDarkColor,
    required this.innerGradientColors,
    this.iconColor = Colors.white,
    this.showConfetti = true,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    // Scaling factors based on a base size of 150.0
    final double scale = size / 150.0;
    
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer Glow
          Container(
            width: 140.0 * scale,
            height: 140.0 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.2),
                  secondaryColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 2. Glass Ring
          Container(
            width: 115.0 * scale,
            height: 115.0 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowDarkColor.withValues(alpha: 0.18),
                  blurRadius: 24 * scale,
                  spreadRadius: 2 * scale,
                  offset: Offset(0, 8 * scale),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 8 * scale,
                  spreadRadius: -4 * scale,
                  offset: Offset(-3 * scale, -3 * scale),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.0 * scale),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(58.0 * scale),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Inner Sphere
          Container(
            width: 82.0 * scale,
            height: 82.0 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: innerGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowDarkColor.withValues(alpha: 0.3),
                  blurRadius: 12 * scale,
                  offset: Offset(0, 5 * scale),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 4 * scale,
                  offset: Offset(-2 * scale, -2 * scale),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Highlight
                Positioned(
                  top: 6 * scale,
                  left: 12 * scale,
                  child: Container(
                    width: 34.0 * scale,
                    height: 14.0 * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0 * scale),
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 42.0 * scale,
                  color: iconColor,
                ),
              ],
            ),
          ),

          // 4. Confetti
          if (showConfetti) ...[
            Positioned(
              top: 10 * scale,
              left: 16 * scale,
              child: _confetti(AppColors.pinkConfetti, 10 * scale, true),
            ),
            Positioned(
              top: 16 * scale,
              right: 18 * scale,
              child: Container(
                padding: EdgeInsets.all(3.0 * scale),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.warning.withValues(alpha: 0.4), blurRadius: 5 * scale),
                  ],
                ),
                child: Icon(Icons.star_rounded, size: 8.0 * scale, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 18 * scale,
              left: 14 * scale,
              child: Transform.rotate(
                angle: 0.785,
                child: _confetti(AppColors.cyanAccent, 9 * scale, false),
              ),
            ),
            Positioned(
              bottom: 14 * scale,
              right: 16 * scale,
              child: _confetti(AppColors.indigoConfetti, 8 * scale, true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confetti(Color color, double size, bool isCircle) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(2.0),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
