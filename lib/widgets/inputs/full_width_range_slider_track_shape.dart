// File: lib/widgets/inputs/full_width_range_slider_track_shape.dart
// Purpose: Custom RangeSliderTrackShape that extends the slider track to the full edge of the parent container without side padding.

import 'package:flutter/material.dart';

class FullWidthRangeSliderTrackShape extends RangeSliderTrackShape {
  const FullWidthRangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor ?? Colors.blue;
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    // Background full track (inactive)
    context.canvas.drawRRect(RRect.fromRectAndRadius(trackRect, trackRadius), inactivePaint);

    // Active track segment
    final Rect activeRect = Rect.fromLTRB(
      startThumbCenter.dx.clamp(trackRect.left, trackRect.right),
      trackRect.top,
      endThumbCenter.dx.clamp(trackRect.left, trackRect.right),
      trackRect.bottom,
    );

    if (activeRect.width > 0) {
      context.canvas.drawRRect(RRect.fromRectAndRadius(activeRect, trackRadius), activePaint);
    }
  }
}
