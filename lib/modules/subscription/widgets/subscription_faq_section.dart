// File: lib/modules/subscription/widgets/subscription_faq_section.dart
// Purpose: Expandable FAQ accordion section for SubscriptionPackageDetailScreen.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class FaqItemData {
  final String question;
  final String answer;

  const FaqItemData({required this.question, required this.answer});
}

class SubscriptionFaqSection extends StatelessWidget {
  final List<FaqItemData> faqs;

  const SubscriptionFaqSection({super.key, this.faqs = const []});

  static List<FaqItemData> getDefaultFaqs() {
    return const [
      FaqItemData(
        question: 'What happens after I purchase a package?',
        answer:
            'Our dedicated marketing team will immediately contact you to review your property details, target location, and create custom ad designs for Meta & Google.',
      ),
      FaqItemData(
        question: 'Is Facebook & Instagram ad spend included in this price?',
        answer:
            'Yes! 80% of your total package fee goes directly towards Meta and Google ad spend. There are zero hidden fees.',
      ),
      FaqItemData(
        question: 'Where will my property ad be displayed?',
        answer:
            'Your ad will be showcased across Facebook Feed, Instagram Stories, Instagram Reels, and Meta Audience Network targeting active property buyers.',
      ),
      FaqItemData(
        question: 'How are leads delivered to me?',
        answer:
            'Leads are delivered instantly to your Realty Bazaar app dashboard and sent straight to your WhatsApp number via direct notification.',
      ),
      FaqItemData(
        question: 'When does the package duration start?',
        answer:
            'The duration countdown (7, 15, or 30 days) begins only AFTER your ad design is approved and goes live on Meta.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final list = faqs.isNotEmpty ? faqs : getDefaultFaqs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Frequently Asked Questions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 18.0,
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10.0),
          itemBuilder: (context, index) {
            final faq = list[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  childrenPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  title: Text(
                    faq.question,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14.0,
                    ),
                  ),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textMuted,
                  children: [
                    Text(
                      faq.answer,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13.0,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
