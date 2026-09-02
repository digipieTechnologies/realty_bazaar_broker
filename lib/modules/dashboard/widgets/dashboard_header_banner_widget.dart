// File: lib/modules/dashboard/widgets/dashboard_header_banner_widget.dart
// Purpose: Standalone welcome header banner widget with floating curved background art, category tag, and verified agency badge.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';

class DashboardHeaderBannerWidget extends StatefulWidget {
  const DashboardHeaderBannerWidget({super.key});

  @override
  State<DashboardHeaderBannerWidget> createState() => _DashboardHeaderBannerWidgetState();
}

class _DashboardHeaderBannerWidgetState extends State<DashboardHeaderBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final name = authProvider.userProfile?.name ?? authProvider.userProfile?.email?.split('@').first ?? 'Broker';

    final rawBusinessName = authProvider.userProfile?.brokerId?.businessName;
    final categoryTag =
        (rawBusinessName != null &&
            rawBusinessName.isNotEmpty &&
            !rawBusinessName.toLowerCase().contains(name.toLowerCase()))
        ? rawBusinessName.toUpperCase()
        : 'REAL ESTATE BROKER';

    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isMobile ? 12.0 : 20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary700, AppColors.primary500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: [
          BoxShadow(color: AppColors.primary500.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.0),
        child: Stack(
          children: [
            // Floating Micro-animated Background Shapes
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) {
                  final offset = _floatAnim.value;
                  return Stack(
                    children: [
                      Positioned(
                        right: -25 + offset,
                        top: -25 - offset,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 35 - offset * 0.7,
                        top: 15 + offset * 0.7,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentGold),
                        ),
                      ),
                      Positioned(
                        right: 85 + offset * 0.5,
                        bottom: -20 - offset * 0.5,
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentTeal.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Banner Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 14.0 : 22.0, vertical: isMobile ? 14.0 : 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Professional Account Category Pill Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 13.0),
                              const SizedBox(width: 4.0),
                              Text(
                                categoryTag,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: isMobile ? 10.0 : 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 6.0 : 10.0),
                        Text(
                          'Welcome back, $name!',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 17.0 : 20.0,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Here is your live real estate growth overview.',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: isMobile ? 12.0 : 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 10.0 : 16.0),
                  // Right Verified Agency Glassmorphism Icon Container
                  Container(
                    width: isMobile ? 44.0 : 56.0,
                    height: isMobile ? 44.0 : 56.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.verified_user_rounded, color: Colors.white, size: isMobile ? 22.0 : 28.0),
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
