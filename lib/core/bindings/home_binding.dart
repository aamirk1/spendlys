import 'package:get/get.dart';
import 'package:spendly/controllers/expense_controller.dart';
import 'package:spendly/controllers/income_controller.dart';
import 'package:spendly/features/business/presentation/screens/business_home_view.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ExpenseController());
    Get.put(IncomeController());
    Get.put(BusinessHomeController());
  }
}
