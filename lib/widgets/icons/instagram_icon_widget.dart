// File: lib/widgets/icons/instagram_icon_widget.dart
// Purpose: Modular reusable Instagram brand image icon widget.

import 'package:flutter/material.dart';

class InstagramIconWidget extends StatelessWidget {
  final double size;

  const InstagramIconWidget({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/instagram.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
