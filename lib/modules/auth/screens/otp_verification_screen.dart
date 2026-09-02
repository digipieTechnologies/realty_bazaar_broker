// File: lib/modules/auth/screens/otp_verification_screen.dart
// Purpose: Interactive, responsive OTP verification screen matching the The Realty Bazaar App auth design system.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/otp_type.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/inputs/app_pinput_field.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/auth_header_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? email;
  final String? userId;
  final bool isPreSignup;
  final AppOtpType otpType;
  final Map<String, String>? signUpData;

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.userId,
    this.isPreSignup = false,
    this.otpType = AppOtpType.emailVerify,
    this.signUpData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  int _resendCountdown = 30; // 30 seconds expiry timer
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOtp() async {
    AppUtils.dismissKeyboard(context);
    final otp = _pinController.text.trim();
    if (otp.length < 6) {
      AppToast.showError(context.tr('invalid_otp_title'), context.tr('invalid_otp_desc'));
      return;
    }

    final authProvider = context.read<AuthProvider>();

    if (widget.otpType == AppOtpType.forgotPassword) {
      // Forgot Password OTP verification
      final success = await authProvider.verifyEmailOtp(
        email: widget.email,
        userId: widget.userId,
        otp: otp,
        otpType: AppOtpType.forgotPassword,
      );

      if (success && mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        AppToast.showSuccess(
          context.tr('security_code_verified_title'),
          context.tr('security_code_verified_desc'),
        );
        context.go(AppRoutes.resetPassword, extra: {'email': widget.email});
      } else if (mounted) {
        AppToast.showError(
          context.tr('verification_failed_title'),
          authProvider.errorMessage ?? context.tr('invalid_expired_otp_desc'),
        );
      }
    } else if (widget.isPreSignup && widget.signUpData != null) {
      // Pre-signup verification: validates 2-minute OTP & creates account
      final success = await authProvider.completeSignUpWithOtp(signUpData: widget.signUpData!, otp: otp);

      if (success && mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        AppToast.showSuccess(
          context.tr('registration_complete_title'),
          context.tr('registration_complete_desc'),
        );
        context.go(AppRoutes.home);
      } else if (mounted) {
        AppToast.showError(
          context.tr('verification_failed_title'),
          authProvider.errorMessage ?? context.tr('invalid_expired_otp_desc'),
        );
      }
    } else {
      // Post-login verification
      final success = await authProvider.verifyEmailOtp(
        email: widget.email,
        userId: widget.userId,
        otp: otp,
        otpType: widget.otpType,
      );

      if (success && mounted) {
        AppToast.showSuccess(context.tr('email_verified_title'), context.tr('email_verified_desc'));
        context.go(AppRoutes.home);
      } else if (mounted) {
        AppToast.showError(
          context.tr('verification_failed_title'),
          authProvider.errorMessage ?? context.tr('invalid_expired_otp_desc'),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    final authProvider = context.read<AuthProvider>();
    final targetEmail = widget.email ?? widget.signUpData?['email'];

    if (targetEmail == null || targetEmail.isEmpty) {
      AppToast.showError(context.tr('error'), context.tr('email_missing_desc'));
      setState(() {
        _isResending = false;
      });
      return;
    }

    final success = await authProvider.resendEmailOtp(
      email: targetEmail,
      userId: widget.userId,
      otpType: widget.otpType,
    );

    if (mounted) {
      setState(() {
        _isResending = false;
      });
      if (success) {
        AppToast.showSuccess(
          context.tr('code_sent_toast_title'),
          context.tr('new_code_sent_desc'),
        );
        _startResendTimer();
      } else {
        AppToast.showError(
          context.tr('resend_failed_title'),
          authProvider.errorMessage ?? context.tr('resend_failed_desc'),
        );
      }
    }
  }

  Future<void> _handleBackToLogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final targetEmail = widget.email ?? authProviderEmail(context) ?? 'your email';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackToLogin();
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Stack(
          children: [
            if (!isDesktop) ...[
              Positioned(
                top: -120,
                right: -120,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
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
                    color: AppColors.primary800.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ],
            Row(
              children: [
                if (isDesktop) Expanded(child: _leftSidebar()),
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
                                  ? _formContent(targetEmail)
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24.0),
                                        border: Border.all(color: AppColors.border, width: 1.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 20.0,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: _formContent(targetEmail),
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
      ),
    );
  }

  String? authProviderEmail(BuildContext context) {
    try {
      return context.watch<AuthProvider>().userProfile?.email;
    } catch (_) {
      return null;
    }
  }

  Widget _leftSidebar() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(AppAssets.building), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary700.withValues(alpha: 0.85),
              AppColors.primary.withValues(alpha: 0.70),
            ],
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.0)],
              ),
              child: const AppLogo(size: 38.0),
            ),
            const Spacer(),
            Text(
              context.tr('empowering_leaders'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Secure your account with 2-step verification.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15.0, height: 1.45),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }

  Widget _formContent(String email) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeaderWidget(
            title: context.tr('verify_email_title'),
            subtitle: context.tr('verify_email_subtitle').replaceAll('{email}', email),
          ),
          const SizedBox(height: 32.0),

          // App Pinput Field
          AppPinputField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            length: 6,
            autofocus: true,
            onCompleted: (_) => _handleVerifyOtp(),
          ),

          const SizedBox(height: 32.0),

          // Verify button
          AppButton(
            text: context.tr('verify_email_btn'),
            variant: AppButtonVariant.gradient,
            isLoading: isLoading,
            isDisabled: isLoading,
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.0),
            onPressed: _handleVerifyOtp,
          ),

          const SizedBox(height: 24.0),

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.tr('did_not_receive_code'), style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 4.0),
              _resendCountdown > 0
                  ? Text(
                      context.tr('resend_in_seconds', arguments: {'seconds': '$_resendCountdown'}),
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : InkWell(
                      onTap: _isResending ? null : _handleResendOtp,
                      borderRadius: BorderRadius.circular(4.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Text(
                          _isResending ? context.tr('sending_code') : context.tr('resend_code'),
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
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
          onTap: _handleBackToLogin,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  context.tr('back_to_login'),
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

  Widget _copyrightFooter() {
    return Text(
      context.tr('copyright_text'),
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}
