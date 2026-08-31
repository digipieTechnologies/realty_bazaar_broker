// File: lib/widgets/icons/call_icon_widget.dart
// Purpose: Modular reusable Call SVG icon widget using newly downloaded vector asset.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_assets.dart';
import '../../app/app_colors.dart';

class CallIconWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const CallIconWidget({super.key, this.size = 20.0, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return SvgPicture.asset(
      AppAssets.icCall,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      fit: BoxFit.contain,
    );
  }
}
