// File: lib/modules/legal/screens/terms_of_service_screen.dart
// Purpose: Public and in-app responsive Terms of Service screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/brand/app_logo.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.initial);
            }
          },
        ),
        title: Text(context.tr('terms_of_service'), style: AppTextStyles.heading3.copyWith(fontSize: 18)),
        centerTitle: false,
        actions: [
          if (isDesktop) ...[
            TextButton(
              onPressed: () => context.push(AppRoutes.privacyPolicy),
              child: Text(
                context.tr('privacy_policy'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push(AppRoutes.deleteAccount),
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
                constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
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
                              Text(context.tr('terms_of_service'), style: AppTextStyles.heading2),
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
                        title: '1. Agreement to Terms',
                        content:
                            'By accessing or using The Realty Bazaar Broker mobile application or web portal, you agree to be bound by these Terms of Service. If you do not agree, please do not use our services.',
                      ),

                      _buildSection(
                        title: '2. Broker Accounts & Responsibilities',
                        content:
                            '• You must provide accurate, current, and complete information during registration.\n'
                            '• You are responsible for safeguarding your login credentials and for all activities that occur under your account.\n'
                            '• You represent that you are a licensed or authorized real estate professional or broker compliant with local regulations.',
                      ),

                      _buildSection(
                        title: '3. Property Listings & Content Accuracy',
                        content:
                            '• You retain ownership of property descriptions, photos, and materials you upload.\n'
                            '• You warrant that all property details, pricing, and availability uploaded to the platform are accurate and truthful.\n'
                            '• We reserve the right to remove listings that violate laws, copyright, or platform safety rules.',
                      ),

                      _buildSection(
                        title: '4. Social Media Integrations & Publishing',
                        content:
                            '• When publishing listings to Meta (Facebook/Instagram), you grant us permission to act via your authorized page token.\n'
                            '• You are responsible for adhering to Meta Platform policies regarding real estate advertising and community standards.',
                      ),

                      _buildSection(
                        title: '5. Account Termination & Deletion',
                        content:
                            '• You may terminate your account at any time via the Delete Account option in the app or via our public deletion form.\n'
                            '• We reserve the right to suspend or terminate accounts that engage in fraudulent behavior, abuse, or policy violations.',
                      ),

                      _buildSection(
                        title: '6. Limitation of Liability',
                        content:
                            'The Realty Bazaar is provided "as is" without warranty of any kind. We are not liable for direct, indirect, incidental, or consequential damages resulting from your use of the platform or property transactions between parties.',
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => context.push(AppRoutes.privacyPolicy),
                            child: Text(context.tr('privacy_policy')),
                          ),
                          FilledButton(
                            onPressed: () => context.push(AppRoutes.deleteAccount),
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
