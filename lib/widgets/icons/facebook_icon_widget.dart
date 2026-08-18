// File: lib/widgets/icons/facebook_icon_widget.dart
// Purpose: Modular reusable Facebook brand image icon widget.

import 'package:flutter/material.dart';

class FacebookIconWidget extends StatelessWidget {
  final double size;

  const FacebookIconWidget({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/facebook.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
