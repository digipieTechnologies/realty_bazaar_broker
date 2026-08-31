import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_routes.dart';
import '../../core/services/clarity_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/models.dart';
import '../../util/common_ext.dart';
import '../../widgets/toast/app_toast.dart';
import '../chat/chat_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../lead/lead_provider.dart';
import '../property/property_provider.dart';
import '../social/social_provider.dart';
import '../video_request/video_request_provider.dart';

class AuthProvider extends ChangeNotifier {
  static const String sessionKey = 'user_id';
  final _storage = GetStorage();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears any lingering authentication error message state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Signs in a user using email and password, then saves the session.
  /// Returns true if successful, false otherwise.
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user returned.');
      }

      // Verify user state in public.users table
      final profile = await SupabaseConfig.client.from('users').select().eq('id', user.id).maybeSingle();

      if (profile == null) {
        await signOut();
        throw const AuthException('User profile not found in public registry.');
      }

      final isActive = profile['is_active'] as bool? ?? true;
      final isDeleted = profile['is_deleted'] as bool? ?? false;

      if (isDeleted) {
        await signOut();
        throw const AuthException('This account has been deleted.');
      }
      if (!isActive) {
        await signOut();
        throw const AuthException('This account is currently deactivated.');
      }

      // Verify Role Access: Only UserRole.broker accounts are allowed in this app
      final userRole = UserRole.fromDbValue(profile['role']);
      if (userRole != UserRole.broker) {
        await signOut();
        throw const AuthException('Access Denied: Only Broker accounts can sign in to this application.');
      }

      // Persist user session ID
      await _storage.write(sessionKey, user.id);

      // Fetch and cache user profile
      _userProfile = UserModel.fromJson(profile);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Signs up a user in Supabase Auth and auto-signs them in (no email confirmation).
  /// Returns true if successful, false otherwise.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Check if user already exists in public.users table
      final existingUser = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      if (existingUser != null) {
        throw const AuthException('An account with this email already exists. Please sign in instead.');
      }

      // 2. Sign up in Supabase Auth (no email confirmation required)
      final response = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: null,
        data: {'display_name': name.trim(), 'role': UserRole.broker.dbValue},
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed. No user profile returned.');
      }

      // 3. Detect duplicate via empty identities
      //    When email confirmation is disabled, Supabase returns a user with
      //    an empty identities list for already-registered emails.
      if (user.identities?.isEmpty ?? false) {
        throw const AuthException('An account with this email already exists. Please sign in instead.');
      }

      // 4. Create new Broker record in database first
      final brokerInsert = await SupabaseConfig.client
          .from('brokers')
          .insert({'business_name': '', 'plan': 'Free', 'onboarding_status': 'pending', 'is_active': true})
          .select('id')
          .single();

      final brokerId = brokerInsert['id'] as String;

      // 5. Sync profile metadata to public.users table with role 'broker' and linked broker_id
      final cleanPhone = phone.trim().replaceAll(RegExp(r'^\+?91'), '').trim();
      await SupabaseConfig.client.from('users').insert({
        'id': user.id,
        'name': name.trim(),
        'email': email.trim(),
        'phone': cleanPhone,
        'phone_country_code': '91',
        'phone_country_iso': 'IN',
        'role': UserRole.broker.dbValue,
        'is_active': true,
        'is_deleted': false,
        'broker_id': brokerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5. Auto sign-in to establish a full authenticated session
      await SupabaseConfig.client.auth.signInWithPassword(email: email.trim(), password: password);

      // 6. Persist session locally
      await _storage.write(sessionKey, user.id);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Checks if an email is already registered in public.users table.
  Future<bool> checkEmailExists(String email) async {
    _setLoading(true);
    try {
      final existingUser = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      if (existingUser != null) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email exists: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Requests a 2-minute OTP for pre-signup verification using `generate_user_otp` RPC.
  Future<bool> requestSignUpOtp(String email, [AppOtpType otpType = AppOtpType.emailVerify]) async {
    _setLoading(true);
    _setError(null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      debugPrint(
        '🔑 [Frontend Log] Requesting OTP generation RPC for email: $cleanEmail, type: ${otpType.dbValue}',
      );

      // Invoke SQL RPC function `generate_user_otp` to create OTP record in DB
      final res = await SupabaseConfig.client.rpc(
        'generate_user_otp',
        params: {'p_email': cleanEmail, 'p_otp_type': otpType.dbValue},
      );

      debugPrint('✅ [Frontend Log] generate_user_otp RPC Response: $res');

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] generate_user_otp RPC Error: $e');
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Validates the 2-minute OTP via server-side DB query matching and completes user registration & database profile creation.
  Future<bool> completeSignUpWithOtp({
    required Map<String, String> signUpData,
    required String otp,
    AppOtpType otpType = AppOtpType.emailVerify,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final email = signUpData['email']?.trim().toLowerCase();
      final name = signUpData['name']?.trim();
      final password = signUpData['password'];
      final phone = signUpData['phone']?.trim() ?? '';

      if (email == null || password == null || name == null) {
        throw const AuthException('Invalid sign-up details provided.');
      }

      debugPrint(
        '🔍 [Frontend Log] Verifying OTP for completeSignUp: email=$email, otp=$otp, type=${otpType.dbValue}',
      );

      // 1. Server-Side Verification: Query user_otps directly matching email, otp, otp_type & non-expired time
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final otpRecords = await SupabaseConfig.client
          .from('user_otps')
          .select()
          .eq('email', email)
          .eq('otp', otp.trim())
          .eq('otp_type', otpType.dbValue)
          .gte('expiry_at', nowIso);

      debugPrint('✅ [Frontend Log] OTP Verification records found: ${otpRecords.length}');

      if (otpRecords.isEmpty) {
        throw const AuthException('Invalid or expired verification code. Please check and try again.');
      }

      final record = otpRecords.first;

      // 2. Perform actual Sign Up in Supabase Auth
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {'display_name': name, 'role': UserRole.broker.dbValue},
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed. No user profile returned.');
      }

      if (user.identities?.isEmpty ?? false) {
        throw const AuthException('An account with this email already exists. Please sign in instead.');
      }

      // 3. Create linked Broker record
      final brokerInsert = await SupabaseConfig.client
          .from('brokers')
          .insert({'business_name': '', 'plan': 'Free', 'onboarding_status': 'pending', 'is_active': true})
          .select('id')
          .single();

      final brokerId = brokerInsert['id'] as String;

      // 4. Create user profile in public.users table with is_email_verified = true
      final cleanPhone = phone.replaceAll(RegExp(r'^\+?91'), '').trim();
      await SupabaseConfig.client.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'phone_country_code': '91',
        'phone_country_iso': 'IN',
        'role': UserRole.broker.dbValue,
        'is_active': true,
        'is_deleted': false,
        'is_email_verified': true,
        'broker_id': brokerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5. Clean up used OTP record
      await SupabaseConfig.client.from('user_otps').delete().eq('id', record['id']);

      // 6. Establish full session
      await SupabaseConfig.client.auth.signInWithPassword(email: email, password: password);

      await _storage.write(sessionKey, user.id);

      debugPrint('🎉 [Frontend Log] SignUp & OTP verification completed successfully for user ${user.id}');
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] completeSignUpWithOtp Error: $e');
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  UserModel? _userProfile;
  UserModel? get userProfile => _userProfile;
  bool get isAuthenticated =>
      _userProfile != null || (_storage.read<String>(sessionKey)?.isNotEmpty ?? false);

  /// Checks email existence and role, then generates a 2-minute OTP for forgot password using `generate_user_otp` RPC.
  Future<bool> requestForgotPasswordOtp(String email, {UserRole expectedRole = UserRole.broker}) async {
    _setLoading(true);
    _setError(null);
    try {
      final cleanEmail = email.trim().toLowerCase();

      // 1. Check if email exists in public.users
      final userRecord = await SupabaseConfig.client
          .from('users')
          .select('id, role')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (userRecord == null) {
        throw const AuthException('No registered account found with this email address.');
      }

      final roleStr = userRecord['role'] as String?;
      if (roleStr != expectedRole.dbValue) {
        throw const AuthException('This account does not have permission for this portal.');
      }

      // 2. Invoke generate_user_otp RPC for forgot_password type
      final res = await SupabaseConfig.client.rpc(
        'generate_user_otp',
        params: {'p_email': cleanEmail, 'p_otp_type': AppOtpType.forgotPassword.dbValue},
      );

      debugPrint('✅ [Frontend Log] requestForgotPasswordOtp RPC Response: $res');
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] requestForgotPasswordOtp Error: $e');
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Updates user password in backend database via reset_user_password RPC.
  Future<bool> resetPasswordWithOtp({required String email, required String newPassword}) async {
    _setLoading(true);
    _setError(null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      final res = await SupabaseConfig.client.rpc(
        'reset_user_password',
        params: {'p_email': cleanEmail, 'p_new_password': newPassword},
      );

      debugPrint('✅ [Frontend Log] resetPasswordWithOtp Response: $res');
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] resetPasswordWithOtp Error: $e');
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Verifies email OTP via server-side DB query matching and updates is_email_verified flag in public.users table.
  Future<bool> verifyEmailOtp({
    String? email,
    String? userId,
    required String otp,
    AppOtpType otpType = AppOtpType.emailVerify,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final targetUserId = userId ?? _userProfile?.id;
      final targetEmail = email ?? _userProfile?.email;

      if (targetUserId == null && targetEmail == null) {
        throw const AuthException('No user session or email specified for OTP verification.');
      }

      debugPrint(
        '🔍 [Frontend Log] Verifying OTP: email=$targetEmail, userId=$targetUserId, otp=$otp, type=${otpType.dbValue}',
      );

      // Server-Side Verification: Query user_otps directly matching email/userId, otp, otp_type & non-expired time
      final nowIso = DateTime.now().toUtc().toIso8601String();
      var query = SupabaseConfig.client
          .from('user_otps')
          .select()
          .eq('otp', otp.trim())
          .eq('otp_type', otpType.dbValue)
          .gte('expiry_at', nowIso);

      if (targetEmail != null && targetEmail.trim().isNotEmpty) {
        query = query.eq('email', targetEmail.trim().toLowerCase());
      } else if (targetUserId != null) {
        query = query.eq('user_id', targetUserId);
      }

      final otpRecords = await query;
      debugPrint('✅ [Frontend Log] OTP Verification records found: ${otpRecords.length}');

      if (otpRecords.isEmpty) {
        throw const AuthException('Invalid or expired verification code. Please check and try again.');
      }

      final record = otpRecords.first;

      // Update is_email_verified to true in public.users table
      if (targetUserId != null) {
        await SupabaseConfig.client.from('users').update({'is_email_verified': true}).eq('id', targetUserId);
      }
      if (targetEmail != null && targetEmail.trim().isNotEmpty) {
        await SupabaseConfig.client
            .from('users')
            .update({'is_email_verified': true})
            .eq('email', targetEmail.trim().toLowerCase());
      }

      // Clean up used OTP record
      await SupabaseConfig.client.from('user_otps').delete().eq('id', record['id']);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(isEmailVerified: true);
      } else if (targetUserId != null) {
        await fetchCurrentUserProfile(targetUserId);
      }

      debugPrint('🎉 [Frontend Log] Email OTP verified successfully.');
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] verifyEmailOtp Error: $e');
      _setError(e.getUserExceptionMessage());
      _setLoading(false);
      return false;
    }
  }

  /// Resends a new OTP using `generate_user_otp` RPC function.
  Future<bool> resendEmailOtp({
    String? email,
    String? userId,
    AppOtpType otpType = AppOtpType.emailVerify,
  }) async {
    _setError(null);
    try {
      final targetEmail = email ?? _userProfile?.email;
      if (targetEmail == null) {
        throw const AuthException('Email address is required to resend OTP.');
      }

      debugPrint('🔑 [Frontend Log] Resending OTP for email: $targetEmail, type: ${otpType.dbValue}');

      // Call generate_user_otp RPC function
      final res = await SupabaseConfig.client.rpc(
        'generate_user_otp',
        params: {'p_email': targetEmail, 'p_otp_type': otpType.dbValue},
      );

      debugPrint('✅ [Frontend Log] Resend generate_user_otp RPC Response: $res');

      return true;
    } catch (e) {
      debugPrint('❌ [Frontend Log] resendEmailOtp Error: $e');
      _setError(e.getUserExceptionMessage());
      return false;
    }
  }

  /// Fetches the currently logged-in user profile, performing active session checks, role access validation, and auto sign-out if deactivated/deleted.
  Future<UserModel?> fetchCurrentUserProfile(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select('*, broker_id(*, address_id(*))')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        _userProfile = null;
        notifyListeners();
        await signOut();
        AppRoutes.router.go(AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.showError('Session Expired', 'User account not found on server.');
        });
        return null;
      }

      final profile = UserModel.fromJson(response);

      // Check soft-delete status
      if (profile.isDeleted ?? false) {
        _userProfile = null;
        notifyListeners();
        await signOut();
        AppRoutes.router.go(AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.showError('Auth Error', 'This account has been deleted.');
        });
        return null;
      }

      // Check active status
      if (!(profile.isActive ?? true)) {
        _userProfile = null;
        notifyListeners();
        await signOut();
        AppRoutes.router.go(AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.showError('Auth Error', 'This account is currently deactivated.');
        });
        return null;
      }

      // Check email verification status
      if (!(profile.isEmailVerified ?? false)) {
        _userProfile = null;
        notifyListeners();
        await signOut();
        AppRoutes.router.go(AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.showError(
            'Email Verification Required',
            'Your email address is not verified. Please sign in to verify your email.',
          );
        });
        return null;
      }

      // Verify Role Access: Only Broker accounts allowed in this app
      if (profile.role != UserRole.broker) {
        _userProfile = null;
        notifyListeners();
        await signOut();
        AppRoutes.router.go(AppRoutes.login);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToast.showError('Access Denied', 'Only Broker accounts can sign in to this application.');
        });
        return null;
      }

      _userProfile = profile;
      notifyListeners();
      subscribeToCurrentUserRealtime(id);
      syncDeviceToken(id);

      // Identify user and tag role in Microsoft Clarity
      ClarityService.instance.setUserId(id);
      if (profile.role != null) {
        ClarityService.instance.setCustomTag('role', profile.role!.dbValue);
      }
      if (profile.name != null && profile.name!.isNotEmpty) {
        ClarityService.instance.setCustomTag('user_name', profile.name!);
      }

      return _userProfile;
    } catch (e) {
      debugPrint('Error fetching current user profile for $id: $e');
      return null;
    }
  }

  RealtimeChannel? _userRealtimeChannel;

  /// Subscribes to realtime updates for the current logged-in user in public.users
  void subscribeToCurrentUserRealtime(String userId) {
    unsubscribeCurrentUserRealtime();

    _userRealtimeChannel = SupabaseConfig.client
        .channel('user_realtime_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: userId),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord.isEmpty) return;

            final updatedUser = UserModel.fromJson(newRecord);

            if (updatedUser.isDeleted ?? false) {
              await _handleRemoteLogout('Auth Error', 'This account has been deleted.');
            } else if (!(updatedUser.isActive ?? true)) {
              await _handleRemoteLogout('Auth Error', 'This account is currently deactivated.');
            } else if (!(updatedUser.isEmailVerified ?? false)) {
              await _handleRemoteLogout(
                'Email Verification Required',
                'Your email verification status was modified. Please sign in again.',
              );
            } else if (updatedUser.role != UserRole.broker) {
              await _handleRemoteLogout('Access Denied', 'Your user role has been modified.');
            }
          },
        )
        .subscribe();
  }

  Future<void> _handleRemoteLogout(String title, String message) async {
    unsubscribeCurrentUserRealtime();
    _userProfile = null;
    notifyListeners();
    await signOut();
    AppRoutes.router.go(AppRoutes.login);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.showError(title, message);
    });
  }

  void unsubscribeCurrentUserRealtime() {
    if (_userRealtimeChannel != null) {
      SupabaseConfig.client.removeChannel(_userRealtimeChannel!);
      _userRealtimeChannel = null;
    }
  }

  /// Pure query helper to fetch any user details by UUID without triggering auth session side-effects or logouts.
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select('*, broker_id(*, address_id(*))')
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile by ID $id: $e');
      return null;
    }
  }

  /// Updates the user profile, broker name, and address details in the database.
  Future<bool> updateProfileAndBroker({
    required String name,
    required String phone,
    required String businessName,
    required String fullAddress,
    required String? city,
    required String? state,
    required String? pincode,
    required String? country,
    required String? landmark,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final userId = _userProfile?.id;
      if (userId == null) throw Exception("No active session found.");

      final broker = _userProfile?.brokerId;
      final brokerId = broker?.id;
      if (brokerId == null) throw Exception("No linked broker found.");

      String? addressId = broker?.addressId?.id;

      // 1. Insert or Update the address record in the addresses table
      if (addressId == null) {
        final addressInsert = await SupabaseConfig.client
            .from('addresses')
            .insert({
              'full_address': fullAddress.trim(),
              'city': city?.trim(),
              'state': state?.trim(),
              'pincode': pincode?.trim(),
              'country': country?.trim(),
              'landmark': landmark?.trim(),
              'entity_type': 'broker',
              'entity_id': brokerId,
            })
            .select('id')
            .single();

        addressId = addressInsert['id'] as String;

        // Update the broker table with business name and linked address_id
        await SupabaseConfig.client
            .from('brokers')
            .update({'business_name': businessName.trim(), 'address_id': addressId})
            .eq('id', brokerId);
      } else {
        await SupabaseConfig.client
            .from('addresses')
            .update({
              'full_address': fullAddress.trim(),
              'city': city?.trim(),
              'state': state?.trim(),
              'pincode': pincode?.trim(),
              'country': country?.trim(),
              'landmark': landmark?.trim(),
            })
            .eq('id', addressId);

        // Update broker business name
        await SupabaseConfig.client
            .from('brokers')
            .update({'business_name': businessName.trim()})
            .eq('id', brokerId);
      }

      // 2. Update the user details
      final cleanPhone = phone.trim().replaceAll(RegExp(r'^\+?91'), '').trim();
      await SupabaseConfig.client
          .from('users')
          .update({
            'name': name.trim(),
            'phone': cleanPhone,
            'phone_country_code': '91',
            'phone_country_iso': 'IN',
          })
          .eq('id', userId);

      // 3. Update broker setup_details in Supabase if business_info_added is false
      final currentSetup = broker?.setupDetails ?? const BrokerSetupDetailsModel();
      if (!currentSetup.businessInfoAdded) {
        final updatedSetup = currentSetup.copyWith(businessInfoAdded: true);
        await SupabaseConfig.client
            .from('brokers')
            .update({'setup_details': updatedSetup.toJson()})
            .eq('id', brokerId);
      }

      // Re-fetch profile with updated details to sync cache and local state
      await fetchCurrentUserProfile(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates local broker setupDetails in memory when a social connection is detected active.
  void updateLocalBrokerSetupDetails({required BrokerSetupDetailsModel setupDetails}) {
    final currentBroker = _userProfile?.brokerId;
    if (currentBroker == null) return;
    final updatedBroker = currentBroker.copyWith(setupDetails: setupDetails);
    _userProfile = _userProfile!.copyWith(brokerId: updatedBroker);
    notifyListeners();
  }

  static const String fcmTokenKey = 'cached_fcm_token';

  /// Syncs logged in user session with OneSignal push service.
  Future<void> syncDeviceToken(String userId) async {
    try {
      await NotificationService.instance.bindUserToOneSignal(userId);
    } catch (e) {
      debugPrint('Error syncing OneSignal user ID: $e');
    }
  }

  /// Unbinds user from OneSignal upon user sign out.
  Future<void> removeDeviceTokenOnLogout() async {
    try {
      // Unbind user from OneSignal
      await NotificationService.instance.unbindUserFromOneSignal();
    } catch (e) {
      debugPrint('Error removing device token on logout: $e');
    }
  }

  /// Logs out the user and clears all data, subscriptions, and push token sessions ONLY after successful sign out.
  Future<void> signOut([BuildContext? context]) async {
    _setLoading(true);
    try {
      // 1. First, attempt to sign out from Supabase Auth backend
      await SupabaseConfig.client.auth.signOut();

      // 2. Unsubscribe user profile real-time listener
      unsubscribeCurrentUserRealtime();

      // 3. Remove all active Supabase real-time channel subscriptions
      try {
        await SupabaseConfig.client.removeAllChannels();
      } catch (e) {
        debugPrint('Error removing channels on sign out: $e');
      }

      // 4. Unbind user session from OneSignal push notification service
      await removeDeviceTokenOnLogout();

      // 5. Remove persisted session key from storage
      await _storage.remove(sessionKey);

      // 6. Clear cached user profile and error state
      _userProfile = null;
      _errorMessage = null;

      // 7. Reset all feature provider in-memory data AFTER successful sign out
      final targetContext = context ?? AppRoutes.rootNavigatorKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        try {
          targetContext.read<DashboardProvider>().clear();
          targetContext.read<LeadProvider>().clear();
          targetContext.read<PropertyProvider>().clear();
          targetContext.read<VideoRequestProvider>().clear();
          targetContext.read<ChatProvider>().clear();
          targetContext.read<SocialProvider>().clear();
        } catch (e) {
          debugPrint('Error clearing feature providers on sign out: $e');
        }
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Permanently deletes / soft-deletes the current authenticated user's account via Edge Function
  Future<bool> deleteAccount({required String reason, BuildContext? context}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'delete-account',
        body: {'action': 'request', 'reason': reason},
      );

      if (response.status == 409) {
        final msg = response.data?['message'] ?? 'A deletion request is already pending.';
        _setError(msg);
        return false;
      }

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Failed to delete account.';
        throw Exception(errorMsg);
      }

      // Cleanup local state and feature providers
      unsubscribeCurrentUserRealtime();
      try {
        await SupabaseConfig.client.removeAllChannels();
      } catch (e) {
        debugPrint('Error removing channels: $e');
      }

      await removeDeviceTokenOnLogout();
      await _storage.remove(sessionKey);
      _userProfile = null;

      final targetContext = context ?? AppRoutes.rootNavigatorKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        try {
          targetContext.read<DashboardProvider>().clear();
          targetContext.read<LeadProvider>().clear();
          targetContext.read<PropertyProvider>().clear();
          targetContext.read<VideoRequestProvider>().clear();
          targetContext.read<ChatProvider>().clear();
          targetContext.read<SocialProvider>().clear();
        } catch (e) {
          debugPrint('Error clearing feature providers on deletion: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Submits a public account deletion request for unauthenticated / guest users
  Future<bool> submitPublicDeletionRequest({String? email, String? phone, String? reason}) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'delete-account',
        body: {
          'action': 'request',
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'reason': reason ?? 'Public web deletion request',
        },
      );

      if (response.status == 409) {
        final msg = response.data?['message'] ?? 'A deletion request is already pending.';
        _setError(msg);
        return false;
      }

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Failed to submit deletion request.';
        _setError(errorMsg.toString());
        return false;
      }

      return true;
    } on FunctionException catch (fe) {
      debugPrint('Public delete account FunctionException: ${fe.details}');
      final msg = fe.details is Map ? (fe.details['error'] ?? fe.reasonPhrase) : fe.reasonPhrase;
      _setError(msg?.toString() ?? 'No account found matching these details.');
      return false;
    } catch (e) {
      debugPrint('Public delete account error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}
