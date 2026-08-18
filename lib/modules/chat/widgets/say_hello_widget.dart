// File: lib/modules/chat/widgets/say_hello_widget.dart
// Purpose: Centered placeholder widget shown in empty chat rooms prompting users to say hello.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class SayHelloWidget extends StatelessWidget {
  final VoidCallback onSayHello;

  const SayHelloWidget({
    super.key,
    required this.onSayHello,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 44.0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No messages yet',
            style: AppTextStyles.heading3.copyWith(fontSize: 16.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Start the conversation by sending a message below!',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18.0),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 16.0),
            label: const Text('Say Hello 👋'),
            onPressed: onSayHello,
          ),
        ],
      ),
    );
  }
}
