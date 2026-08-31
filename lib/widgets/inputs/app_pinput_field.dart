// File: lib/widgets/inputs/app_pinput_field.dart
// Purpose: Reusable Pinput OTP field component styled with the The Realty Bazaar design tokens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppPinputField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool enabled;

  const AppPinputField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48.0,
      height: 56.0,
      textStyle: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.primary.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.primary, width: 2.0),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      length: length,
      autofocus: autofocus,
      enabled: enabled,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      errorPinTheme: errorPinTheme,
      onCompleted: onCompleted,
      onChanged: onChanged,
      validator: validator,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      cursor: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(margin: const EdgeInsets.only(bottom: 9), width: 18, height: 2, color: AppColors.primary),
        ],
      ),
    );
  }
}
