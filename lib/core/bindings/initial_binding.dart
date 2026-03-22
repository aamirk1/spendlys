import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/controllers/sign_in_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkService());
    Get.put(ExpenseController());
    Get.put(IncomeController());
    Get.put(LocalizationController());
    Get.put(ThemeController());
    Get.put(SignInController());

    final secureStorage = SecureStorageService();
    Get.put(secureStorage);
    Get.put(
        ApiClient(baseUrl: ApiConstants.baseUrl, secureStorage: secureStorage));
  }
}
