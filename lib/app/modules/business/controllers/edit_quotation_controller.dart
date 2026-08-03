import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/modules/business/models/quotation_item.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/profile/controllers/user_info_controller.dart';
import 'package:spendly/app/modules/business/controllers/quotation_list_controller.dart';

class EditQuotationController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final customers = [].obs;
  final items = <QuotationItem>[].obs;
  final products = [].obs;

  final selectedCustomerId = Rxn<String>();
  final quotationNumberController = TextEditingController();
  final advanceAmountController = TextEditingController(text: "0.0");

  final taxPercent = 0.0.obs;

  final paymentMode = 'Cash'.obs;
  final paymentModes = ['Cash', 'Bank Transfer', 'Credit Card', 'UPI', 'Other'];

  final isLoading = false.obs;

  late String quotationId;

  void initData(Map<String, dynamic> quot) {
    quotationId = quot['id'];
    quotationNumberController.text = quot['quotation_number'] ?? "";
    selectedCustomerId.value = quot['customer_id']?.toString();
    taxPercent.value = (quot['tax_percent'] ??
            ((quot['tax'] ?? 0.0) / (quot['subtotal'] ?? 1.0) * 100))
        .toDouble();

    final List quotItems = quot['items'] ?? [];
    items.clear();
    for (var it in quotItems) {
      items.add(QuotationItem(
          description: it['description'] ?? "",
          quantity: (it['quantity'] ?? 1.0).toDouble(),
          unitPrice: (it['unit_price'] ?? 0.0).toDouble()));
    }
    advanceAmountController.text = (quot['advance_amount'] ?? 0.0).toString();
    paymentMode.value = quot['payment_mode'] ?? 'Cash';
    fetchCustomers();
    fetchProducts();
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
      debugPrint("Failed to fetch products: $e");
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
      debugPrint("Failed to fetch customers: $e");
    }
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get calculatedTax => subtotal * (taxPercent.value / 100);
  double get total => subtotal + calculatedTax;

  void addItem(String desc, double qty, double price) {
    items
        .add(QuotationItem(description: desc, quantity: qty, unitPrice: price));
  }

  void removeItem(int index) => items.removeAt(index);

  Future<void> updateQuotation() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomerId.value == null) {
      Utils.showSnackbar("Required", "Please select a customer");
      return;
    }
    if (items.isEmpty) {
      Utils.showSnackbar("Required", "Please add at least one item");
      return;
    }

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final payload = {
        "customer_id": selectedCustomerId.value,
        "quotation_number": quotationNumberController.text.trim(),
        "subtotal": subtotal,
        "tax": calculatedTax,
        "tax_percent": taxPercent.value,
        "total": total,
        "payment_mode": paymentMode.value,
        "advance_amount": double.tryParse(advanceAmountController.text) ?? 0.0,
        "creator_name": Get.find<UserInfoController>().myUser.value.name,
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.put('/business/quotations/$quotationId',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Quotation update queued offline. Will sync when online."
                : "Quotation Updated Successfully!",
            isError: false);
        if (Get.isRegistered<QuotationListController>()) {
          Get.find<QuotationListController>()
              .fetchQuotations(forceRefresh: true);
        }
        Get.back(); // back to detail
        Get.back(); // back to list (to refresh data)
      } else {
        Utils.showSnackbar("Error", "Failed to update: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception updating quotation: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
