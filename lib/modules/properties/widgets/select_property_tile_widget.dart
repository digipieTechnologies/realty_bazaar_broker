// File: lib/modules/properties/widgets/select_property_tile_widget.dart
// Purpose: Minimal tile component for property candidates in the selection modal dialog.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../models/models.dart';

class SelectPropertyTileWidget extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectPropertyTileWidget({
    super.key,
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  String _formatLocation(AddressModel? address) {
    if (address == null) return 'Location not specified';
    if (address.fullAddress.trim().isNotEmpty) {
      return address.fullAddress.trim();
    }
    final parts = <String>[];
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    if (address.state != null && address.state!.isNotEmpty) {
      parts.add(address.state!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Location not specified';
  }

  @override
  Widget build(BuildContext context) {
    final priceStr = property.price > 0 ? property.price.toCompactCurrency() : '';
    final locationStr = _formatLocation(property.address);
    final bhkStr = property.bedrooms > 0 ? '${property.bedrooms} BHK' : '';
    final typeStr = property.propertyType.displayName.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Checkbox indicator
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22.0,
              ),
              const SizedBox(width: 12.0),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.propertyTitle,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14.0, color: AppColors.textSecondary),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            locationStr,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Badges row
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        if (priceStr.isNotEmpty)
                          _buildBadge(
                            priceStr,
                            AppColors.primary,
                            tooltip: property.price.toFullIndianCurrency(),
                          ),
                        if (bhkStr.isNotEmpty) _buildBadge(bhkStr, AppColors.primary800),
                        _buildBadge(typeStr, AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {String? tooltip}) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: color),
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, preferBelow: false, child: badge);
    }
    return badge;
  }
}
