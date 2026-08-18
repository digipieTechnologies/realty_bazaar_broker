// File: lib/modules/chat/widgets/message_type/text_message_widget.dart
// Purpose: Text message bubble component supporting multiline text.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';

class TextMessageWidget extends StatelessWidget {
  final String text;
  final bool isMe;

  const TextMessageWidget({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body1.copyWith(
        fontSize: 13.5,
        color: isMe ? Colors.white : AppColors.textPrimary,
        height: 1.35,
      ),
    );
  }
}
