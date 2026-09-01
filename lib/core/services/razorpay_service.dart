import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../widgets/toast/app_toast.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Callbacks
  final Function(PaymentSuccessResponse)? onSuccess;
  final Function(PaymentFailureResponse)? onFailure;
  final Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService({
    this.onSuccess,
    this.onFailure,
    this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    if (onSuccess != null) {
      onSuccess!(response);
    } else {
      AppToast.showSuccess('Payment Successful', 'Your payment was completed successfully.');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    if (onFailure != null) {
      onFailure!(response);
    } else {
      AppToast.showError('Payment Failed', response.message ?? 'An error occurred during payment.');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// Opens the Razorpay checkout modal
  /// [amountInPaise] is the amount in paise (e.g., Rs. 500 = 50000)
  bool openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    required String contact,
    required String email,
    String? orderId, // Optional, normally fetched from your backend
  }) {
    const keyId = String.fromEnvironment('RAZORPAY_KEY_ID');
    
    if (keyId.isEmpty || keyId == 'rzp_test_placeholder_key') {
      AppToast.showError('Configuration Error', 'Razorpay Key ID is missing or invalid.');
      return false;
    }

    var options = {
      'key': keyId,
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {
        'color': '#0F325E', // Match AppColors.primary (primary900)
      }
    };

    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay.open(options);
      return true;
    } catch (e) {
      debugPrint('Error starting Razorpay checkout: $e');
      AppToast.showError('Error', 'Failed to initialize payment gateway.');
      return false;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
