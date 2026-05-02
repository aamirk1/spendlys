import 'package:flutter/material.dart';
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

  // Search and Filter
  final searchQuery = ''.obs;
  final dateRange = Rxn<DateTimeRange>();

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
    
    // Ensure Business controllers are registered for reactivity
    if (!Get.isRegistered<InvoiceListController>()) Get.put(InvoiceListController());
    
    // Listen to changes in source lists to update the resolved business list in real-time
    ever(Get.find<InvoiceListController>().invoices, (_) => _updateBusinessInvoices());
    ever(customers, (_) => _updateBusinessInvoices());

    // Default fetch for loans since it's initial selected type
    fetchData();
  }

  void _updateBusinessInvoices() {
    if (!Get.isRegistered<InvoiceListController>()) return;
    final rawInvoices = Get.find<InvoiceListController>().invoices;
    invoices.value = rawInvoices.map((inv) {
      final name = getCustomerName(inv);
      return {...inv, 'resolved_customer_name': name};
    }).toList();
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
          _updateBusinessInvoices();
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

  // Filtered Getters
  List get filteredBusiness => invoices.where((inv) {
        if (searchQuery.value.isEmpty) return true;
        final name = (inv['resolved_customer_name'] ?? '').toString().toLowerCase();
        final id = (inv['invoice_number'] ?? '').toString().toLowerCase();
        final matchesSearch =
            name.contains(searchQuery.value.toLowerCase()) ||
                id.contains(searchQuery.value.toLowerCase());

        bool matchesDate = true;
        if (dateRange.value != null && inv['date'] != null) {
          final d = DateTime.parse(inv['date']);
          matchesDate = d.isAfter(dateRange.value!.start
                  .subtract(const Duration(seconds: 1))) &&
              d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
        }
        return matchesSearch && matchesDate;
      }).toList();

  List get filteredLoans {
    List all = [...loanController.borrowed, ...loanController.lent];
    all.sort((a, b) => b.date.compareTo(a.date));

    if (dateRange.value != null) {
      all = all.where((l) {
        return l.date.isAfter(dateRange.value!.start
                .subtract(const Duration(seconds: 1))) &&
            l.date.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (searchQuery.value.isEmpty) return all;
    return all
        .where((l) => l.personName
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  List get filteredExpenses {
    final incomes = incomeController.incomeList
        .map((e) => {...e, 'ledgerType': 'INCOME'})
        .toList();
    final expenses = expenseController.expensesList
        .map((e) => {...e, 'ledgerType': 'EXPENSE'})
        .toList();
    List all = [...incomes, ...expenses];
    all.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (dateRange.value != null) {
      all = all.where((item) {
        final d = item['date'] as DateTime;
        return d.isAfter(dateRange.value!.start
                .subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (searchQuery.value.isEmpty) return all;
    return all.where((item) {
      final desc = (item['description'] ?? item['category'] ?? "Transaction")
          .toString()
          .toLowerCase();
      return desc.contains(searchQuery.value.toLowerCase());
    }).toList();
  }
}
