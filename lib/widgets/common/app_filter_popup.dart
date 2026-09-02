// File: lib/widgets/common/app_filter_popup.dart
// Purpose: Reusable popover dropdown filter button using Overlay portals to avoid standard dialogues.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../util/common_ext.dart';
import '../buttons/app_button.dart';

class AppFilterButton extends StatefulWidget {
  final Widget child;
  final String title;
  final double width;
  final VoidCallback? onClear;
  final VoidCallback? onApply;

  const AppFilterButton({
    super.key,
    required this.child,
    required this.title,
    this.width = 320.0,
    this.onClear,
    this.onApply,
  });

  @override
  State<AppFilterButton> createState() => _AppFilterButtonState();
}

class _AppFilterButtonState extends State<AppFilterButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _togglePopup() {
    if (_isOpen) {
      _closePopup();
    } else {
      _openPopup();
    }
  }

  void _openPopup() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closePopup() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _isOpen = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppFilterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _closePopup();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        if (!mounted) return const SizedBox.shrink();

        final renderBox = this.context.findRenderObject() as RenderBox;
        final buttonSize = renderBox.size;
        final buttonPosition = renderBox.localToGlobal(Offset.zero);
        final screenWidth = context.width;
        const padding = 16.0;

        // Dynamic responsive width: clamp to fit screen width on narrow devices
        final popoverWidth = widget.width.clamp(0.0, screenWidth - (padding * 2));

        // Desired global left coordinate (default to right-align with the button)
        double popoverLeft = (buttonPosition.dx + buttonSize.width) - popoverWidth;

        // Ensure left edge doesn't go off-screen
        if (popoverLeft < padding) {
          popoverLeft = padding;
        }

        // Ensure right edge doesn't go off-screen
        if (popoverLeft + popoverWidth > screenWidth - padding) {
          popoverLeft = screenWidth - padding - popoverWidth;
        }

        // dx offset relative to the target anchor (button's left coordinate)
        final double dx = popoverLeft - buttonPosition.dx;

        return Stack(
          children: [
            // Dismiss barrier on outside click
            GestureDetector(
              onTap: _closePopup,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),

            // Positioned follower right below the anchor
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(dx, buttonSize.height + 6.0),
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: popoverWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24.0,
                          offset: const Offset(0, 8.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header: Label & Close Icon
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.title,
                                style: AppTextStyles.heading3.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 15.0,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20.0),
                                color: AppColors.textSecondary,
                                onPressed: _closePopup,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8.0),
                                splashRadius: 20.0,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),

                        // Body: Custom children widgets
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                          child: widget.child,
                        ),

                        // Bottom actions bar
                        if (widget.onClear != null || widget.onApply != null) ...[
                          const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
                            child: Row(
                              children: [
                                if (widget.onClear != null)
                                  Expanded(
                                    child: AppButton.outline(
                                      text: context.tr('clear_all'),
                                      height: 42.0,
                                      borderRadius: 10.0,
                                      borderColor: AppColors.border,
                                      textColor: AppColors.textPrimary,
                                      onPressed: () {
                                        widget.onClear!();
                                        _closePopup();
                                      },
                                    ),
                                  ),
                                if (widget.onClear != null && widget.onApply != null)
                                  const SizedBox(width: 8.0),
                                if (widget.onApply != null)
                                  Expanded(
                                    child: AppButton.solid(
                                      text: context.tr('apply'),
                                      height: 42.0,
                                      borderRadius: 10.0,
                                      color: AppColors.primary,
                                      onPressed: () {
                                        if (widget.onApply != null) {
                                          widget.onApply!();
                                        }
                                        _closePopup();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 42.0,
        width: isMobile ? 42.0 : null,
        decoration: BoxDecoration(
          color: _isOpen ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: _isOpen ? AppColors.primary : AppColors.border, width: 1.0),
        ),
        child: InkWell(
          onTap: _togglePopup,
          borderRadius: BorderRadius.circular(10.0),
          child: isMobile
              ? Center(
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: _isOpen ? AppColors.primary : AppColors.textSecondary,
                    size: 20.0,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: _isOpen ? AppColors.primary : AppColors.textSecondary,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Filter',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isOpen ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
