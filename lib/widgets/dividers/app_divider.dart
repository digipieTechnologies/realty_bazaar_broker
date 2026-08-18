import 'package:flutter/material.dart';
import '../../app/app_colors.dart';

class AppDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final EdgeInsets? margin;

  const AppDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget divider = Divider(
      height: height,
      thickness: thickness,
      color: color ?? AppColors.border,
    );

    if (margin != null) {
      divider = Padding(padding: margin!, child: divider);
    }

    return divider;
  }
}
