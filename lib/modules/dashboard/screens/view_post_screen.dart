// File: lib/modules/dashboard/screens/view_post_screen.dart
// Purpose: Dedicated screen for viewing Social Post Details by ID/Object for direct deep linking and modal navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/social_enums.dart';
import '../../../models/social_post_model.dart';
import '../../../providers/social/social_provider.dart';
import '../../../app/app_utils.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/social_post_card.dart';

class ViewPostScreen extends StatefulWidget {
  final SocialPostModel? post;
  final String? postId;

  const ViewPostScreen({super.key, this.post, this.postId});

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  SocialPostModel? _post;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post;
    } else if (widget.postId != null && widget.postId!.isNotEmpty) {
      _isLoading = true;
      _fetchPost(widget.postId!);
    }
  }

  Future<void> _fetchPost(String id) async {
    try {
      final provider = Provider.of<SocialProvider>(context, listen: false);
      final fetched = await provider.fetchPostById(id);
      if (mounted) {
        setState(() {
          _post = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'Post details not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading post details.';
        });
      }
    }
  }

  void _sharePostLink() {
    final effectiveId = _post?.postId ?? _post?.platformPostId ?? _post?.id ?? widget.postId ?? '';
    final url = 'https://the-realty-bazaar-broker.web.app/posts/$effectiveId';
    Clipboard.setData(ClipboardData(text: url));
    AppToast.showSuccess('Link Copied', 'Post deep link copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('post_details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null || _post == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('post_details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Post details not found.', style: AppTextStyles.body1),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    final hasPermalink = post.permalink != null && post.permalink!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: context.tr('post_details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Deep Link',
            onPressed: _sharePostLink,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.screenWidth800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Card representation
                SocialPostCard(post: post),

                const SizedBox(height: 16),

                // External Actions Card
                if (hasPermalink)
                  AppCardContainer(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View on ${post.platform == SocialPlatform.facebook ? 'Facebook' : 'Instagram'}',
                                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Open the native post page directly in browser or app',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          text: 'Open Post',
                          width: 120,
                          height: 40,
                          onPressed: () => AppUtils.launchAppUrl(post.permalink!),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
