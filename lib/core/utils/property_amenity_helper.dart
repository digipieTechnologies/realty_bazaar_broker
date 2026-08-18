// File: lib/core/utils/property_amenity_helper.dart
// Purpose: Centralized repository helper for property amenities, providing icons and predefined lists.

import 'package:flutter/material.dart';

class PropertyAmenityHelper {
  static const Map<String, IconData> amenityIcons = {
    'Swimming Pool': Icons.pool_rounded,
    'Gym / Fitness': Icons.fitness_center_rounded,
    'Gymnasium': Icons.fitness_center_rounded,
    '24/7 Security': Icons.shield_rounded,
    'Private Garden': Icons.park_rounded,
    'Power Backup': Icons.bolt_rounded,
    'Elevator / Lift': Icons.elevator_rounded,
    'Clubhouse': Icons.deck_rounded,
    'EV Charging': Icons.ev_station_rounded,
    'Wi-Fi': Icons.wifi_rounded,
    'Spa / Sauna': Icons.hot_tub_rounded,
    'Mountain View': Icons.landscape_rounded,
    'Kids Play Area': Icons.child_care_rounded,
  };

  static IconData getIcon(String amenity) {
    return amenityIcons[amenity] ?? Icons.check_circle_rounded;
  }

  static const List<String> availableAmenityNames = [
    'Swimming Pool',
    'Gym / Fitness',
    '24/7 Security',
    'Private Garden',
    'Power Backup',
    'Elevator / Lift',
    'Clubhouse',
    'EV Charging',
    'Wi-Fi',
    'Spa / Sauna',
    'Mountain View',
    'Kids Play Area',
  ];
}
