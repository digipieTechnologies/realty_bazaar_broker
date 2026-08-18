// File: lib/widgets/icons/whatsapp_icon_widget.dart
// Purpose: Modular reusable WhatsApp brand image icon widget.

import 'package:flutter/material.dart';

class WhatsappIconWidget extends StatelessWidget {
  final double size;

  const WhatsappIconWidget({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/whatsapp.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
