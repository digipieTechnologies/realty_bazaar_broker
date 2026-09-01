// File: lib/modules/auth/screens/login_screen.dart
// Purpose: Interactive high-fidelity Auth portal with inline state transitions, phone validation, and password strength checks.

// ignore_for_file: deprecated_member_use

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
import '../../../models/country_code.dart';
import '../../../models/otp_type.dart';
import '../../../models/user_enums.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/auth_footer_link_widget.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/password_field_widget.dart';
import '../widgets/phone_field_widget.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';

enum AuthMode { login, signup, forgotPassword }

class LoginScreen extends StatefulWidget {
  final AuthMode initialMode;
  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _submitFocusNode = FocusNode();
  final _footerLinkFocusNode = FocusNode();

  late AuthMode _currentMode;
  CountryCode _selectedCountry = CountryCode.countries.first; // Default to India (+91)

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _submitFocusNode.dispose();
    _footerLinkFocusNode.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    TextInput.finishAutofillContext(shouldSave: false);
    setState(() {
      _currentMode = mode;
      _formKey.currentState?.reset();
      // Clear form inputs when switching tabs for a clean experience
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _selectedCountry = CountryCode.countries.first;
    });
    // Unfocus active keyboard on switch
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleAuthSubmit() async {
    AppUtils.dismissKeyboard(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    if (_currentMode == AuthMode.login) {
      final success = await authProvider.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (success && mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        if (authProvider.userProfile?.isEmailVerified == false) {
          final targetEmail = _emailController.text.trim();
          await authProvider.resendEmailOtp(
            email: targetEmail,
            userId: authProvider.userProfile?.id,
            otpType: AppOtpType.emailVerify,
          );
          if (!mounted) return;
          AppToast.showError(
            'Email Verification Required',
            'We sent a 6-digit verification code to your email.',
          );
          context.go(
            AppRoutes.verifyOtp,
            extra: {
              'email': targetEmail,
              'userId': authProvider.userProfile?.id,
              'otpType': AppOtpType.emailVerify,
            },
          );
        } else {
          AppToast.showSuccess(context.tr('login_successful'), context.tr('welcome_back_generic'));
          context.go(AppRoutes.home);
        }
      } else if (mounted) {
        AppToast.showError(
          context.tr('auth_error'),
          authProvider.errorMessage ?? context.tr('error_generic'),
        );
      }
    } else if (_currentMode == AuthMode.signup) {
      final email = _emailController.text.trim();

      // 1. First check if user already exists in public.users
      final exists = await authProvider.checkEmailExists(email);
      if (exists && mounted) {
        AppToast.showError(
          'Already Registered',
          'An account with this email already exists. Please sign in instead.',
        );
        return;
      }

      // Format number as: +91 9999988888
      final cleanNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = '${_selectedCountry.code} $cleanNumber';

      // 2. Generate and send 2-minute verification OTP via RPC without creating account yet
      final otpSent = await authProvider.requestSignUpOtp(email);
      if (otpSent && mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        AppToast.showSuccess(
          'Verification Code Sent',
          'Please check your email for the 6-digit verification code.',
        );
        context.go(
          AppRoutes.verifyOtp,
          extra: {
            'email': email,
            'isPreSignup': true,
            'signUpData': {
              'name': _nameController.text.trim(),
              'email': email,
              'password': _passwordController.text,
              'phone': formattedPhone,
            },
            'otpType': AppOtpType.emailVerify,
          },
        );
      } else if (mounted) {
        AppToast.showError(
          'Verification Failed',
          authProvider.errorMessage ?? 'Unable to send verification code. Please try again.',
        );
      }
    } else if (_currentMode == AuthMode.forgotPassword) {
      final email = _emailController.text.trim();
      final success = await authProvider.requestForgotPasswordOtp(email, expectedRole: UserRole.broker);
      if (success && mounted) {
        TextInput.finishAutofillContext(shouldSave: false);
        AppToast.showSuccess(context.tr('code_sent_title'), context.tr('code_sent_sub'));
        context.go(AppRoutes.verifyOtp, extra: {'email': email, 'otpType': AppOtpType.forgotPassword});
      } else if (mounted) {
        AppToast.showError(
          context.tr('reset_failed'),
          authProvider.errorMessage ?? context.tr('error_generic'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          // Background soft glowing shapes for mobile view (low contrast theme-matching design)
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
                  color: AppColors.primary800.withOpacity(0.03),
                ),
              ),
            ),
          ],

          Row(
            children: [
              // Left Sidebar (Skyscraper view, visible only on larger viewports)
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
                            // Wrap form in a premium card structure on mobile viewports
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

  // --- LEFT SIDEBAR COMPONENT ---
  Widget _leftSidebar() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(AppAssets.building), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary700.withOpacity(0.85), AppColors.primary.withOpacity(0.70)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // White background transparent logo badge
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

            // Hero Title & Description
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
              context.tr('join_network'),
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15.0, height: 1.45),
            ),
            const SizedBox(height: 40.0),

            // Bottom Glassmorphic feature Cards
            Row(
              children: [
                Expanded(
                  child: _glassmorphicCard(
                    icon: Icons.analytics_outlined,
                    title: context.tr('adv_reporting'),
                    desc: context.tr('adv_reporting_desc'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _glassmorphicCard(
                    icon: Icons.apartment_outlined,
                    title: context.tr('asset_control'),
                    desc: context.tr('asset_control_desc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassmorphicCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24.0),
          const SizedBox(height: 12.0),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
          ),
          const SizedBox(height: 6.0),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.0, height: 1.3)),
        ],
      ),
    );
  }

  // --- FORM CONTAINER & SWITCHER ---
  Widget _formContent() {
    return FocusTraversalGroup(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerWidget(),
              const SizedBox(height: 24.0),

              // Dynamic form input fields
              if (_currentMode == AuthMode.signup) ...[_nameField(), const SizedBox(height: 16.0)],
              _emailField(),
              if (_currentMode == AuthMode.signup) ...[const SizedBox(height: 16.0), _phoneField()],
              if (_currentMode != AuthMode.forgotPassword) ...[
                const SizedBox(height: 16.0),
                _passwordField(),
              ],
              if (_currentMode == AuthMode.login) ...[const SizedBox(height: 8.0), _forgotPasswordLink()],
              if (_currentMode == AuthMode.signup) ...[const SizedBox(height: 16.0), _confirmPasswordField()],

              const SizedBox(height: 24.0),
              _AuthSubmitButton(
                currentMode: _currentMode,
                focusNode: _submitFocusNode,
                onPressed: _handleAuthSubmit,
              ),
              const SizedBox(height: 24.0),
              _footerLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerWidget() {
    switch (_currentMode) {
      case AuthMode.signup:
        return AuthHeaderWidget(
          title: context.tr('create_account'),
          subtitle: context.tr('create_account_sub'),
        );
      case AuthMode.forgotPassword:
        return AuthHeaderWidget(
          title: context.tr('forgot_password_title'),
          subtitle: context.tr('forgot_password_sub'),
        );
      case AuthMode.login:
        return AuthHeaderWidget(
          title: context.tr('welcome_back_title'),
          subtitle: context.tr('welcome_back_sub'),
        );
    }
  }

  Widget _nameField() {
    return AppTextField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      label: context.tr('full_name'),
      hint: 'John Doe',
      keyboardType: TextInputType.name,
      autofillHints: const [AutofillHints.name],
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
      validator: (val) {
        if (val.isEmptyORNull) return context.tr('full_name_required');
        return null;
      },
    );
  }

  Widget _emailField() {
    final isForgotPassword = _currentMode == AuthMode.forgotPassword;
    final isSignup = _currentMode == AuthMode.signup;

    return AppTextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      label: context.tr('email_address'),
      hint: 'name@therealtybazaar.com',
      keyboardType: TextInputType.emailAddress,
      autofillHints: isForgotPassword
          ? const [AutofillHints.email]
          : const [AutofillHints.email, AutofillHints.username],
      textInputAction: isForgotPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (isForgotPassword) {
          _handleAuthSubmit();
        } else if (isSignup) {
          _phoneFocusNode.requestFocus();
        } else {
          _passwordFocusNode.requestFocus();
        }
      },
      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
      validator: (val) {
        if (val.isEmptyORNull) return context.tr('email_required');
        if (!val.isEmail) return context.tr('valid_email_required');
        return null;
      },
    );
  }

  Widget _phoneField() {
    return PhoneFieldWidget(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      initialCountry: _selectedCountry,
      autofillHints: const [AutofillHints.telephoneNumber],
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      onCountryChanged: (country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  Widget _passwordField() {
    final isSignup = _currentMode == AuthMode.signup;

    return PasswordFieldWidget(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      label: context.tr('password'),
      autofillHints: isSignup ? const [AutofillHints.newPassword] : const [AutofillHints.password],
      textInputAction: isSignup ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (isSignup) {
          _confirmPasswordFocusNode.requestFocus();
        } else {
          _handleAuthSubmit();
        }
      },
      validator: (val) {
        if (val.isEmptyORNull) return context.tr('password_required');
        if (_currentMode == AuthMode.signup && !val.isStrongPassword) {
          return context.tr('strong_password_required');
        }
        return null;
      },
    );
  }

  Widget _forgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: ExcludeFocusTraversal(
        child: InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: () => _switchMode(AuthMode.forgotPassword),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Text(
              context.tr('forgot_password_link'),
              style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmPasswordField() {
    return PasswordFieldWidget(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      label: context.tr('confirm_password'),
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleAuthSubmit(),
      validator: (val) {
        if (val.isEmptyORNull) return context.tr('confirm_password_required');
        if (val != _passwordController.text) {
          return context.tr('passwords_dont_match');
        }
        return null;
      },
    );
  }

  Widget _footerLink() {
    if (_currentMode == AuthMode.signup) {
      return AuthFooterLinkWidget(
        focusNode: _footerLinkFocusNode,
        mainText: context.tr('already_have_account'),
        actionText: context.tr('sign_in'),
        onTap: () => _switchMode(AuthMode.login),
      );
    } else if (_currentMode == AuthMode.forgotPassword) {
      return AuthFooterLinkWidget(
        focusNode: _footerLinkFocusNode,
        mainText: context.tr('remember_password'),
        actionText: context.tr('sign_in'),
        onTap: () => _switchMode(AuthMode.login),
      );
    } else {
      return AuthFooterLinkWidget(
        focusNode: _footerLinkFocusNode,
        mainText: context.tr('dont_have_account'),
        actionText: 'Sign Up',
        onTap: () => _switchMode(AuthMode.signup),
      );
    }
  }

  Widget _copyrightFooter() {
    return Column(
      children: [
        Text(
          context.tr('copyright_text'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => AppNavigator.navigateToPrivacyPolicy(context),
              child: Text(
                context.tr('privacy_policy'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            InkWell(
              onTap: () => AppNavigator.navigateToTermsOfService(context),
              child: Text(
                context.tr('terms_of_service'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Extracted widget so context.select lives in its own BuildContext.
/// Only THIS widget rebuilds when isLoading changes — the parent form is untouched.
class _AuthSubmitButton extends StatelessWidget {
  final AuthMode currentMode;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const _AuthSubmitButton({required this.currentMode, required this.onPressed, this.focusNode});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    String buttonText = context.tr('sign_in_dashboard');
    if (currentMode == AuthMode.signup) {
      buttonText = 'Sign Up';
    } else if (currentMode == AuthMode.forgotPassword) {
      buttonText = context.tr('send_reset_link');
    }

    return AppButton(
      focusNode: focusNode,
      text: buttonText,
      variant: AppButtonVariant.gradient,
      isLoading: isLoading,
      isDisabled: isLoading,
      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20.0),
      onPressed: onPressed,
    );
  }
}
