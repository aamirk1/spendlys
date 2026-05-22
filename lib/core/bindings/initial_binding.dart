import 'package:get/get.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/app_update_service.dart';
import 'package:spendly/controllers/auth_controller.dart';
import 'package:spendly/features/business/data/services/business_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/core/services/sync_service.dart';

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
    Get.put(ConnectivityService(), permanent: true);
    Get.put(SyncService(), permanent: true);

    // 2. State Management (Controllers)
    Get.put(LocalizationController(), permanent: true);
    Get.put(ThemeController(), permanent: true);

    // AuthService MUST be put before SignInController since SignInController depends on it
    Get.put(AuthService(), permanent: true);
    Get.put(AppUpdateService(), permanent: true);
    Get.put(SignInController());

    // AuthController for OTP flow
    Get.put(AuthController());
    Get.put(BusinessService(), permanent: true);
  }
}
