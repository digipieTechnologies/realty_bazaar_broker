import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/inputs/app_textfield.dart';
import 'field_info_dialog.dart';

class StepPropertyLocationWidget extends StatelessWidget {
  final TextEditingController fullAddressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController pincodeController;
  final TextEditingController landmarkController;

  const StepPropertyLocationWidget({
    super.key,
    required this.fullAddressController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.pincodeController,
    required this.landmarkController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with Info Icon
        Row(
          children: [
            Text(
              context.tr('section_location_details'),
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8.0),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  FieldInfoDialog.show(
                    context,
                    title: context.tr('section_location_details'),
                    description: context.tr('location_subtitle'),
                    examples: const [
                      'Street Address: 521, Royal Empress, Near Dumas Beach Road',
                      'City: Surat, State: Gujarat',
                      'Landmark: Opposite Model Town Circle',
                    ],
                    tip: 'Including a recognizable landmark increases buyer viewing inquiries by 35%.',
                  );
                },
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          context.tr('location_subtitle'),
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24.0),

        // Full Address Line Input
        AppTextField(
          controller: fullAddressController,
          label: '${context.tr('street_address_label')} *',
          hint: context.tr('street_address_hint'),
          maxLines: 1,
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
        const SizedBox(height: 16.0),

        // Landmark Input
        AppTextField(
          controller: landmarkController,
          label: context.tr('landmark'),
          hint: context.tr('landmark_hint'),
          prefixIcon: const Icon(Icons.near_me_outlined),
        ),
        const SizedBox(height: 16.0),

        // City & State Inputs
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: cityController,
                label: '${context.tr('city')} *',
                hint: context.tr('city_hint'),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: AppTextField(
                controller: stateController,
                label: '${context.tr('state')} *',
                hint: context.tr('state_hint'),
                prefixIcon: const Icon(Icons.map_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Pincode & Country Inputs
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: pincodeController,
                label: context.tr('pincode'),
                hint: context.tr('pincode_hint'),
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.pin_drop_outlined),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: AppTextField(
                controller: countryController,
                label: '${context.tr('country')} *',
                hint: context.tr('country_hint'),
                prefixIcon: const Icon(Icons.public_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
