import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/modules/business/controllers/customers_controller.dart';

class CustomerDetailController extends GetxController {
  final customer = <String, dynamic>{}.obs;
  CustomerDetailController(Map<String, dynamic> initialCustomer) {
    customer.value = initialCustomer;
  }

  final invoices = [].obs;
  final quotations = [].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomerTransactions();
    // Keep local customer object in sync with CustomersController when updates happen
    if (Get.isRegistered<CustomersController>()) {
      final customersController = Get.find<CustomersController>();
      ever(customersController.customers, (_) {
        final match = customersController.customers.firstWhere(
          (c) => c['id']?.toString() == customer['id']?.toString(),
          orElse: () => null,
        );
        if (match != null) {
          customer.value = Map<String, dynamic>.from(match);
        }
      });
    }
  }

  Future<void> fetchCustomerTransactions() async {
    isLoading.value = true;
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      // 1. Fetch invoices
      final invResponse = await ApiService.get('/business/invoices', headers: {'x-user-id': userId});
      if (invResponse.statusCode == 200) {
        final allInvoices = jsonDecode(invResponse.body) as List;
        invoices.value = allInvoices.where((inv) {
          final custId = inv['customer']?['id']?.toString() ?? inv['customer_id']?.toString();
          return custId == customer['id']?.toString() || 
                 inv['customer']?['name']?.toString().toLowerCase() == customer['name']?.toString().toLowerCase();
        }).toList();
      }

      // 2. Fetch quotations
      final quotResponse = await ApiService.get('/business/quotations', headers: {'x-user-id': userId});
      if (quotResponse.statusCode == 200) {
        final allQuotations = jsonDecode(quotResponse.body) as List;
        quotations.value = allQuotations.where((q) {
          final custId = q['customer']?['id']?.toString() ?? q['customer_id']?.toString();
          return custId == customer['id']?.toString() ||
                 q['customer']?['name']?.toString().toLowerCase() == customer['name']?.toString().toLowerCase();
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching customer transactions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  double get totalSalesAmount {
    return invoices.fold(0.0, (sum, inv) => sum + (double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0));
  }

  double get pendingDuesAmount {
    return invoices.fold(0.0, (sum, inv) {
      final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
      final paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
      return sum + (total - paid);
    });
  }

  double get totalPaidAmount {
    return invoices.fold(0.0, (sum, inv) => sum + (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0));
  }
}
