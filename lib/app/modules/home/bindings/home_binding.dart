import 'package:get/get.dart';
import 'package:spendly/app/modules/business/controllers/business_home_controller.dart';
import 'package:spendly/app/modules/expense/controllers/expense_controller.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ExpenseController());
    Get.put(IncomeController());
    Get.put(LoanController());
    Get.put(BusinessHomeController());
  }
}
