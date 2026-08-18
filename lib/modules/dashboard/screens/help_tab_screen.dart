// File: lib/modules/dashboard/screens/help_tab_screen.dart
// Purpose: Screen containing the help & support tab page.

import 'package:flutter/material.dart';
import '../widgets/base_tab_screen.dart';

class HelpTabScreen extends StatelessWidget {
  const HelpTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseTabScreen(
      title: 'Help & Support',
      description:
          'Visit our online documentation or contact help desk support at tech-support@brokerhive.com.',
      icon: Icons.help_outline_rounded,
    );
  }
}
