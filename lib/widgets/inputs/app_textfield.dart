// File: lib/widgets/inputs/app_textfield.dart
// Purpose: Form input field with password toggles, validation styling, and state preservation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool readOnly;
  final int? maxLength;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.onTap,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  void _toggleObscurity() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: 6.0),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscured,
          readOnly: widget.readOnly,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          onTap: widget.onTap,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          style: widget.readOnly
              ? AppTextStyles.textField.copyWith(color: AppColors.textMuted)
              : AppTextStyles.textField,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            filled: true,
            fillColor: widget.readOnly ? AppColors.surfaceLight : AppColors.surface,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            suffixIcon: widget.obscureText
                ? ExcludeFocusTraversal(
                    child: IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.iconDefault,
                      ),
                      onPressed: _toggleObscurity,
                    ),
                  )
                : widget.suffixIcon,
            counterText: '', // Hide default character counter to keep UI clean, can use custom if needed
          ),
        ),
      ],
    );
  }
}
