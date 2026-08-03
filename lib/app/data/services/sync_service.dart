import 'package:get/get.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/data/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/modules/expense/controllers/expense_controller.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';
import 'package:spendly/app/modules/category/controllers/category_controller.dart';
import 'package:spendly/app/modules/business/controllers/invoice_list_controller.dart';
import 'package:spendly/app/modules/business/controllers/quotation_list_controller.dart';
import 'package:spendly/app/modules/business/controllers/inventory_controller.dart';
import 'package:spendly/app/modules/business/controllers/customers_controller.dart';
import 'package:spendly/app/modules/group_split/controllers/group_split_controller.dart';
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
    if (Get.isRegistered<GroupSplitController>()) {
      Get.find<GroupSplitController>().fetchGroupSplits();
    }
  }
}
