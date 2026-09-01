// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';

class WaitingFeaturesSection extends StatelessWidget {
  const WaitingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final teasers = provider.serviceTeasers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('whats_waiting'),
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16.0),

        // Horizontal scrollable ListView of 4 cards
        SizedBox(
          height: 160.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: teasers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16.0),
            itemBuilder: (context, index) {
              final teaser = teasers[index];
              return SizedBox(width: 260.0, child: _buildTeaserCard(context, teaser));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeaserCard(BuildContext context, ServiceTeaser teaser) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: teaser.themeColor.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: teaser.themeColor.withOpacity(0.02), blurRadius: 10.0, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: teaser.themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(teaser.icon, color: teaser.themeColor, size: 20.0),
          ),
          const SizedBox(height: 16.0),

          // Title
          Text(
            context.tr('teaser_title_${teaser.title.toLowerCase().replaceAll(' ', '_')}'),
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6.0),

          // Description
          Expanded(
            child: Text(
              context.tr('teaser_desc_${teaser.title.toLowerCase().replaceAll(' ', '_')}'),
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
