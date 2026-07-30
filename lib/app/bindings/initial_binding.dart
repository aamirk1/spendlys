import 'package:get/get.dart';
import 'package:spendly/app/data/services/network_service.dart';
import 'package:spendly/app/data/services/api_client.dart';
import 'package:spendly/app/data/services/api_constants.dart';
import 'package:spendly/app/data/services/secure_storage_service.dart';
import 'package:spendly/app/data/services/localization_controller.dart';
import 'package:spendly/app/data/services/theme_controller.dart';
import 'package:spendly/app/modules/auth/controllers/sign_in_controller.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/app_update_service.dart';
import 'package:spendly/app/modules/auth/controllers/auth_controller.dart';
import 'package:spendly/app/data/services/business_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services & Infrastructure
    final secureStorage = SecureStorageService();
    Get.put(secureStorage, permanent: true);
    Get.put(
        ApiClient(baseUrl: ApiConstants.baseUrl, secureStorage: secureStorage),
        permanent: true);
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
    Get.put(BusinessService(), permanent: true);
    // NOTE: ExpenseController and IncomeController are NOT registered here.
    // They call the API in onInit() which would fire before login (→ 401).
    // Instead they are lazy-registered via Get.lazyPut in the home binding.
  }
}
