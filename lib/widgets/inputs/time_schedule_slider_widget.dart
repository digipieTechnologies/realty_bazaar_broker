// File: lib/widgets/inputs/time_schedule_slider_widget.dart
// Purpose: Modern reusable 24-hour Time Schedule slider component with Whole Day checkbox toggle.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import 'app_checkbox_tile.dart';
import 'full_width_range_slider_track_shape.dart';

class TimeScheduleSliderWidget extends StatelessWidget {
  final RangeValues values;
  final bool isWholeDay;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<bool?> onWholeDayChanged;

  const TimeScheduleSliderWidget({
    super.key,
    required this.values,
    required this.isWholeDay,
    required this.onChanged,
    required this.onWholeDayChanged,
  });

  String _formatHour(double value) {
    final int hour = value.round();
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final startStr = _formatHour(values.start);
    final endStr = _formatHour(values.end);

    final displayTimeStr = isWholeDay
        ? context.tr('whole_day_range')
        : '$startStr - $endStr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('time_schedule'),
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isWholeDay
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                displayTimeStr,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isWholeDay ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Whole Day Checkbox
        AppCheckboxTile(
          value: isWholeDay,
          label: context.tr('whole_day'),
          onChanged: onWholeDayChanged,
        ),
        const SizedBox(height: 10.0),

        // Time Range Slider (Disabled when Whole Day is checked)
        Opacity(
          opacity: isWholeDay ? 0.4 : 1.0,
          child: AbsorbPointer(
            absorbing: isWholeDay,
            child: SliderTheme(
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
                values: isWholeDay ? const RangeValues(0, 24) : values,
                min: 0.0,
                max: 24.0,
                divisions: 24,
                labels: RangeLabels(startStr, endStr),
                onChanged: (newValues) {
                  // If user slides end-to-end (0 to 24), automatically mark as whole day
                  if (newValues.start == 0.0 && newValues.end == 24.0) {
                    onWholeDayChanged(true);
                  } else {
                    onChanged(newValues);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
