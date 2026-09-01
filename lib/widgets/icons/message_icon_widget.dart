// File: lib/widgets/icons/message_icon_widget.dart
// Purpose: Modular reusable Message/SMS SVG icon widget using newly downloaded vector asset.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_assets.dart';
import '../../app/app_colors.dart';

class MessageIconWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const MessageIconWidget({super.key, this.size = 20.0, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.info;
    return SvgPicture.asset(
      AppAssets.icMessage,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      fit: BoxFit.contain,
    );
  }
}
