// File: lib/modules/dashboard/widgets/setup_progress_circular_indicator_widget.dart
// Purpose: Modular reusable circular progress ring widget displaying live percentage integer and animated loader ring.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';

class SetupProgressCircularIndicatorWidget extends StatelessWidget {
  final double percentage;
  final double size;
  final double? strokeWidth;
  final TextStyle? textStyle;

  const SetupProgressCircularIndicatorWidget({
    super.key,
    required this.percentage,
    this.size = 42.0,
    this.strokeWidth,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final int percentInt = (percentage * 100).toInt();
    final double computedStrokeWidth = strokeWidth ?? (size * 0.1).clamp(2.5, 4.5);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: computedStrokeWidth,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$percentInt%',
                style: textStyle ??
                    TextStyle(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
