// File: lib/app/app_routes.dart
// Purpose: Routing table and GoRouter configuration with Navigator keys, deep linking, and return-url preservation.

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../core/services/clarity_service.dart';
import '../models/otp_type.dart';
import '../models/property_model.dart';
import '../models/social_lead_model.dart';
import '../models/social_post_model.dart';
import '../modules/auth/screens/delete_account_screen.dart';
import '../modules/auth/screens/login_screen.dart';
import '../modules/auth/screens/otp_verification_screen.dart';
import '../modules/auth/screens/reset_password_screen.dart';
import '../modules/auth/screens/splash_screen.dart';
import '../modules/dashboard/screens/ad_campaign_settings_screen.dart';
import '../modules/dashboard/screens/dashboard_tab_screen.dart';
import '../modules/dashboard/screens/grow_tab_screen.dart';
import '../modules/dashboard/screens/help_tab_screen.dart';
import '../modules/dashboard/screens/leads_tab_screen.dart';
import '../modules/dashboard/screens/posts_tab_screen.dart';
import '../modules/dashboard/screens/profile_screen.dart';
import '../modules/dashboard/screens/properties_tab_screen.dart';
import '../modules/dashboard/screens/referrals_tab_screen.dart';
import '../modules/dashboard/screens/reports_tab_screen.dart';
import '../modules/dashboard/screens/request_video_tab_screen.dart';
import '../modules/dashboard/screens/settings_tab_screen.dart';
import '../modules/dashboard/screens/shell_layout_screen.dart';
import '../modules/dashboard/screens/view_post_screen.dart';
import '../modules/leads/screens/view_lead_screen.dart';
import '../modules/visits/screens/visits_tab_screen.dart';
import '../modules/visits/screens/view_visit_screen.dart';
import '../models/property_visit_model.dart';
import '../modules/legal/screens/privacy_policy_screen.dart';
import '../modules/legal/screens/terms_of_service_screen.dart';
import '../modules/properties/screens/view_property_screen.dart';
import '../modules/subscription/screens/active_plan_detail_screen.dart';
import '../modules/subscription/screens/subscription_success_screen.dart';
import '../widgets/common/common_app_bar.dart';

class AppRoutes {
  AppRoutes._();

  // Storage key for preserving deep link URL across auth flows
  static const String pendingRedirectKey = 'pending_redirect_url';

  // Global Navigator Key for AppOverlay/Toasts access
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  // Route Paths
  static const String initial = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String deleteAccount = '/delete-account';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String home = '/dashboard';
  static const String details = '/details';
  static const String campaignSettings = '/campaign-settings';
  static const String subscriptionSuccess = '/subscription-success';
  static const String activePlanDetail = '/active-plan-detail';
  static const String propertyDetails = '/properties/:idOrCode';
  static const String leadDetails = '/leads/:id';
  static const String postDetails = '/posts/:id';
  static const String visits = '/visits';
  static const String visitDetails = '/visits/:id';

  // GoRouter Singleton Instance
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initial,
    debugLogDiagnostics: true,
    observers: [ClarityRouteObserver()],
    redirect: (context, state) {
      final storage = GetStorage();
      final userId = storage.read<String>('user_id');
      final isLoggedIn = userId != null && userId.isNotEmpty;

      final goingToAuth =
          state.matchedLocation == login ||
          state.matchedLocation == signUp ||
          state.matchedLocation == forgotPassword ||
          state.matchedLocation == verifyOtp ||
          state.matchedLocation == resetPassword;

      final goingToPublicLegal =
          state.matchedLocation == deleteAccount ||
          state.matchedLocation == privacyPolicy ||
          state.matchedLocation == termsOfService;

      final goingToSplash = state.matchedLocation == initial;

      final goingToLoginOrSignup =
          state.matchedLocation == login || state.matchedLocation == signUp || state.matchedLocation == forgotPassword;

      // 1. Unauthenticated user trying to access protected content
      if (!isLoggedIn && !goingToAuth && !goingToSplash && !goingToPublicLegal) {
        // Save the intended destination URL so user returns here after login
        final targetUri = state.uri.toString();
        if (targetUri.isNotEmpty && targetUri != '/' && targetUri != '/login') {
          storage.write(pendingRedirectKey, targetUri);
        }
        return login;
      }

      // 2. Authenticated user landing on login / signup screens
      if (isLoggedIn && goingToLoginOrSignup) {
        final pendingUrl = storage.read<String>(pendingRedirectKey);
        if (pendingUrl != null && pendingUrl.isNotEmpty && pendingUrl != '/login' && pendingUrl != '/') {
          storage.remove(pendingRedirectKey);
          return pendingUrl;
        }
        return home;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}', style: const TextStyle(color: Colors.red, fontSize: 16)),
      ),
    ),
    routes: [
      GoRoute(path: initial, name: 'splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(initialMode: AuthMode.login),
      ),
      GoRoute(
        path: signUp,
        name: 'signup',
        builder: (context, state) => const LoginScreen(initialMode: AuthMode.signup),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot_password',
        builder: (context, state) => const LoginScreen(initialMode: AuthMode.forgotPassword),
      ),
      GoRoute(path: deleteAccount, name: 'delete_account', builder: (context, state) => const DeleteAccountScreen()),
      GoRoute(path: privacyPolicy, name: 'privacy_policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(
        path: termsOfService,
        name: 'terms_of_service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: verifyOtp,
        name: 'verify_otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          final userId = extra?['userId'] as String?;
          final isPreSignup = extra?['isPreSignup'] as bool? ?? false;
          final otpType = extra?['otpType'] as AppOtpType? ?? AppOtpType.emailVerify;
          final signUpData = extra?['signUpData'] as Map<String, String>?;
          return OtpVerificationScreen(
            email: email,
            userId: userId,
            isPreSignup: isPreSignup,
            otpType: otpType,
            signUpData: signUpData,
          );
        },
      ),
      GoRoute(
        path: resetPassword,
        name: 'reset_password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),

      // Legacy route fallback redirect
      GoRoute(path: '/home', redirect: (context, state) => '/dashboard'),

      // Shell Route wrapping the 8 responsive dashboard screens
      ShellRoute(
        builder: (context, state, child) {
          return ShellLayoutScreen(child: child);
        },
        routes: [
          GoRoute(path: '/dashboard', name: 'dashboard', builder: (context, state) => const DashboardTabScreen()),
          GoRoute(
            path: '/leads',
            name: 'leads',
            builder: (context, state) => const LeadsTabScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: ':id',
                name: 'lead_details',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  final leadExtra = state.extra is SocialLeadModel ? state.extra as SocialLeadModel : null;
                  return ViewLeadScreen(lead: leadExtra, leadId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/visits',
            name: 'visits',
            builder: (context, state) => const VisitsTabScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: ':id',
                name: 'visit_details',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  final visitExtra = state.extra is PropertyVisitModel ? state.extra as PropertyVisitModel : null;
                  return ViewVisitScreen(visit: visitExtra, visitId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/posts',
            name: 'posts',
            builder: (context, state) => const PostsTabScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: ':id',
                name: 'post_details',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  final postExtra = state.extra is SocialPostModel ? state.extra as SocialPostModel : null;
                  return ViewPostScreen(post: postExtra, postId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/properties',
            name: 'properties',
            builder: (context, state) => const PropertiesTabScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: ':idOrCode',
                name: 'property_details',
                builder: (context, state) {
                  final idOrCode = state.pathParameters['idOrCode'];
                  final propertyExtra = state.extra is PropertyModel ? state.extra as PropertyModel : null;
                  return ViewPropertyScreen(property: propertyExtra, propertyId: idOrCode);
                },
              ),
            ],
          ),
          GoRoute(path: '/grow', name: 'grow', builder: (context, state) => const GrowTabScreen()),
          GoRoute(
            path: '/request-video',
            name: 'request_video',
            builder: (context, state) => const RequestVideoTabScreen(),
          ),
          GoRoute(path: '/referrals', name: 'referrals', builder: (context, state) => const ReferralsTabScreen()),
          GoRoute(path: '/reports', name: 'reports', builder: (context, state) => const ReportsTabScreen()),
          GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsTabScreen()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/help', name: 'help', builder: (context, state) => const HelpTabScreen()),
        ],
      ),

      GoRoute(
        path: campaignSettings,
        name: 'campaign_settings',
        builder: (context, state) => const AdCampaignSettingsScreen(),
      ),
      GoRoute(
        path: subscriptionSuccess,
        name: 'subscription_success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final rawBenefits = extra?['benefits'];
          List<String> benefitsList = [];
          if (rawBenefits is List) {
            benefitsList = rawBenefits.map((e) => e.toString()).toList();
          }
          return SubscriptionSuccessScreen(
            planName: extra?['planName'] as String? ?? 'Activated Subscription',
            amount: (extra?['amount'] as num?)?.toDouble() ?? 0.0,
            startDate: extra?['startDate'] as DateTime? ?? DateTime.now(),
            endDate: extra?['endDate'] as DateTime? ?? DateTime.now().add(const Duration(days: 30)),
            paymentId: extra?['paymentId'] as String? ?? '',
            durationTitle: extra?['durationTitle'] as String? ?? '30 Days',
            benefits: benefitsList,
          );
        },
      ),
      GoRoute(
        path: activePlanDetail,
        name: 'active_plan_detail',
        builder: (context, state) => const ActivePlanDetailScreen(),
      ),
      GoRoute(
        path: details,
        name: 'details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final title = extra?['title'] as String? ?? 'Details';
          return Scaffold(
            appBar: CommonAppBar(title: title),
            body: Center(child: Text('Placeholder details screen for $title', style: const TextStyle(fontSize: 16))),
          );
        },
      ),
    ],
  );
}
