// File: lib/widgets/inputs/age_range_slider_widget.dart
// Purpose: Modern reusable Age Range slider component displaying selected range values.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';

import 'full_width_range_slider_track_shape.dart';

class AgeRangeSliderWidget extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final double min;
  final double max;

  const AgeRangeSliderWidget({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 18.0,
    this.max = 65.0,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = values.start.round().toString();
    final endStr = values.end.round().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('age_range'),
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                '$startStr - $endStr',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeTrackShape: const FullWidthRangeSliderTrackShape(),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4.0,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 9.0,
              elevation: 3,
            ),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            labels: RangeLabels(startStr, endStr),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
