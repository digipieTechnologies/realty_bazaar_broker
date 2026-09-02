// File: lib/modules/legal/screens/privacy_policy_screen.dart
// Purpose: Public and in-app responsive Privacy Policy screen compliant with Store policies.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';
import 'package:the_realty_bazaar/core/localization/app_localizations.dart';
import 'package:the_realty_bazaar/util/common_ext.dart';
import 'package:the_realty_bazaar/widgets/brand/app_logo.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.initial);
            }
          },
        ),
        title: Text(context.tr('privacy_policy'), style: AppTextStyles.heading3.copyWith(fontSize: 18)),
        centerTitle: false,
        actions: [
          if (isDesktop) ...[
            TextButton(
              onPressed: () => AppNavigator.navigateToTermsOfService(context),
              child: Text(
                context.tr('terms_of_service'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => AppNavigator.navigateToDeleteAccount(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(
                context.tr('delete_account'),
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 36.0 : 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: context.screenWidth800),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 38),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('privacy_policy'), style: AppTextStyles.heading2),
                              Text(
                                context.tr('last_updated'),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: context.tr('pp_section_1_title'),
                        content: context.tr('pp_section_1_content'),
                      ),

                      _buildSection(
                        title: context.tr('pp_section_2_title'),
                        content: context.tr('pp_section_2_content'),
                      ),

                      _buildSection(
                        title: context.tr('pp_section_3_title'),
                        content: context.tr('pp_section_3_content'),
                      ),

                      _buildSection(
                        title: context.tr('pp_section_4_title'),
                        content: context.tr('pp_section_4_content'),
                      ),

                      _buildSection(
                        title: context.tr('pp_section_5_title'),
                        content: context.tr('pp_section_5_content'),
                      ),

                      _buildSection(
                        title: context.tr('pp_section_6_title'),
                        content: context.tr('pp_section_6_content'),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => AppNavigator.navigateToTermsOfService(context),
                            child: Text(context.tr('terms_of_service')),
                          ),
                          FilledButton(
                            onPressed: () => AppNavigator.navigateToDeleteAccount(context),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            child: Text(context.tr('delete_account')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}
