// File: lib/modules/auth/screens/reset_password_screen.dart
// Purpose: Responsive Reset/Update Password Screen matching auth theme with modern back button.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_strings.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/password_field_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPasswordSubmit() async {
    AppUtils.dismissKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPasswordWithOtp(
      email: widget.email,
      newPassword: _passwordController.text,
    );

    if (success && mounted) {
      AppToast.showSuccess(
        'Password Reset Successful',
        'Your password has been updated. Please sign in with your new password.',
      );
      context.go(AppRoutes.login);
    } else if (mounted) {
      AppToast.showError(
        'Password Reset Failed',
        authProvider.errorMessage ?? 'Failed to update password. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          // Background soft glowing shapes for mobile view
          if (!isDesktop) ...[
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05)),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.03),
                ),
              ),
            ),
          ],

          Row(
            children: [
              // Left Sidebar (Visible only on desktop viewports)
              if (isDesktop) Expanded(child: _leftSidebar()),

              // Right Form Column
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _modernBackButton(),
                            const SizedBox(height: 24.0),
                            isDesktop
                                ? _formContent()
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24.0),
                                      border: Border.all(color: AppColors.border, width: 1.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 20.0,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _formContent(),
                                  ),
                            const SizedBox(height: 32.0),
                            _copyrightFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8.0, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  'Back to Login',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LEFT SIDEBAR COMPONENT ---
  Widget _leftSidebar() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(AppAssets.building), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark.withOpacity(0.85), AppColors.primary.withOpacity(0.70)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8.0)],
              ),
              child: const AppLogo(size: 38.0),
            ),
            const Spacer(),
            Text(
              'Secure Your Account',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Set a strong, new password to protect your ${AppStrings.appName} account and client data.',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15.0, height: 1.45),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // --- FORM CONTENT ---
  Widget _formContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeaderWidget(
            title: 'Set New Password',
            subtitle:
                'Your new password must be at least 6 characters long and different from previous passwords.',
          ),
          const SizedBox(height: 24.0),

          // New Password field
          PasswordFieldWidget(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'New Password',
            textInputAction: TextInputAction.next,
            validator: (val) {
              if (val.isEmptyORNull) return 'Please enter a new password';
              if (!val.isStrongPassword)
                return 'Password must be at least 6 characters with a letter and digit';
              return null;
            },
          ),
          const SizedBox(height: 16.0),

          // Confirm New Password field
          PasswordFieldWidget(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'Confirm New Password',
            textInputAction: TextInputAction.done,
            validator: (val) {
              if (val.isEmptyORNull) return 'Please confirm your new password';
              if (val != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28.0),

          _ResetPasswordSubmitButton(onPressed: _handleResetPasswordSubmit),
        ],
      ),
    );
  }

  Widget _copyrightFooter() {
    return Text(
      '© ${DateTime.now().year} ${AppStrings.appName}. All rights reserved.',
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

class _ResetPasswordSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResetPasswordSubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return AppButton(
      text: 'UPDATE PASSWORD',
      variant: AppButtonVariant.gradient,
      isLoading: isLoading,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.0),
      onPressed: onPressed,
    ).disable(isDisable: isLoading);
  }
}
