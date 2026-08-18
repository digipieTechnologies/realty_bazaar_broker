// File: lib/modules/properties/services/post_content_service.dart
// Purpose: Single-responsibility service for generating all social post content
//          (topHeader, instagramHandle, location, bottomContact, caption) via the
//          generate-post-content edge function with a local fallback.

import 'package:brokerhive/models/property_enums.dart';
import 'package:flutter/foundation.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/property_model.dart';
import '../../../providers/social/social_provider.dart';

/// Result object returned from content generation.
/// All fields are plain strings; callers may use them to pre-fill controllers.
class PostContentResult {
  final String topHeader;
  final String instagramHandle;
  final String location;
  final String bottomContact;
  final String caption;
  final String brokerPhone;
  final String brokerName;

  const PostContentResult({
    required this.topHeader,
    required this.instagramHandle,
    required this.location,
    required this.bottomContact,
    required this.caption,
    required this.brokerPhone,
    required this.brokerName,
  });
}

class PostContentService {
  PostContentService._();

  /// Generates post content by calling the `generate-post-content` edge function.
  /// Falls back to local generation if the API call fails.
  static Future<PostContentResult> generate({
    required PropertyModel? property,
    required SocialProvider socialProvider,
    required String? localBrokerPhone,
    required String? localBrokerName,
  }) async {
    final prop = property;

    // ── Try edge function ────────────────────────────────────────────────────
    if (prop?.id != null && prop!.id!.isNotEmpty) {
      try {
        final response = await SupabaseConfig.client.functions.invoke(
          'generate-post-content',
          body: {
            'propertyId': prop.id,
            'brokerId': prop.brokerId,
            'instagramUsername':
                socialProvider.instagramAccount?.instagramUsername,
            'facebookPageName': socialProvider.facebookAccount?.pageName,
          },
        );

        if (response.status == 200 && response.data is Map) {
          final data = response.data as Map;
          final topHeader = (data['topHeader'] ?? '').toString();
          final handle = (data['instagramHandle'] ?? '').toString();
          final location = (data['location'] ?? '').toString();
          final bottomContact = (data['bottomContact'] ?? '').toString();
          final caption = (data['caption'] ?? '').toString();
          final brokerPhone =
              (data['brokerPhone'] ?? localBrokerPhone ?? '').toString();
          final brokerName =
              (data['brokerName'] ?? localBrokerName ?? '').toString();

          if (topHeader.isNotEmpty && caption.isNotEmpty) {
            return PostContentResult(
              topHeader: topHeader,
              instagramHandle: handle,
              location: location,
              bottomContact: bottomContact,
              caption: caption,
              brokerPhone: brokerPhone,
              brokerName: brokerName,
            );
          }
        }
      } catch (e) {
        debugPrint('[PostContentService] Edge function failed: $e');
      }
    }

    // ── Local fallback ───────────────────────────────────────────────────────
    return _buildLocalResult(property, socialProvider, localBrokerPhone, localBrokerName);
  }

  static PostContentResult _buildLocalResult(
    PropertyModel? prop,
    SocialProvider socialProvider,
    String? localBrokerPhone,
    String? localBrokerName,
  ) {
    final phone = localBrokerPhone ?? '';
    final name = localBrokerName ?? '';

    if (prop == null) {
      return PostContentResult(
        topHeader: 'LUXURY PROPERTY FOR SALE / PRIME LOCATION',
        instagramHandle: _buildHandle(socialProvider),
        location: 'PRIME LOCATION',
        bottomContact: _buildContact(name, phone),
        caption: _buildFallbackCaption(null, phone),
        brokerPhone: phone,
        brokerName: name,
      );
    }

    final bhk = prop.bedrooms > 0 ? '${prop.bedrooms} BHK ' : '';
    final pType = prop.propertyType.displayName.toUpperCase();
    final lType = prop.listingType.displayName.toUpperCase();
    final addr = prop.address;
    // AddressModel has: city, landmark, fullAddress
    final locality = addr?.landmark ?? addr?.city ?? '';
    final city = addr?.city ?? '';
    final areaStr = prop.area > 0
        ? '${prop.area.toStringAsFixed(0)} ${prop.areaUnit.displayName.toUpperCase()}'
        : '';
    final furnish = prop.furnishingStatus.displayName.toUpperCase();

    final headerParts = [
      '$bhk$pType FOR $lType IN ${city.toUpperCase()}',
      if (areaStr.isNotEmpty) areaStr,
      if (furnish.isNotEmpty && furnish != 'UNFURNISHED') furnish,
    ];
    final topHeader = headerParts.join(' / ');

    final locationText = (locality.isNotEmpty ? locality : city).toUpperCase();

    return PostContentResult(
      topHeader: topHeader,
      instagramHandle: _buildHandle(socialProvider),
      location: locationText.isNotEmpty ? locationText : 'PRIME LOCATION',
      bottomContact: _buildContact(name, phone),
      caption: _buildFallbackCaption(prop, phone),
      brokerPhone: phone,
      brokerName: name,
    );
  }

  static String _buildHandle(SocialProvider sp) {
    final ig = sp.instagramAccount?.instagramUsername;
    final fb = sp.facebookAccount?.pageName;
    if (ig != null && ig.isNotEmpty) return 'IG - @${ig.toUpperCase()}';
    if (fb != null && fb.isNotEmpty) return 'FB - ${fb.toUpperCase()}';
    return 'BROKERHIVE';
  }

  static String _buildContact(String name, String phone) {
    if (name.isNotEmpty && phone.isNotEmpty) {
      return '${name.toUpperCase()} - $phone';
    }
    if (phone.isNotEmpty) return 'CALL / WHATSAPP: $phone';
    return 'CONTACT BROKER FOR SITE VISIT';
  }

  static String _buildFallbackCaption(PropertyModel? prop, String phone) {
    final contactLine = phone.isNotEmpty
        ? '📞 Call / WhatsApp: $phone'
        : '📞 DM for site visit!';

    if (prop == null) {
      return '✨ Luxury Property Available\n📍 Prime Location\n$contactLine\n#RealEstate #DreamHome #PropertyForSale';
    }

    final city = prop.address?.city ?? '';
    final price = prop.price;
    final priceStr = price >= 10000000
        ? '₹${(price / 10000000).toStringAsFixed(2)} Cr'
        : price >= 100000
            ? '₹${(price / 100000).toStringAsFixed(2)} Lakh'
            : '';

    return '✨ ${prop.propertyTitle}'
        '${city.isNotEmpty ? '\n📍 $city' : ''}'
        '${priceStr.isNotEmpty ? ' | $priceStr' : ''}'
        '\n$contactLine'
        '\n#RealEstate #${city.replaceAll(' ', '')}Property #DreamHome';
  }
}
