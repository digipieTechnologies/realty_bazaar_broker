// File: lib/modules/auth/screens/splash_screen.dart
// Purpose: Modern light-mode professional splash screen with direct clean branding layout on canvas.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_strings.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/brand/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (fade & scale up)
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));

    _entranceController.forward();

    // 2. Navigation Timer (2.5 seconds)
    Timer(const Duration(milliseconds: 2500), _checkSessionAndRoute);
  }

  void _checkSessionAndRoute() {
    if (!mounted) return;

    final storage = GetStorage();
    final userId = storage.read<String>('user_id');
    if (userId != null && userId.isNotEmpty) {
      final pendingUrl = storage.read<String>(AppRoutes.pendingRedirectKey);
      if (pendingUrl != null && pendingUrl.isNotEmpty && pendingUrl != '/' && pendingUrl != '/login') {
        storage.remove(AppRoutes.pendingRedirectKey);
        context.go(pendingUrl);
        return;
      }
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Soft Ambient Background Glow Circles
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary700.withValues(alpha: 0.05),
                ),
              ),
            ),

            // 2. Central Hero Branding (Direct on Canvas, No Container Box)
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo surrounded by soft glow circular container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 28.0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLogo(size: 84.0, backgroundColor: Colors.transparent),
                    ),
                    const SizedBox(height: 24.0),

                    // App Title (Direct Text)
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isMobile ? 30.0 : 36.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10.0),

                    // Subtitle / Platform Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14.0, color: AppColors.primary),
                          const SizedBox(width: 6.0),
                          Text(
                            context.tr('real_estate_growth_platform').toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Bottom Footer Security & Progress Indicator
            Positioned(
              bottom: isMobile ? 32.0 : 40.0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thin Indeterminate Progress Bar
                    SizedBox(
                      width: 140.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: const LinearProgressIndicator(
                          minHeight: 3.0,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 13.0, color: AppColors.textMuted),
                        const SizedBox(width: 4.0),
                        Text(
                          'Secured & Encrypted Broker Nexus',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
