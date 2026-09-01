import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class SearchFilterHeaderWidget extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearPressed;
  final Widget? trailingAction;

  const SearchFilterHeaderWidget({
    super.key,
    this.controller,
    this.hintText = 'Search by title, location, type...',
    this.onSearchChanged,
    this.onClearPressed,
    this.trailingAction,
  });

  @override
  State<SearchFilterHeaderWidget> createState() => _SearchFilterHeaderWidgetState();
}

class _SearchFilterHeaderWidgetState extends State<SearchFilterHeaderWidget> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search TextField Container
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 46.0,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _isFocused ? AppColors.primary : AppColors.border,
                width: _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: _isFocused ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _isFocused ? AppColors.primary : AppColors.textSecondary,
                  size: 20.0,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onSearchChanged,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                      filled: false,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.controller != null && widget.controller!.text.isNotEmpty)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller!.clear();
                        if (widget.onClearPressed != null) {
                          widget.onClearPressed!();
                        } else if (widget.onSearchChanged != null) {
                          widget.onSearchChanged!('');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Icon(Icons.cancel_rounded, color: AppColors.textSecondary, size: 18.0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (widget.trailingAction != null) ...[const SizedBox(width: 12.0), widget.trailingAction!],
      ],
    );
  }
}
