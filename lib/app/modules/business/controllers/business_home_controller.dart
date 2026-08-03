import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/utils/utils.dart';

class BusinessHomeController extends GetxController {
  final isLoading = false.obs;

  // Raw data lists
  final invoices = [].obs;
  final quotations = [].obs;
  final customers = [].obs;
  final products = [].obs;

  // Selected tab & sub-filters
  final selectedSectionTab =
      'Invoices'.obs; // Invoices, Quotations, Customers, Products, Payments
  final activeInvoiceFilter = 'All'.obs; // All, Paid, Pending
  final activeQuotationFilter = 'All'.obs; // All, Accepted, Pending, Rejected
  final selectedFilter = 'This Month'.obs;

  // Search
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Focus node for appbar search action
  final searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });
    refreshData();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchInvoices(),
        fetchQuotations(),
        fetchCustomers(),
        fetchProducts(),
      ]);
    } catch (e) {
      debugPrint("Error refreshing business dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSummary() => refreshData();

  // individual fetches
  Future<void> fetchInvoices() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/invoices',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        invoices.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching invoices: $e");
    }
  }

  Future<void> fetchQuotations() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/quotations',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        quotations.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching quotations: $e");
    }
  }

  Future<void> fetchCustomers() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/customers',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        customers.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    }
  }

  Future<void> fetchProducts() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/inventory/',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        products.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  bool _isWithinFilter(dynamic dateValue, String filter) {
    if (dateValue == null) return false;
    try {
      final DateTime date = dateValue is DateTime
          ? dateValue
          : DateTime.parse(dateValue.toString());
      final now = DateTime.now();
      switch (filter) {
        case 'This Week':
          final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysToSubtract));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return date
                  .isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endOfWeek);
        case 'This Month':
          return date.year == now.year && date.month == now.month;
        case 'This Year':
          return date.year == now.year;
        default:
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  // Dashboard calculations
  double get totalSales => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(
          0.0,
          (sum, inv) =>
              sum + (double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0));
  int get totalInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .length;
  int get paidInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status']?.toString().toLowerCase() ?? '') == 'paid')
      .length;
  int get pendingInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status']?.toString().toLowerCase() ?? '') != 'paid')
      .length;

  double get pendingAmount => invoices
          .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
          .fold(0.0, (sum, inv) {
        final double total =
            double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final double paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  double get receivedAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(
          0.0,
          (sum, inv) =>
              sum +
              (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0));

  // Filtered lists for display
  List get filteredInvoices {
    List list = invoices;

    // Sub-filter tabs (All, Paid, Pending)
    if (activeInvoiceFilter.value == 'Paid') {
      list = list
          .where((inv) =>
              (inv['status']?.toString().toLowerCase() ?? '') == 'paid')
          .toList();
    } else if (activeInvoiceFilter.value == 'Pending') {
      list = list
          .where((inv) =>
              (inv['status']?.toString().toLowerCase() ?? '') != 'paid')
          .toList();
    }

    // Search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((inv) =>
              (inv['invoice_number']?.toString().toLowerCase() ?? '')
                  .contains(query) ||
              (inv['customer_name']?.toString().toLowerCase() ?? '')
                  .contains(query))
          .toList();
    }
    return list;
  }

  List get filteredQuotations {
    List list = quotations;

    // Sub-filter tabs (All, Accepted, Pending, Rejected)
    if (activeQuotationFilter.value == 'Accepted') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'accepted' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'converted')
          .toList();
    } else if (activeQuotationFilter.value == 'Pending') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'pending' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'sent' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'draft')
          .toList();
    } else if (activeQuotationFilter.value == 'Rejected') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'rejected' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'expired')
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((q) =>
              (q['quotation_number']?.toString().toLowerCase() ?? '')
                  .contains(query) ||
              (q['customer_name']?.toString().toLowerCase() ?? '')
                  .contains(query))
          .toList();
    }
    return list;
  }

  List get filteredCustomers {
    List list = customers;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((c) =>
              (c['name']?.toString().toLowerCase() ?? '').contains(query) ||
              (c['phone']?.toString().toLowerCase() ?? '').contains(query))
          .toList();
    }
    return list;
  }

  List get filteredProducts {
    List list = products;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((p) =>
              (p['name']?.toString().toLowerCase() ?? '').contains(query))
          .toList();
    }
    return list;
  }

  // Quick Customer add callback
  Future<void> quickAddCustomer(String name, String phone) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.post('/business/customers',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: {"name": name, "phone": phone});
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Customer $name added successfully!",
            isError: false);
        fetchCustomers();
      }
    } catch (e) {
      debugPrint("Failed to quick add customer: $e");
    }
  }

  // Record Payment dialogue invoice selection
  List get unpaidInvoices => invoices.where((inv) {
        final double total =
            double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final double paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return (total - paid) > 0.01;
      }).toList();

  Future<void> recordInvoicePayment(
      String invoiceId, double amount, String method, String reference) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    try {
      final payload = {
        "amount": amount,
        "method": method,
        "reference_id": reference
      };
      final response = await ApiService.post(
          '/business/invoices/$invoiceId/payments',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar(
            "Success", "Payment of ₹${amount.toStringAsFixed(0)} recorded!",
            isError: false);
        refreshData();
      } else {
        Utils.showSnackbar(
            "Error", "Failed to record payment: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception recording payment: $e");
    }
  }
}
