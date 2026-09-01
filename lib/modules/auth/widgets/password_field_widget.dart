// File: lib/modules/auth/widgets/password_field_widget.dart
// Purpose: Dedicated password input wrapper built on AppTextField.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../widgets/inputs/app_textfield.dart';

class PasswordFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordFieldWidget({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint = '••••••••',
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
      validator: validator,
    );
  }
}
