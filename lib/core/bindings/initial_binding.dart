import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/core/services/network_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkService());
    Get.put(ExpenseController());
    Get.put(IncomeController());
  }
}
