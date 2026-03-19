import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/screens/business/invoice_list.dart';
import 'package:spendly/screens/business/customers_list.dart';

enum LedgerType { business, loan, expense }

class LedgerController extends GetxController {
  final selectedType = LedgerType.loan.obs;
  final isLoading = false.obs;

  // We reuse existing controllers for data
  final LoanController loanController = Get.find<LoanController>();
  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();

  // For business, we might need a separate controller or fetch logic
  final invoices = [].obs;
  final customers = <String, String>{}.obs; // ID -> Name map

  @override
  void onInit() {
    super.onInit();
    // Default fetch for loans since it's initial selected type
    fetchData();
  }

  void setType(LedgerType type) {
    selectedType.value = type;
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      switch (selectedType.value) {
        case LedgerType.business:
          // 1. Fetch Customers first for mapping
          await _fetchCustomerMap();

          // 2. Reuse fetchInvoices
          if (Get.isRegistered<InvoiceListController>()) {
            await Get.find<InvoiceListController>().fetchInvoices();
          } else {
            Get.put(InvoiceListController());
            await Get.find<InvoiceListController>().fetchInvoices();
          }

          // 3. Inject names into local list
          final rawInvoices = Get.find<InvoiceListController>().invoices;
          invoices.value = rawInvoices.map((inv) {
            final name = getCustomerName(inv);
            return {...inv, 'resolved_customer_name': name};
          }).toList();
          break;
        case LedgerType.loan:
          await loanController.fetchLoans();
          break;
        case LedgerType.expense:
          // Expense/Income controllers reactive anyway
          break;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchCustomerMap() async {
    try {
      Get.put(CustomersController());
      await Get.find<CustomersController>().fetchCustomers();
      final List allCust = Get.find<CustomersController>().customers;
      final Map<String, String> mapping = {};
      for (var c in allCust) {
        if (c['id'] != null) {
          mapping[c['id'].toString()] = c['name']?.toString() ?? "Unknown";
        }
      }
      customers.value = mapping;
    } catch (_) {}
  }

  String getCustomerName(dynamic invoice) {
    if (invoice['customer'] != null && invoice['customer']['name'] != null) {
      return invoice['customer']['name'];
    }
    if (invoice['customer_name'] != null &&
        invoice['customer_name'].toString().isNotEmpty) {
      return invoice['customer_name'];
    }
    final String? custId = invoice['customer_id']?.toString();
    if (custId != null && customers.containsKey(custId)) {
      return customers[custId]!;
    }
    return "Unknown Customer";
  }
}
