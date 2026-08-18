// File: lib/modules/dashboard/widgets/recent_properties_widget.dart
// Purpose: Dashboard widget displaying top 3 recent properties in a horizontal scrolling list using PropertyCardWidget with mobile card layout and shimmer loading.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/shimmer/property_list_horizontal_shimmer_widget.dart';
import '../../properties/widgets/property_card_widget.dart';

class RecentPropertiesWidget extends StatefulWidget {
  const RecentPropertiesWidget({super.key});

  @override
  State<RecentPropertiesWidget> createState() => _RecentPropertiesWidgetState();
}

class _RecentPropertiesWidgetState extends State<RecentPropertiesWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id;
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);

      if (brokerId != null && brokerId.isNotEmpty) {
        propertyProvider.fetchProperties(brokerId: brokerId, page: 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = context.watch<PropertyProvider>();
    final properties = propertyProvider.properties.take(3).toList();
    final isLoading = propertyProvider.isLoading && propertyProvider.properties.isEmpty;

    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section Header Badge & View All Button
          AppSectionHeader(
            title: context.tr('properties'),
            icon: Icons.apartment_rounded,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
            trailing: InkWell(
              onTap: () => context.go('/properties'),
              borderRadius: BorderRadius.circular(6.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 3.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1.0, color: AppColors.border),

          // Content Area: Loading, Empty, or Horizontal Property List
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: PropertyListHorizontalShimmerWidget(count: 3),
            )
          else if (properties.isEmpty)
            AppEmptyStateWidget(
              icon: Icons.apartment_rounded,
              title: context.tr('no_properties_listed_yet'),
              description: context.tr('no_properties_empty_desc'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: properties.map((property) {
                      return SizedBox(
                        width: 260.0,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: PropertyCardWidget(
                            property: property,
                            isMinimalView: true,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
