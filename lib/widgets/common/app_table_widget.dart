import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import 'app_card_container.dart';

/// Centralized themed container for all tables in the application.
/// Changing styles here will automatically update all tables across the app.
class AppTableContainer extends StatelessWidget {
  final Widget child;

  const AppTableContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      borderRadius: 16.0,
      child: child,
    );
  }
}

/// Column configuration metadata used by AppTableHeaderRow.
class AppTableColumnDef {
  final String title;
  final int flex;
  final Alignment alignment;

  const AppTableColumnDef({
    required this.title,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

/// Themed header row for desktop table layout.
class AppTableHeaderRow extends StatelessWidget {
  final List<AppTableColumnDef> columns;
  final double endSpacing;

  const AppTableHeaderRow({
    super.key,
    required this.columns,
    this.endSpacing = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Align(
                alignment: col.alignment,
                child: Text(
                  col.title.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                    fontSize: 11.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (endSpacing > 0) SizedBox(width: endSpacing),
        ],
      ),
    );
  }
}

/// Reusable table search textfield widget for header bars.
class AppTableSearchField extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final String hintText;

  const AppTableSearchField({
    super.key,
    this.onSearchChanged,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18.0,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
