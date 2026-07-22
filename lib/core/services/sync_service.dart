import 'package:get/get.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/controllers/categoryController.dart';
import 'package:spendly/screens/business/invoice_list.dart';
import 'package:spendly/screens/business/quotation_list.dart';
import 'package:spendly/screens/business/inventory/inventory_list_view.dart';
import 'package:spendly/screens/business/customers_list.dart';

import 'dart:async';

class SyncService extends GetxService {
  final _isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Periodically try to sync if online
    Timer.periodic(const Duration(minutes: 5), (_) => startSync());
  }

  Future<void> startSync() async {
    final connectivity = Get.find<ConnectivityService>();
    if (!connectivity.isOnline.value || _isSyncing.value) return;

    final pendingRequests = LocalCacheService.getAllPendingRequests();
    if (pendingRequests.isEmpty) return;

    _isSyncing.value = true;
    debugPrint(
        "--- Sync Starting: Found ${pendingRequests.length} pending items ---");

    for (var req in pendingRequests) {
      final id = req['id'];
      final endpoint = req['endpoint'];
      final method = req['method'];
      final headers = Map<String, String>.from(req['headers'] ?? {});
      final body = req['body'];

      try {
        late dynamic response;
        if (method == 'POST') {
          response = await ApiService.post(endpoint,
              headers: headers, body: body, bypassCache: true);
        } else if (method == 'PUT') {
          response = await ApiService.put(endpoint,
              headers: headers, body: body, bypassCache: true);
        } else if (method == 'DELETE') {
          response = await ApiService.delete(endpoint,
              headers: headers, bypassCache: true);
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint("Sync Success: $method $endpoint");
          await LocalCacheService.removePendingRequest(id);
        } else {
          debugPrint("Sync Failed: status code ${response.statusCode}");
          // Keep it to retry later or handle specific errors
        }
      } catch (e) {
        debugPrint("Sync Exception: $e");
        // Connection lost or API error, stop processing this queue for now
        break;
      }
    }

    _isSyncing.value = false;
    debugPrint("--- Sync Finished ---");

    // Refresh active controllers to sync UI with real IDs from DB
    if (Get.isRegistered<IncomeController>()) {
      Get.find<IncomeController>().fetchIncomes();
    }
    if (Get.isRegistered<ExpenseController>()) {
      Get.find<ExpenseController>().fetchExpenses();
    }
    if (Get.isRegistered<LoanController>()) {
      Get.find<LoanController>().fetchLoans();
    }
    if (Get.isRegistered<CategoryController>()) {
      Get.find<CategoryController>().fetchCategories();
    }
    if (Get.isRegistered<InvoiceListController>()) {
      Get.find<InvoiceListController>().fetchInvoices(refresh: true);
    }
    if (Get.isRegistered<QuotationListController>()) {
      Get.find<QuotationListController>().fetchQuotations();
    }
    if (Get.isRegistered<InventoryController>()) {
      Get.find<InventoryController>().fetchProducts();
    }
    if (Get.isRegistered<CustomersController>()) {
      Get.find<CustomersController>().fetchCustomers();
    }
  }
}
