// File: lib/modules/dashboard/screens/referrals_tab_screen.dart
// Purpose: Screen containing the Referral network tab page.

import 'package:flutter/material.dart';
import '../widgets/base_tab_screen.dart';

class ReferralsTabScreen extends StatelessWidget {
  const ReferralsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseTabScreen(
      title: 'Referrals Network',
      description:
          'Track commission shares, agent handoffs, and affiliate link generation.',
      icon: Icons.share_outlined,
    );
  }
}
