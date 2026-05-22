import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/features/premium/data/models/premium_feature_model.dart';

class PaymentState extends Equatable {
  final bool isLoading;
  final int premiumAmount;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final List<PremiumFeature> premiumFeatures;
  final String? errorMessage;
  final bool paymentSuccess;

  const PaymentState({
    this.isLoading = false,
    this.premiumAmount = 99,
    this.isPremium = false,
    this.premiumExpiry,
    this.premiumFeatures = const [],
    this.errorMessage,
    this.paymentSuccess = false,
  });

  int get remainingDays {
    if (premiumExpiry == null) return 0;
    final diff = premiumExpiry!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  PaymentState copyWith({
    bool? isLoading,
    int? premiumAmount,
    bool? isPremium,
    DateTime? premiumExpiry,
    List<PremiumFeature>? premiumFeatures,
    String? errorMessage,
    bool? paymentSuccess,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      premiumFeatures: premiumFeatures ?? this.premiumFeatures,
      errorMessage: errorMessage,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        premiumAmount,
        isPremium,
        premiumExpiry,
        premiumFeatures,
        errorMessage,
        paymentSuccess,
      ];
}

class PaymentCubit extends Cubit<PaymentState> {
  final GetStorage _box;
  late Razorpay _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PaymentCubit(this._box) : super(const PaymentState()) {
    final cachedIsPremium = _box.read("isPremium") ?? false;
    DateTime? cachedExpiry;
    if (_box.read("premiumExpiry") != null) {
      cachedExpiry = DateTime.parse(_box.read("premiumExpiry"));
    }
    emit(state.copyWith(
      isPremium: cachedIsPremium,
      premiumExpiry: cachedExpiry,
    ));

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
      final userId = _box.read("userId");
      final response = await ApiService.get(
        '/auth/me',
        headers: {'x-user-id': userId ?? ''},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPremiumVal = data['is_premium'] ?? false;
        DateTime? expiry;
        if (data['premium_expiry'] != null) {
          expiry = DateTime.parse(data['premium_expiry']);
          _box.write("premiumExpiry", data['premium_expiry']);
        }
        _box.write("isPremium", isPremiumVal);
        emit(state.copyWith(
          isPremium: isPremiumVal,
          premiumExpiry: expiry,
        ));
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
        emit(state.copyWith(premiumAmount: data['amount']));
      }
    } catch (e) {
      debugPrint('Error fetching premium amount: $e');
    }
  }

  Future<void> fetchPremiumFeatures() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.get('/payment/premium-features');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final features = data.map((e) => PremiumFeature.fromJson(e)).toList();
        emit(state.copyWith(
          premiumFeatures: features,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      debugPrint('Error fetching premium features: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await verifyPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    emit(state.copyWith(
      isLoading: false,
      errorMessage: response.message ?? 'Unknown error',
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    emit(state.copyWith(
      isLoading: false,
      errorMessage: 'Selected external wallet: ${response.walletName}',
    ));
  }

  Future<void> initiateOrder(int amount) async {
    emit(state.copyWith(isLoading: true, paymentSuccess: false));
    try {
      final userId = _box.read("userId");
      final int totalAmountWithFee = (amount * 1.03).round();

      final response = await ApiService.post(
        '/payment/initiate-order',
        headers: {
          'x-user-id': userId ?? '',
        },
        body: {
          'amount': totalAmountWithFee * 100, // convert to paise
          'currency': 'INR',
        },
      );

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);
        _openCheckout(orderData);
      } else {
        String errorMessage = 'Failed to initiate order';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (_) {}
        emit(state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred: $e',
      ));
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
      debugPrint('Error opening checkout: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to open payment gateway',
      ));
    }
  }

  Future<void> verifyPayment(PaymentSuccessResponse response) async {
    emit(state.copyWith(isLoading: true));
    try {
      final userId = _box.read("userId");
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
        final isPremiumVal = data['is_premium'] ?? true;
        DateTime? expiry;
        if (data['premium_expiry'] != null) {
          expiry = DateTime.parse(data['premium_expiry']);
          _box.write("premiumExpiry", data['premium_expiry']);
        }
        _box.write("isPremium", isPremiumVal);

        emit(state.copyWith(
          isPremium: isPremiumVal,
          premiumExpiry: expiry,
          isLoading: false,
          paymentSuccess: true,
        ));
      } else {
        final errorMsg = jsonDecode(verifyResp.body)['detail'] ?? 'Payment verification failed';
        emit(state.copyWith(
          isLoading: false,
          errorMessage: errorMsg,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Verification error: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _razorpay.clear();
    return super.close();
  }
}
