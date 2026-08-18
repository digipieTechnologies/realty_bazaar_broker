// File: lib/modules/properties/widgets/property_location_card.dart
// Purpose: Reusable location card widget shared across property preview and view dialogs.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/address_model.dart';

class PropertyLocationCard extends StatelessWidget {
  final AddressModel? address;

  const PropertyLocationCard({
    super.key,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    if (address == null) return const SizedBox.shrink();

    final fullAddr = address!.fullAddress.trim();
    final landmark = address!.landmark?.trim();

    final parts = <String>[];
    if (address!.city != null && address!.city!.trim().isNotEmpty) {
      parts.add(address!.city!.trim());
    }
    if (address!.state != null && address!.state!.trim().isNotEmpty) {
      parts.add(address!.state!.trim());
    }
    if (address!.country != null && address!.country!.trim().isNotEmpty) {
      parts.add(address!.country!.trim());
    }
    final baseAddr = parts.join(', ');
    final cityStatePincodeStr = (address!.pincode != null && address!.pincode!.trim().isNotEmpty)
        ? (baseAddr.isNotEmpty ? '$baseAddr - ${address!.pincode}' : address!.pincode!)
        : baseAddr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.error,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fullAddr.isNotEmpty)
                  Text(
                    fullAddr,
                    style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                  ),
                if (landmark != null && landmark.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    'Landmark: $landmark',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (cityStatePincodeStr.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    cityStatePincodeStr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
