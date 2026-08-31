import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/common/app_tag_chip.dart';

class TargetingSuggestionsWidget extends StatefulWidget {
  final List<String> suggestions;
  final ValueChanged<List<String>> onSuggestionsChanged;

  const TargetingSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionsChanged,
  });

  @override
  State<TargetingSuggestionsWidget> createState() => _TargetingSuggestionsWidgetState();
}

class _TargetingSuggestionsWidgetState extends State<TargetingSuggestionsWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSuggestion() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!widget.suggestions.contains(text)) {
      final updated = List<String>.from(widget.suggestions)..add(text);
      widget.onSuggestionsChanged(updated);
    }
    _controller.clear();
  }

  void _removeSuggestion(String tag) {
    final updated = List<String>.from(widget.suggestions)..remove(tag);
    widget.onSuggestionsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              context.tr('targeting_suggestions'),
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              '(${context.tr('optional')})',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          context.tr('targeting_suggestions_desc'),
          style: AppTextStyles.caption.copyWith(fontSize: 12.0, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12.0),

        // Input Field Box (without "Add" text button)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _addSuggestion(),
            style: AppTextStyles.body2.copyWith(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: context.tr('targeting_suggestions_placeholder'),
              hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textMuted, fontSize: 13.0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
          ),
        ),

        // Display Added Chips below (using AppTagChip)
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: widget.suggestions.map((tag) {
              return AppTagChip(label: tag, onDelete: () => _removeSuggestion(tag));
            }).toList(),
          ),
        ],
      ],
    );
  }
}
