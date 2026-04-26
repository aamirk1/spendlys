import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/models/premium_feature.dart';
import 'package:spendly/utils/utils.dart';

class PaymentController extends GetxController {
  late Razorpay _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var isLoading = false.obs;
  var premiumAmount = 149.obs; // Default
  var isPremium = false.obs;
  var premiumFeatures = <PremiumFeature>[].obs;

  final GetStorage box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    isPremium.value = box.read("isPremium") ?? false;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchPremiumAmount();
    fetchPremiumFeatures();
    checkPremiumStatus();
  }

  Future<void> checkPremiumStatus() async {
    try {
      final userId = box.read("userId");
      final response = await ApiService.get(
        '/auth/me',
        headers: {'x-user-id': userId ?? ''},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        isPremium.value = data['is_premium'] ?? false;
        box.write("isPremium", isPremium.value);
      }
    } catch (e) {
      debugPrint('Error checking premium status: $e');
    }
  }

  Future<void> fetchPremiumAmount() async {
    try {
      final response = await ApiService.get('/payment/premium-amount');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        premiumAmount.value = data['amount'];
      }
    } catch (e) {
      debugPrint('Error fetching premium amount: $e');
    }
  }

  Future<void> fetchPremiumFeatures() async {
    isLoading.value = true;
    try {
      final response = await ApiService.get('/payment/premium-features');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        premiumFeatures
            .assignAll(data.map((e) => PremiumFeature.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching premium features: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment successful, now verify on backend
    await verifyPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isLoading.value = false;
    Utils.showSnackbar('Payment Failed', response.message ?? 'Unknown error');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isLoading.value = false;
    Utils.showSnackbar('External Wallet', 'Selected: ${response.walletName}');
  }

  Future<void> initiateOrder(int amount) async {
    isLoading.value = true;
    try {
      final userId = box.read("userId");
      final response = await ApiService.post(
        '/payment/initiate-order',
        headers: {
          'x-user-id': userId ?? '',
        },
        body: {
          'amount': amount * 100, // convert to paise
          'currency': 'INR',
        },
      );

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);
        _openCheckout(orderData);
      } else {
        isLoading.value = false;
        String errorMessage = 'Failed to initiate order';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (_) {}
        Utils.showSnackbar('Error', errorMessage);
      }
    } catch (e) {
      isLoading.value = false;
      Utils.showSnackbar('Error', 'An error occurred: $e');
    }
  }

  void _openCheckout(Map<String, dynamic> orderData) {
    var options = {
      'key': orderData['key'],
      'amount': orderData['amount'],
      'name': 'DailyBacaht Premium',
      'order_id': orderData['order_id'],
      'description': 'Unlock all premium features',
      'prefill': {
        'contact': _auth.currentUser?.phoneNumber ?? '',
        'email': _auth.currentUser?.email ?? ''
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> verifyPayment(PaymentSuccessResponse response) async {
    isLoading.value = true;
    try {
      final userId = box.read("userId");
      final verifyResp = await ApiService.post(
        '/payment/verify-payment',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId ?? '',
        },
        body: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
        },
      );

      if (verifyResp.statusCode == 200) {
        final data = jsonDecode(verifyResp.body);
        isPremium.value = data['is_premium'] ?? true;
        box.write("isPremium", isPremium.value);

        Utils.showSnackbar('Success', 'Welcome to Premium!', isError: false);

        // Refresh the status from server just to be sure everything is synced
        await checkPremiumStatus();

        // If we are on the premium screen, go back
        if (Get.currentRoute.contains('premium')) {
          Get.back();
        }
      } else {
        final errorMsg = jsonDecode(verifyResp.body)['detail'] ??
            'Payment verification failed';
        Utils.showSnackbar('Error', errorMsg);
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Verification error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
