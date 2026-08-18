// File: lib/modules/dashboard/screens/reports_tab_screen.dart
// Purpose: Screen containing the reports directory tab page.

import 'package:flutter/material.dart';
import '../widgets/base_tab_screen.dart';

class ReportsTabScreen extends StatelessWidget {
  const ReportsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseTabScreen(
      title: 'Performance Reports',
      description:
          'Real-time market analytics, conversion rates, and revenue generation tracking.',
      icon: Icons.bar_chart_rounded,
    );
  }
}
