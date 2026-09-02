// File: lib/widgets/common/app_pagination_widget.dart
// Purpose: Common pagination widget for list, grid, and table views with responsive ellipsis (...) pagination, standalone card styling, and hand cursor hover effects.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../util/common_ext.dart';

class AppPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final String itemLabel;
  final ValueChanged<int> onPageChanged;
  final bool isStandalone;

  const AppPaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.itemsPerPage = 10,
    this.itemLabel = 'items',
    required this.onPageChanged,
    this.isStandalone = false,
  });

  List<dynamic> _getPageNumbers(bool isMobile) {
    final maxVisible = isMobile ? 4 : 7;
    if (totalPages <= maxVisible) {
      return List.generate(totalPages, (i) => i + 1);
    }

    if (isMobile) {
      if (currentPage <= 2) {
        return [1, 2, '...', totalPages];
      } else if (currentPage >= totalPages - 1) {
        return [1, '...', totalPages - 1, totalPages];
      } else {
        return [1, '...', currentPage, '...', totalPages];
      }
    } else {
      if (currentPage <= 4) {
        return [1, 2, 3, 4, 5, '...', totalPages];
      } else if (currentPage >= totalPages - 3) {
        return [1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
      } else {
        return [1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startItem = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage) > totalItems ? totalItems : (currentPage * itemsPerPage);
    final isMobile = context.isMobileUI;

    final infoWidget = RichText(
      text: TextSpan(
        style: AppTextStyles.body2.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13.0,
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: 'Showing '),
          TextSpan(
            text: '$startItem–$endItem',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const TextSpan(text: ' of '),
          TextSpan(
            text: '$totalItems',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          TextSpan(text: ' $itemLabel'),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isStandalone ? 20.0 : 16.0,
        vertical: isStandalone ? 14.0 : 12.0,
      ),
      decoration: isStandalone
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2.0),
                ),
              ],
            )
          : const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
              ),
              border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
            ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoWidget,
                const SizedBox(height: 12.0),
                Align(alignment: Alignment.centerRight, child: _buildPageControls(isMobile)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [infoWidget, _buildPageControls(isMobile)],
            ),
    );
  }

  Widget _buildPageControls(bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _getPageNumbers(isMobile);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous Button
        _buildNavigationButton(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 3.0 : 6.0),

        // Page Numbers & Ellipses
        for (int i = 0; i < pages.length; i++) ...[
          if (pages[i] is int) ...[
            _buildPageNumberItem(
              page: pages[i] as int,
              isSelected: pages[i] == currentPage,
              isMobile: isMobile,
            ),
          ] else ...[
            _buildEllipsisItem(index: i, isMobile: isMobile),
          ],
        ],

        SizedBox(width: isMobile ? 3.0 : 6.0),

        // Next Button
        _buildNavigationButton(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    final size = isMobile ? 32.0 : 36.0;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8.0),
          hoverColor: AppColors.primary.withValues(alpha: 0.08),
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF8FAFC) : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: isMobile ? 18.0 : 20.0,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumberItem({required int page, required bool isSelected, required bool isMobile}) {
    final size = isMobile ? 30.0 : 34.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 1.5 : 2.5),
        child: Material(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.0),
          elevation: isSelected ? 1.0 : 0.0,
          shadowColor: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
          child: InkWell(
            onTap: () => onPageChanged(page),
            borderRadius: BorderRadius.circular(8.0),
            hoverColor: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.0),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  fontSize: isMobile ? 12.0 : 13.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsisItem({required int index, required bool isMobile}) {
    final width = isMobile ? 22.0 : 26.0;
    final height = isMobile ? 30.0 : 34.0;

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 1.0 : 2.0),
      alignment: Alignment.center,
      child: Text(
        '...',
        style: TextStyle(
          fontSize: isMobile ? 12.0 : 13.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
