// File: lib/modules/dashboard/screens/dashboard_tab_screen.dart
// Purpose: Primary Dashboard screen featuring Welcome header, Recent Leads section, and vertical Meta (Facebook/Instagram) connection cards.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/permission_service.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/social/social_provider.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/shimmer/social_connect_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/dashboard_summary_widget.dart';
import '../widgets/recent_leads_widget.dart';
import '../widgets/recent_posts_widget.dart';
import '../widgets/recent_properties_widget.dart';
import '../widgets/social_connect_card.dart';

class DashboardTabScreen extends StatefulWidget {
  const DashboardTabScreen({super.key});

  @override
  State<DashboardTabScreen> createState() => _DashboardTabScreenState();
}

class _DashboardTabScreenState extends State<DashboardTabScreen>
    with WidgetsBindingObserver {
  String? _subscribedBrokerId;
  SocialProvider? _socialProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestNotificationPermissionDirectly();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_subscribedBrokerId != null && _socialProvider != null) {
        debugPrint(
          '[DashboardTabScreen] App resumed from background. Silent refresh social connections...',
        );
        _socialProvider!.fetchInitialConnections(
          _subscribedBrokerId!,
          forceShimmer: false,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final brokerId = authProvider.userProfile?.brokerId?.id;
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      if (brokerId != null && brokerId != _subscribedBrokerId) {
        _subscribedBrokerId = brokerId;
        _socialProvider = Provider.of<SocialProvider>(context, listen: false);
        _socialProvider!.fetchInitialConnections(brokerId);
        _socialProvider!.subscribeToSocialAccounts(brokerId);
      }
    });

    // Handle deep link callback params (connected/error)
    final state = GoRouterState.of(context);
    final queryParams = state.uri.queryParameters;
    if (queryParams.containsKey('connected')) {
      final connected = queryParams['connected'] == 'true';
      final error = queryParams['error'];
      final platform = queryParams['platform'] ?? 'facebook';

      // Clear query parameters by replacing the route so we don't trigger the toast again on rebuilds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/dashboard');

          if (connected) {
            final authProvider = context.read<AuthProvider>();
            final socialProvider = context.read<SocialProvider>();
            final brokerId = authProvider.userProfile?.brokerId?.id;
            if (brokerId != null && brokerId.isNotEmpty) {
              socialProvider.fetchInitialConnections(
                brokerId,
                forceShimmer: false,
              );
            }

            AppToast.showSuccess(
              'Connection Successful',
              'Successfully connected your $platform account!',
            );
          } else if (error != null) {
            AppToast.showError('Connection Failed', Uri.decodeComponent(error));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final socialProvider = context.watch<SocialProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Main Content Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 950.0;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left / Middle Column (Flex: 7 - ~65% Width)
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(
                                title: 'Overview Performance',
                                icon: Icons.insights_rounded,
                              ),
                              const DashboardSummaryWidget(),
                              const SizedBox(height: 24.0),
                              const Divider(height: 1.0, color: AppColors.border),
                              const SizedBox(height: 24.0),
                              const RecentPropertiesWidget(),
                              const SizedBox(height: 24.0),
                              const Divider(height: 1.0, color: AppColors.border),
                              const SizedBox(height: 24.0),
                              const RecentPostsWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24.0),

                        // Right Column (Flex: 3 - ~35% Width)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(
                                title: 'Connected Channels',
                                icon: Icons.link_rounded,
                              ),
                              if (socialProvider.isFetchingConnections)
                                const SocialConnectShimmerWidget(
                                  isVertical: true,
                                )
                              else ...[
                                _buildFacebookCard(
                                  context,
                                  authProvider,
                                  socialProvider,
                                ),
                                const SizedBox(height: 12.0),
                                _buildInstagramCard(
                                  context,
                                  authProvider,
                                  socialProvider,
                                ),
                              ],
                              const SizedBox(height: 24.0),
                              const Divider(height: 1.0, color: AppColors.border),
                              const SizedBox(height: 24.0),
                              const RecentLeadsWidget(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile Column Layout: Summary -> Connected Channels -> Recent Leads -> Recent Posts -> Recent Properties
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Summary / Overview Performance
                      const AppSectionHeader(
                        title: 'Overview Performance',
                        icon: Icons.insights_rounded,
                      ),
                      const DashboardSummaryWidget(),
                      const SizedBox(height: 24.0),
                      const Divider(height: 1.0, color: AppColors.border),
                      const SizedBox(height: 24.0),

                      // Section 2: Connected Channels (Social Channels)
                      const AppSectionHeader(
                        title: 'Connected Channels',
                        icon: Icons.link_rounded,
                      ),
                      if (socialProvider.isFetchingConnections)
                        const SocialConnectShimmerWidget(isVertical: true)
                      else ...[
                        _buildFacebookCard(
                          context,
                          authProvider,
                          socialProvider,
                        ),
                        const SizedBox(height: 10.0),
                        _buildInstagramCard(
                          context,
                          authProvider,
                          socialProvider,
                        ),
                      ],
                      const SizedBox(height: 24.0),
                      const Divider(height: 1.0, color: AppColors.border),
                      const SizedBox(height: 24.0),

                      // Section 3: Recent Leads Widget (Top 3 Leads)
                      const RecentLeadsWidget(),
                      const SizedBox(height: 24.0),
                      const Divider(height: 1.0, color: AppColors.border),
                      const SizedBox(height: 24.0),

                      // Section 4: Recent Posts Widget (Top 3 Posts)
                      const RecentPostsWidget(),
                      const SizedBox(height: 24.0),
                      const Divider(height: 1.0, color: AppColors.border),
                      const SizedBox(height: 24.0),

                      // Section 5: Recent Properties Widget (Top 3 Properties)
                      const RecentPropertiesWidget(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisconnectDialog(
    BuildContext context,
    String brokerId,
    String platform,
    SocialProvider provider,
  ) {
    final platformDisplayName = platform == 'facebook'
        ? 'Facebook Page'
        : 'Instagram Business';

    AppDialog.show(
      context,
      title: 'Disconnect $platformDisplayName',
      description:
          'Are you sure you want to disconnect $platformDisplayName? This will unsubscribe webhooks and revoke Meta access permissions.',
      type: DialogType.error,
      confirmText: context.tr('disconnect'),
      cancelText: context.tr('cancel'),
      onConfirm: () {
        provider.disconnectSocialAccount(brokerId, platform);
      },
    );
  }

  Widget _buildFacebookCard(
    BuildContext context,
    AuthProvider authProvider,
    SocialProvider provider,
  ) {
    final brokerId = authProvider.userProfile?.brokerId?.id;
    final String? pageId = provider.facebookAccount?.pageId;
    final String? imageUrl =
        provider.facebookAccount?.profilePictureUrl ??
        (pageId != null
            ? 'https://graph.facebook.com/$pageId/picture?type=large'
            : null);

    return SocialConnectCard(
      platformName: context.tr('facebook_pages'),
      description: context.tr('facebook_desc'),
      features: [context.tr('auto_capture'), context.tr('real_time_comment')],
      isConnected: provider.isFacebookConnected,
      isLoading: provider.isPlatformDisconnecting('facebook'),
      userName: provider.facebookAccount?.pageName,
      userImageUrl: imageUrl,
      onConnectPressed: () {
        if (provider.isFacebookConnected) {
          if (brokerId != null) {
            _showDisconnectDialog(context, brokerId, 'facebook', provider);
          }
        } else {
          if (brokerId != null) {
            provider.connectFacebook(brokerId);
          }
        }
      },
      logo: Image.asset(
        'assets/icons/facebook.png',
        width: 40.0,
        height: 40.0,
        fit: BoxFit.contain,
      ),
      buttonColor: const Color(0xFF1877F2),
    );
  }

  Widget _buildInstagramCard(
    BuildContext context,
    AuthProvider authProvider,
    SocialProvider provider,
  ) {
    final brokerId = authProvider.userProfile?.brokerId?.id;
    final String? imageUrl = provider.instagramAccount?.profilePictureUrl;

    return SocialConnectCard(
      platformName: context.tr('instagram_business'),
      description: context.tr('instagram_desc'),
      features: [context.tr('visual_message'), context.tr('story_reply')],
      isConnected: provider.isInstagramConnected,
      isLoading: provider.isPlatformDisconnecting('instagram'),
      userName: provider.instagramAccount?.instagramUsername,
      userImageUrl: imageUrl,
      onConnectPressed: () {
        if (provider.isInstagramConnected) {
          if (brokerId != null) {
            _showDisconnectDialog(context, brokerId, 'instagram', provider);
          }
        } else {
          if (brokerId != null) {
            provider.connectInstagramDirectly(brokerId);
          }
        }
      },
      logo: Image.asset(
        'assets/icons/instagram.png',
        width: 40.0,
        height: 40.0,
        fit: BoxFit.contain,
      ),
      buttonGradient: const [Color(0xFFFCAF45), Color(0xFFC13584)],
    );
  }
}
