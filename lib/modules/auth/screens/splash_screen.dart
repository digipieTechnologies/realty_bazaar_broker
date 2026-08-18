// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_assets.dart';
import '../../../app/app_strings.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../core/localization/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Logo and text fade-in animation (1.2 seconds)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start fade animation immediately
    _fadeController.forward();

    // 2. Route check after 2.5 seconds total
    Timer(const Duration(milliseconds: 2500), _checkSessionAndRoute);
  }

  void _checkSessionAndRoute() {
    if (!mounted) return;

    final userId = GetStorage().read<String>('user_id');
    if (userId != null && userId.isNotEmpty) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Slate 900: Premium deep backdrop
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Static Building Banner aligned to bottom
            Positioned.fill(
              child: Opacity(
                opacity: 0.25, // Subtle backdrop style
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppAssets.building),
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Branding Content (Logo + App Name)
            FadeTransition(
              opacity: _logoFadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glass logo container
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
                        width: 1.5,
                      ),
                    ),
                    child: const AppLogo(
                      size: 64.0,
                      backgroundColor: Colors.transparent,
                      iconColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    context.tr('real_estate_growth_platform'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
