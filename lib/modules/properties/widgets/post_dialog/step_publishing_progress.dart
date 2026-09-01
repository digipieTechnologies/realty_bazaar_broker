// File: lib/modules/properties/widgets/post_dialog/step_publishing_progress.dart
// Purpose: Step 3 UI for publishing progress bar and status indicator while posting to social channels.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../providers/social/social_provider.dart';

class StepPublishingProgress extends StatelessWidget {
  final SocialProvider socialProvider;

  const StepPublishingProgress({super.key, required this.socialProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48.0,
              height: 48.0,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Publishing Property Listing',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            const SizedBox(height: 6.0),
            Text(
              socialProvider.publishingStep.isNotEmpty
                  ? socialProvider.publishingStep
                  : 'Uploading media and creating post on selected platforms...',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: 240.0,
              child: LinearProgressIndicator(
                value: socialProvider.publishingProgress > 0 ? socialProvider.publishingProgress : null,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(10.0),
                minHeight: 5.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
