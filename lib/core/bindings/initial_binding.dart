import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkService());
    Get.put(ExpenseController());
    Get.put(IncomeController());

    final secureStorage = SecureStorageService();
    Get.put(secureStorage);
    Get.put(
        ApiClient(baseUrl: ApiConstants.baseUrl, secureStorage: secureStorage));
  }
}
