// File: lib/widgets/inputs/app_dropdown.dart
// Purpose: Highly customized, reusable Dropdown selection input field matching the design system and AppTextField styling.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Widget? icon;
  final bool readOnly;

  const AppDropdown({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    this.icon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[Text(label!, style: AppTextStyles.label), const SizedBox(height: 6.0)],
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: readOnly ? null : onChanged,
          validator: validator,
          isExpanded: true,
          style: AppTextStyles.textField,
          icon: icon ?? const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: readOnly ? AppColors.surfaceLight : AppColors.surface,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
          ),
          items: items,
        ),
      ],
    );
  }
}
