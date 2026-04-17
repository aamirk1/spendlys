import 'package:get/get.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/services/app_update_service.dart';
import 'package:spendly/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services & Infrastructure
    final secureStorage = SecureStorageService();
    Get.put(secureStorage, permanent: true);
    Get.put(ApiClient(baseUrl: ApiConstants.baseUrl, secureStorage: secureStorage), permanent: true);
    Get.put(NetworkService(), permanent: true);
    
    // 2. State Management (Controllers)
    Get.put(LocalizationController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    
    // AuthService MUST be put before SignInController since SignInController depends on it
    Get.put(AuthService());
    Get.put(AppUpdateService(), permanent: true);
    Get.put(SignInController());
    
    // AuthController for OTP flow
    Get.put(AuthController());
    // NOTE: ExpenseController and IncomeController are NOT registered here.
    // They call the API in onInit() which would fire before login (→ 401).
    // Instead they are lazy-registered via Get.lazyPut in the home binding.
  }
}
