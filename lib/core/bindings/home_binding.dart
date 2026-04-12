import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/screens/business/business_home_view.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ExpenseController());
    Get.put(IncomeController());
    Get.put(LoanController());
    Get.put(BusinessHomeController());
  }
}
