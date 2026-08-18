// File: lib/modules/chat/widgets/message_type/location_message_widget.dart
// Purpose: WhatsApp style Location sharing message bubble component with map background thumbnail, pin, location name, and Google Maps URL launcher.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../util/app_utils.dart';

import '../../../../widgets/toast/app_toast.dart';

class LocationMessageWidget extends StatelessWidget {
  final String locationText;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? locationData;
  final bool isMe;

  const LocationMessageWidget({
    super.key,
    required this.locationText,
    this.latitude,
    this.longitude,
    this.locationData,
    required this.isMe,
  });

  Future<void> _openGoogleMaps() async {
    final double? lat = latitude ?? locationData?['latitude'] ?? locationData?['lat'];
    final double? lng = longitude ?? locationData?['longitude'] ?? locationData?['lng'];

    if (lat == null || lng == null) {
      AppToast.showError('Location Error', 'Invalid location coordinates.');
      return;
    }

    final urlString = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    await AppUtils.launchAppUrl(urlString);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = (locationText.isNotEmpty && locationText != 'Shared Location' && locationText != 'Current Location')
        ? locationText
        : (locationData?['address'] ?? locationData?['name'] ?? 'Location');

    return GestureDetector(
      onTap: _openGoogleMaps,
      child: Container(
        width: 220.0,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Map Background with Pin
            SizedBox(
              height: 120.0,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/map_placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.map_rounded, size: 40.0, color: AppColors.textMuted),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.error,
                        size: 24.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Location Label Bar with Chevron
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18.0,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
