import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/reminder_notification_service.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/modules/business/models/quotation_item.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/profile/controllers/user_info_controller.dart';
import 'package:spendly/app/modules/business/controllers/invoice_list_controller.dart';

class EditInvoiceController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final customers = [].obs;
  final items = <QuotationItem>[].obs;
  final products = [].obs;

  final selectedCustomerId = Rxn<String>();
  final invoiceNumberController = TextEditingController();
  final dueDateController = TextEditingController();

  final taxPercent = 0.0.obs;

  final paymentMode = 'Cash'.obs;
  final paymentModes = ['Cash', 'Bank Transfer', 'Credit Card', 'UPI', 'Other'];

  final isLoading = false.obs;

  late String invoiceId;

  void initData(Map<String, dynamic> inv) {
    invoiceId = inv['id'];
    invoiceNumberController.text = inv['invoice_number'] ?? "";
    selectedCustomerId.value = inv['customer_id']?.toString();
    taxPercent.value =
        ((inv['tax'] ?? 0.0) / (inv['subtotal'] ?? 1.0) * 100).toDouble();

    if (inv['due_date'] != null) {
      dueDateController.text = inv['due_date'].toString().split(" ")[0];
    }
    paymentMode.value = inv['payment_mode'] ?? 'Cash';

    final List invItems = inv['items'] ?? [];
    items.clear();
    for (var it in invItems) {
      items.add(QuotationItem(
          description: it['description'] ?? "",
          quantity: (it['quantity'] ?? 1.0).toDouble(),
          unitPrice: (it['unit_price'] ?? 0.0).toDouble()));
    }
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

  Future<void> updateInvoice() async {
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
        "invoice_number": invoiceNumberController.text.trim(),
        "due_date":
            dueDateController.text.isNotEmpty ? dueDateController.text : null,
        "subtotal": subtotal,
        "tax": calculatedTax,
        "tax_percent": taxPercent.value,
        "total": total,
        "payment_mode": paymentMode.value,
        "status": "pending", // Keep status as pending or use existing
        "creator_name": Get.find<UserInfoController>().myUser.value.name,
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.put('/business/invoices/$invoiceId',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Invoice update queued offline. Will sync when online."
                : "Invoice Updated Successfully!",
            isError: false);

        if (!isOffline) {
          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            final dueDateStr = dueDateController.text.trim();
            DateTime? dueDate;
            if (dueDateStr.isNotEmpty) {
              dueDate = DateTime.tryParse(dueDateStr);
            }

            await reminderSvc.scheduleInvoiceNotifications(
              invoiceId: invoiceId,
              invoiceNumber: invoiceNumberController.text.trim(),
              total: total,
              customerName: customers.firstWhere(
                    (c) => c['id'].toString() == selectedCustomerId.value,
                    orElse: () => {'name': 'Customer'},
                  )['name'] ??
                  'Customer',
              dueDate: dueDate,
            );
          } catch (_) {}
        }

        if (Get.isRegistered<InvoiceListController>()) {
          Get.find<InvoiceListController>().fetchInvoices(refresh: true);
        }
        Get.back(); // back to detail
        Get.back(); // back to list
      } else {
        Utils.showSnackbar("Error", "Failed to update: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception updating invoice: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
