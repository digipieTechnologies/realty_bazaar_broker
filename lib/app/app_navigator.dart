import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property_model.dart';
import '../models/social_lead_model.dart';
import '../models/social_post_model.dart';
import '../models/subscription_plan_model.dart';
import '../modules/auth/screens/delete_account_screen.dart';
import '../modules/dashboard/screens/ad_campaign_settings_screen.dart';
import '../modules/dashboard/screens/profile_screen.dart';
import '../modules/dashboard/screens/request_video_tab_screen.dart';
import '../modules/dashboard/screens/view_post_screen.dart';
import '../modules/leads/screens/view_lead_screen.dart';
import '../modules/visits/screens/view_visit_screen.dart';
import '../models/property_visit_model.dart';
import '../modules/legal/screens/privacy_policy_screen.dart';
import '../modules/legal/screens/terms_of_service_screen.dart';
import '../modules/properties/screens/view_property_screen.dart';
import '../modules/subscription/screens/active_plan_detail_screen.dart';
import '../modules/subscription/screens/subscription_package_detail_screen.dart';
import '../modules/subscription/screens/subscription_success_screen.dart';
import '../util/common_ext.dart';
import 'app_routes.dart';

class AppNavigator {
  AppNavigator._();

  /// Navigates to Property Details (URL deep link on Desktop, rootNavigator on Mobile)
  static void navigateToPropertyDetails(BuildContext context, PropertyModel property) {
    final identifier = property.propertyCode?.isNotEmpty == true ? property.propertyCode! : (property.id ?? '');
    if (context.isDesktop) {
      if (identifier.isNotEmpty) {
        context.go('/properties/$identifier', extra: property);
      } else {
        context.go('/properties');
      }
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => ViewPropertyScreen(property: property, propertyId: identifier),
        ),
      );
    }
  }

  /// Navigates to Lead Details (URL deep link on Desktop, rootNavigator on Mobile)
  static void navigateToLeadDetails(BuildContext context, SocialLeadModel lead) {
    final targetId = lead.id ?? '';
    if (context.isDesktop) {
      if (targetId.isNotEmpty) {
        context.go('/leads/$targetId', extra: lead);
      } else {
        context.go('/leads');
      }
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => ViewLeadScreen(lead: lead, leadId: targetId),
        ),
      );
    }
  }

  /// Navigates to Visit Details (URL deep link on Desktop, rootNavigator on Mobile)
  static void navigateToVisitDetails(BuildContext context, PropertyVisitModel visit) {
    final targetId = visit.id ?? '';
    if (context.isDesktop) {
      if (targetId.isNotEmpty) {
        context.go('/visits/$targetId', extra: visit);
      } else {
        context.go('/visits');
      }
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => ViewVisitScreen(visit: visit, visitId: targetId),
        ),
      );
    }
  }

  /// Navigates to Post Details (URL deep link on Desktop, rootNavigator on Mobile)
  static void navigateToPostDetails(BuildContext context, SocialPostModel post) {
    final targetId = post.id ?? post.postId ?? post.platformPostId ?? '';
    if (context.isDesktop) {
      if (targetId.isNotEmpty) {
        context.go('/posts/$targetId', extra: post);
      } else {
        context.go('/posts');
      }
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => ViewPostScreen(post: post, postId: targetId),
        ),
      );
    }
  }

  /// Navigates to Video Requests: switches tab on Desktop, or pushes via rootNavigator on Mobile.
  static void navigateToVideoRequests(BuildContext context) {
    if (context.isDesktop) {
      context.go('/request-video');
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const RequestVideoTabScreen()));
    }
  }

  /// Navigates to Ad Campaign Settings (URL deep link on Desktop, rootNavigator on Mobile)
  static void navigateToCampaignSettings(BuildContext context) {
    if (context.isDesktop) {
      context.push(AppRoutes.campaignSettings);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const AdCampaignSettingsScreen()));
    }
  }

  /// Navigates to Profile (Tab on Desktop, rootNavigator on Mobile)
  static void navigateToProfile(BuildContext context) {
    if (context.isDesktop) {
      context.go('/profile');
    } else {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  /// Navigates to Privacy Policy (URL link on Desktop, rootNavigator on Mobile)
  static void navigateToPrivacyPolicy(BuildContext context) {
    if (context.isDesktop) {
      AppNavigator.navigateToPrivacyPolicy(context);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
    }
  }

  /// Navigates to Terms of Service (URL link on Desktop, rootNavigator on Mobile)
  static void navigateToTermsOfService(BuildContext context) {
    if (context.isDesktop) {
      AppNavigator.navigateToTermsOfService(context);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()));
    }
  }

  /// Navigates to Delete Account (URL link on Desktop, rootNavigator on Mobile)
  static void navigateToDeleteAccount(BuildContext context) {
    if (context.isDesktop) {
      AppNavigator.navigateToDeleteAccount(context);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const DeleteAccountScreen()));
    }
  }

  /// Navigates to Subscription Package Detail full screen route (hides bottom nav bar)
  static void navigateToSubscriptionPackageDetail(BuildContext context, SubscriptionPlanModel plan) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (context) => SubscriptionPackageDetailScreen(initialPlan: plan)));
  }

  /// Navigates to Subscription Purchase Success full screen route
  static void navigateToSubscriptionSuccess(
    BuildContext context, {
    required String planName,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    required String paymentId,
    String durationTitle = '30 Days',
    List<String> benefits = const [],
  }) {
    if (context.isDesktop) {
      context.push(
        AppRoutes.subscriptionSuccess,
        extra: {
          'planName': planName,
          'amount': amount,
          'startDate': startDate,
          'endDate': endDate,
          'paymentId': paymentId,
          'durationTitle': durationTitle,
          'benefits': benefits,
        },
      );
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => SubscriptionSuccessScreen(
            planName: planName,
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            paymentId: paymentId,
            durationTitle: durationTitle,
            benefits: benefits,
          ),
        ),
      );
    }
  }

  /// Navigates to Subscription / Grow tab
  static void navigateToGrowTab(BuildContext context) {
    popAllAndGo(context, '/grow');
  }

  /// Pops all active rootNavigator overlays (modals/dialogs) and navigates cleanly to target path
  static void popAllAndGo(BuildContext context, String path) {
    try {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    } catch (_) {}
    AppRoutes.router.go(path);
  }

  /// Navigates to Home / Dashboard clearing all rootNavigator overlays
  static void navigateToHome(BuildContext context) {
    popAllAndGo(context, AppRoutes.home);
  }

  /// Navigates to Active Plan Detail full screen route
  static void navigateToActivePlanDetail(BuildContext context) {
    if (context.isDesktop) {
      context.push(AppRoutes.activePlanDetail);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute(builder: (context) => const ActivePlanDetailScreen()));
    }
  }
}
