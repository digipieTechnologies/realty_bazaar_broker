// File: lib/modules/dashboard/screens/settings_tab_screen.dart
// Purpose: Screen containing the system settings tab page.

import 'package:flutter/material.dart';
import '../widgets/base_tab_screen.dart';

class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseTabScreen(
      title: 'System Settings',
      description:
          'Configure notifications, billing details, API integrations, and developer options.',
      icon: Icons.settings_outlined,
    );
  }
}
