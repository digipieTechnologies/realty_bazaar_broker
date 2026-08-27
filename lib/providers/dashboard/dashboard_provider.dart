import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/broker_setup_details_model.dart';

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String svgAssetPath;
  final List<Color> gradientColors;
  final bool isCompleted;
  final String routePath;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.svgAssetPath,
    required this.gradientColors,
    required this.isCompleted,
    required this.routePath,
  });
}

class QuickActionItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isLocked;
  final String routePath;

  const QuickActionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.isLocked,
    required this.routePath,
  });
}

class LearningItem {
  final String title;
  final String routePath;

  const LearningItem({required this.title, required this.routePath});
}

class AdvancedFeature {
  final String title;
  final IconData icon;

  const AdvancedFeature({required this.title, required this.icon});
}

class ServiceTeaser {
  final String title;
  final String description;
  final IconData icon;
  final Color themeColor;

  const ServiceTeaser({
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
  });
}

class DashboardSummaryModel {
  final int todaysLeads;
  final String todaysLeadsGrowth;
  final int totalLeads;
  final int totalProperties;
  final int videoRequests;

  const DashboardSummaryModel({
    this.todaysLeads = 0,
    this.todaysLeadsGrowth = '+0%',
    this.totalLeads = 0,
    this.totalProperties = 0,
    this.videoRequests = 0,
  });

  factory DashboardSummaryModel.fromJson(dynamic json) {
    if (json is! Map) {
      return const DashboardSummaryModel();
    }
    return DashboardSummaryModel(
      todaysLeads: (json['todays_leads'] as num?)?.toInt() ?? 0,
      todaysLeadsGrowth: json['todays_leads_growth']?.toString() ?? '+0%',
      totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
      totalProperties: (json['total_properties'] as num?)?.toInt() ?? 0,
      videoRequests: (json['video_requests'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardProvider extends ChangeNotifier {
  DashboardSummaryModel? _summary;
  bool _isLoadingSummary = false;

  DashboardSummaryModel? get summary => _summary;
  bool get isLoadingSummary => _isLoadingSummary;

  void clear() {
    _summary = null;
    _isLoadingSummary = false;
    notifyListeners();
  }

  Future<void> fetchDashboardSummary(String brokerId) async {
    _isLoadingSummary = true;
    notifyListeners();
    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_dashboard_summary',
        params: {'p_broker_id': brokerId},
      );
      if (response != null && response is Map) {
        _summary = DashboardSummaryModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
    } catch (e) {
      debugPrint('[DashboardProvider] Error fetching summary RPC: $e');
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  // Completion calculation based on setupDetails
  double getCompletionPercentage({BrokerSetupDetailsModel? setupDetails}) {
    final steps = getOnboardingSteps(setupDetails: setupDetails);
    final completedCount = steps.where((s) => s.isCompleted).length;
    return completedCount / steps.length;
  }

  // List of onboarding steps mapped directly from BrokerSetupDetailsModel
  List<OnboardingStep> getOnboardingSteps({
    BrokerSetupDetailsModel? setupDetails,
  }) {
    final details = setupDetails ?? const BrokerSetupDetailsModel();

    return [
      OnboardingStep(
        id: 'account_created',
        title: 'Account Created',
        description: 'Broker profile and security credentials verified',
        svgAssetPath: 'assets/icons/ic_profile_filled.svg',
        gradientColors: AppColors.gradientEmerald,
        isCompleted: details.accountCreated,
        routePath: '/profile',
      ),
      OnboardingStep(
        id: 'business_info',
        title: 'Business Info Added',
        description: 'Brokerage details, address & office contacts set up',
        svgAssetPath: 'assets/icons/ic_business_center_filled.svg',
        gradientColors: AppColors.gradientCyan,
        isCompleted: details.businessInfoAdded,
        routePath: '/profile',
      ),
      OnboardingStep(
        id: 'connect_facebook',
        title: 'Connect Facebook',
        description: 'Sync Facebook Page to capture ad leads automatically',
        svgAssetPath: 'assets/icons/ic_facebook_filled.svg',
        gradientColors: AppColors.gradientFacebook,
        isCompleted: details.facebookConnected,
        routePath: '/dashboard',
      ),
      OnboardingStep(
        id: 'connect_instagram',
        title: 'Connect Instagram',
        description: 'Manage DMs & story inquiries in unified inbox',
        svgAssetPath: 'assets/icons/ic_instagram_filled.svg',
        gradientColors: AppColors.gradientInstagramTile,
        isCompleted: details.instagramConnected,
        routePath: '/dashboard',
      ),
      OnboardingStep(
        id: 'import_properties',
        title: 'Import Properties',
        description: 'Upload & publish property listings to marketplace',
        svgAssetPath: 'assets/icons/ic_properties_filled.svg',
        gradientColors: AppColors.gradientAmber,
        isCompleted: details.propertiesImported,
        routePath: '/properties',
      ),
      OnboardingStep(
        id: 'invite_team',
        title: 'Invite Team',
        description: 'Add co-brokers, agents & team members to workspace',
        svgAssetPath: 'assets/icons/ic_leads_filled.svg',
        gradientColors: AppColors.gradientIndigo,
        isCompleted: details.teamInvited,
        routePath: '',
      ),
    ];
  }

  // List of Quick Actions (dynamic lock state)
  List<QuickActionItem> getQuickActions(
    bool isFacebookConnected,
    bool isInstagramConnected,
  ) => [
    const QuickActionItem(
      id: 'profile',
      title: 'Profile',
      icon: Icons.account_circle_outlined,
      isLocked: false,
      routePath: '/profile',
    ),
    QuickActionItem(
      id: 'edit_business',
      title: 'Edit Business',
      icon: Icons.business_outlined,
      isLocked: !isFacebookConnected,
      routePath: '/settings',
    ),
    QuickActionItem(
      id: 'import_properties',
      title: 'Import Properties',
      icon: Icons.cloud_download_outlined,
      isLocked: !isFacebookConnected,
      routePath: '/properties',
    ),
    QuickActionItem(
      id: 'invite_team',
      title: 'Invite Team',
      icon: Icons.group_add_outlined,
      isLocked: !isInstagramConnected,
      routePath: '/settings',
    ),
    QuickActionItem(
      id: 'branding',
      title: 'Branding',
      icon: Icons.palette_outlined,
      isLocked: !isFacebookConnected,
      routePath: '/settings',
    ),
    QuickActionItem(
      id: 'alerts',
      title: 'Alerts',
      icon: Icons.notifications_active_outlined,
      isLocked: !isInstagramConnected,
      routePath: '/settings',
    ),
  ];

  // Learning Center
  List<LearningItem> get learningItems => [
    const LearningItem(
      title: 'How FB Connection Works',
      routePath: '/help/fb-connection',
    ),
    const LearningItem(
      title: 'Instagram Sync Guide',
      routePath: '/help/ig-sync',
    ),
    const LearningItem(
      title: 'Data Privacy Policy',
      routePath: '/privacy-policy',
    ),
    const LearningItem(title: 'Frequently Asked Questions', routePath: '/faq'),
  ];

  // Advanced features
  List<AdvancedFeature> get advancedFeatures => [
    const AdvancedFeature(
      title: 'Automatic Lead Capture',
      icon: Icons.person_add_alt_1_outlined,
    ),
    const AdvancedFeature(
      title: 'Real-time Notifications',
      icon: Icons.notifications_none_outlined,
    ),
    const AdvancedFeature(
      title: 'Analytics Dashboard',
      icon: Icons.analytics_outlined,
    ),
    const AdvancedFeature(
      title: 'Manage Everything',
      icon: Icons.grid_view_outlined,
    ),
    const AdvancedFeature(title: 'CRM Integration', icon: Icons.share_outlined),
    const AdvancedFeature(
      title: 'Time Saving Tools',
      icon: Icons.hourglass_empty_outlined,
    ),
  ];

  // Services "What's waiting for you"
  List<ServiceTeaser> get serviceTeasers => [
    const ServiceTeaser(
      title: 'Lead Inbox',
      description:
          'A unified view for every person interested in your properties.',
      icon: Icons.mail_outline_rounded,
      themeColor: Colors.blue,
    ),
    const ServiceTeaser(
      title: 'Social Inbox',
      description:
          'Manage comments and messages from all platforms in one place.',
      icon: Icons.chat_bubble_outline_rounded,
      themeColor: Colors.purple,
    ),
    const ServiceTeaser(
      title: 'Marketing Analytics',
      description: 'See which ads and organic posts are driving the most ROI.',
      icon: Icons.trending_up_rounded,
      themeColor: Colors.green,
    ),
    const ServiceTeaser(
      title: 'Property Performance',
      description: 'Track views and inquiries for each individual listing.',
      icon: Icons.apartment_rounded,
      themeColor: Colors.orange,
    ),
  ];
}
