// File: lib/widgets/shimmer/chat_shimmer_widget.dart
// Purpose: Standalone reusable shimmer loading placeholder for chat dialogs and screens.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class ChatShimmerWidget extends StatefulWidget {
  final bool showHeader;

  const ChatShimmerWidget({super.key, this.showHeader = false});

  @override
  State<ChatShimmerWidget> createState() => _ChatShimmerWidgetState();
}

class _ChatShimmerWidgetState extends State<ChatShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Column(
          children: [
            // Shimmer Header (Only if requested)
            if (widget.showHeader) ...[
              Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14.0,
                          width: 140.0,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBase.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Container(
                          height: 10.0,
                          width: 90.0,
                          decoration: BoxDecoration(
                            color: AppColors.shimmerBase.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Divider(height: 1.0, color: AppColors.border),
              const SizedBox(height: 16.0),
            ],

            // Shimmer Chat Bubbles
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final isRight = index % 2 == 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        height: 48.0,
                        width: (140 + (index * 25)).toDouble().clamp(120.0, 240.0),
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBase.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
