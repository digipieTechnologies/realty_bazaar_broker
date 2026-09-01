// File: lib/modules/auth/screens/delete_account_screen.dart
// Purpose: Dual-mode responsive Delete Account Screen (Authenticated In-App & Public Web Deletion Request).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/toast/app_toast.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailPhoneController = TextEditingController();
  final _customReasonController = TextEditingController();

  String? _selectedReasonKey;
  bool _confirmedConsequences = false;
  bool _isProcessing = false;

  final List<String> _reasonKeys = [
    'delete_reason_1',
    'delete_reason_2',
    'delete_reason_3',
    'delete_reason_4',
    'delete_reason_5',
  ];

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  String _resolveSelectedReason(BuildContext context) {
    if (_selectedReasonKey == 'delete_reason_5' && _customReasonController.text.trim().isNotEmpty) {
      return _customReasonController.text.trim();
    }
    if (_selectedReasonKey != null) {
      return context.tr(_selectedReasonKey!);
    }
    return _customReasonController.text.trim().isNotEmpty
        ? _customReasonController.text.trim()
        : 'User requested account deletion';
  }

  Future<void> _handleAuthenticatedDelete(BuildContext context) async {
    if (!_confirmedConsequences) {
      AppToast.showError(context.tr('required'), context.tr('i_understand_delete_consequences'));
      return;
    }

    final deleteReason = _resolveSelectedReason(context);
    final successMsgTitle = context.tr('account_deleted_title');
    final successMsgDesc = context.tr('account_deleted_desc');
    final errorFallbackTitle = context.tr('error_generic');
    final authProvider = context.read<AuthProvider>();

    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('delete_account_confirm_title'),
      description: context.tr('delete_account_confirm_desc'),
      confirmText: context.tr('delete_account_button'),
      cancelText: context.tr('cancel'),
      type: DialogType.error,
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final success = await authProvider.deleteAccount(reason: deleteReason, context: context);

        if (!mounted) return;

        if (success) {
          AppToast.showSuccess(successMsgTitle, successMsgDesc);
          if (mounted) context.go(AppRoutes.login);
        } else {
          AppToast.showError(errorFallbackTitle, authProvider.errorMessage ?? errorFallbackTitle);
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _handlePublicDeletionRequest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailPhoneController.text.trim();
    final isEmail = input.contains('@');
    final reason = _resolveSelectedReason(context);
    final successTitle = context.tr('deletion_request_success_title');
    final successDesc = context.tr('deletion_request_success_desc');
    final errorFallback = context.tr('error_generic');

    setState(() => _isProcessing = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.submitPublicDeletionRequest(
        email: isEmail ? input : null,
        phone: !isEmail ? input : null,
        reason: reason,
      );

      if (!mounted) return;

      if (success) {
        AppToast.showSuccess(successTitle, successDesc);
        _emailPhoneController.clear();
        _customReasonController.clear();
        setState(() {
          _selectedReasonKey = null;
          _confirmedConsequences = false;
        });
      } else {
        AppToast.showError(errorFallback, authProvider.errorMessage ?? errorFallback);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final userProfile = authProvider.userProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(isAuthenticated ? AppRoutes.home : AppRoutes.initial);
            }
          },
        ),
        title: Text(context.tr('delete_account'), style: AppTextStyles.heading3.copyWith(fontSize: 18)),
        centerTitle: false,
        actions: [
          if (isDesktop) ...[
            TextButton(
              onPressed: () => context.push(AppRoutes.privacyPolicy),
              child: Text(
                context.tr('privacy_policy'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push(AppRoutes.termsOfService),
              child: Text(
                context.tr('terms_of_service'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 16.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 36.0 : 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadow.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_forever_outlined,
                                color: AppColors.error,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAuthenticated
                                        ? context.tr('delete_account')
                                        : context.tr('delete_account_public_title'),
                                    style: AppTextStyles.heading2.copyWith(color: AppColors.error),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAuthenticated
                                        ? context.tr('delete_account_subtitle')
                                        : context.tr('delete_account_public_subtitle'),
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 20),

                        // Warning Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.tr('delete_account_warning'),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // If Authenticated: Show active user details
                        if (isAuthenticated && userProfile != null) ...[
                          Text(
                            context.tr('personal_details'),
                            style: AppTextStyles.heading3.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    ((userProfile.name?.isNotEmpty ?? false) ? userProfile.name![0] : 'U')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProfile.name ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      Text(
                                        userProfile.email ?? '',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // If Public Guest: Show Email/Phone Input Form
                        if (!isAuthenticated) ...[
                          Text(
                            'Account Identifier (Email or Phone)',
                            style: AppTextStyles.heading3.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _emailPhoneController,
                            label: 'Email or Phone Number',
                            hint: 'e.g. broker@example.com or +919876543210',
                            prefixIcon: const Icon(
                              Icons.account_circle_outlined,
                              color: AppColors.iconDefault,
                            ),
                            validator: (val) =>
                                AppUtils.validateRequired(val, fieldName: 'Email or Phone Number'),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Reason Selection
                        Text(
                          context.tr('delete_reason_label'),
                          style: AppTextStyles.heading3.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        ..._reasonKeys.map((key) {
                          return Material(
                            type: MaterialType.transparency,
                            child: RadioListTile<String>(
                              value: key,
                              groupValue: _selectedReasonKey,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.error,
                              title: Text(context.tr(key), style: const TextStyle(fontSize: 14)),
                              onChanged: (val) {
                                setState(() => _selectedReasonKey = val);
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 12),

                        if (_selectedReasonKey == 'delete_reason_5' || _selectedReasonKey == null) ...[
                          AppTextField(
                            controller: _customReasonController,
                            label: context.tr('delete_reason_hint'),
                            hint: context.tr('delete_reason_hint'),
                            minLines: 4,
                            maxLines: 10,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Checkbox Confirmation
                        Material(
                          type: MaterialType.transparency,
                          child: CheckboxListTile(
                            value: _confirmedConsequences,
                            activeColor: AppColors.error,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              context.tr('i_understand_delete_consequences'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            onChanged: (val) {
                              setState(() => _confirmedConsequences = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        Align(
                          alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
                          child: AppButton(
                            text: isAuthenticated
                                ? context.tr('delete_account_button')
                                : context.tr('submit_deletion_request'),
                            variant: AppButtonVariant.solid,
                            color: AppColors.error,
                            width: isDesktop ? 260.0 : double.infinity,
                            borderRadius: 30,
                            height: 48,
                            isLoading: _isProcessing,
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    if (isAuthenticated) {
                                      _handleAuthenticatedDelete(context);
                                    } else {
                                      _handlePublicDeletionRequest(context);
                                    }
                                  },
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 20),

                        // Google Play Policy Disclosures
                        Text(
                          context.tr('delete_steps_title'),
                          style: AppTextStyles.heading3.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('delete_step_1'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('delete_step_2'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('delete_step_3'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          context.tr('data_retention_title'),
                          style: AppTextStyles.heading3.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('data_retention_desc'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
