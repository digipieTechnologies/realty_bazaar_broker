// File: lib/modules/legal/screens/privacy_policy_screen.dart
// Purpose: Public and in-app responsive Privacy Policy screen compliant with Store policies.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';
import 'package:the_realty_bazaar/widgets/brand/app_logo.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

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
                constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
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
                        title: '1. Introduction & Overview',
                        content:
                            'The Realty Bazaar Broker ("we", "our", or "us") respects your privacy and is committed to protecting the personal data of our real estate brokers, agents, and platform users. This Privacy Policy explains what information we collect, how we use it, how it is safeguarded, and your data deletion rights under Google Play Store and Apple App Store policies.',
                      ),

                      _buildSection(
                        title: '2. Information We Collect',
                        content:
                            '• Account Information: Name, email address, phone number, business/brokerage name, business address, and profile photo.\n'
                            '• Property & Listing Data: Real estate listings, pricing, dimensions, location coordinates, uploaded property photos, and videos.\n'
                            '• Social Media Integrations: When you connect your Facebook Page or Instagram Business accounts, we store OAuth tokens to post property listings and sync inquiries on your behalf.\n'
                            '• Device & Usage Data: IP address, device identifiers, diagnostic crash logs, and interaction data via telemetry tools.',
                      ),

                      _buildSection(
                        title: '3. Device Permissions & Usage',
                        content:
                            '• Camera & Photo Library: Used solely to allow you to capture or upload property media, floorplans, and profile pictures.\n'
                            '• Notifications: Used to send lead alerts, video request updates, and direct chat messages.',
                      ),

                      _buildSection(
                        title: '4. Third-Party Services & Integrations',
                        content:
                            'We integrate with trusted service providers to run our operations:\n'
                            '• Supabase: Secure cloud authentication and database hosting.\n'
                            '• Meta Graph API (Facebook & Instagram): Publishing property posts and synchronizing prospective leads.\n'
                            '• Cloudflare R2 / AWS: Encrypted storage for property photos and video assets.',
                      ),

                      _buildSection(
                        title: '5. Data Retention & Account Deletion',
                        content:
                            'You have the right to request deletion of your account and personal data at any time.\n'
                            '• In-app deletion is available directly from your Profile > Account Actions.\n'
                            '• A public deletion request form is available at any time via our Account Deletion page.\n'
                            '• Upon request, personal identifiers and credentials are immediately deactivated. Operational data is purged in accordance with our 30-day retention schedule.',
                      ),

                      _buildSection(
                        title: '6. Contact Support',
                        content:
                            'If you have questions or inquiries regarding your data privacy, please contact our Data Protection Team at:\n'
                            'Email: support@therealtybazaar.com\n'
                            'Website: https://therealtybazaar.com',
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
