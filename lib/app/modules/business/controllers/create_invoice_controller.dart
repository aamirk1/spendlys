import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/reminder_notification_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/profile/controllers/user_info_controller.dart';
import 'package:spendly/app/modules/business/models/invoice_item.dart';

class CreateInvoiceController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final customers = [].obs;
  final items = <InvoiceItem>[].obs;
  final quotations = [].obs;
  final products = [].obs;

  final selectedCustomerId = Rxn<String>();
  final invoiceNumberController = TextEditingController();
  final dueDateController = TextEditingController();
  DateTime? selectedDueDate; // tracks the actual due date

  // Tax %
  final taxPercent = 0.0.obs;

  // Payment mode
  final paymentMode = 'Cash'.obs;
  final paymentModes = ['Cash', 'Bank Transfer', 'Credit Card', 'UPI', 'Other'];

  final isLoading = false.obs;

  // Search
  final customerSearchQuery = ''.obs;
  final productSearchQuery = ''.obs;
  final saveToInventory = false.obs;

  List get filteredCustomers => customers
      .where((c) => (c['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(customerSearchQuery.value.toLowerCase()))
      .toList();

  List get filteredProducts => products
      .where((p) => (p['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(productSearchQuery.value.toLowerCase()))
      .toList();

  @override
  void onInit() {
    super.onInit();
    invoiceNumberController.text =
        "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    fetchCustomers().then((_) {
      if (Get.arguments != null) {
        final arg = Get.arguments;
        String? custId;
        if (arg is Map) {
          custId = arg['id']?.toString() ?? arg['customer_id']?.toString();
        } else if (arg is String) {
          custId = arg;
        }
        if (custId != null) {
          selectedCustomerId.value = custId;
        }
      }
    });
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
      debugPrint("Failed to fetch quotations: $e");
    }
  }

  void importFromQuotation(Map<String, dynamic> quot) {
    try {
      // 1. Map Customer
      selectedCustomerId.value = quot['customer_id']?.toString();

      // 2. Map Tax
      taxPercent.value =
          double.tryParse(quot['tax_percent']?.toString() ?? '0') ?? 0.0;

      // 3. Map Items
      final rawItems = quot['items'];
      List<InvoiceItem> newItems = [];

      void processItem(dynamic i) {
        newItems.add(InvoiceItem(
            description: i['description']?.toString() ?? 'N/A',
            quantity: double.tryParse(i['quantity']?.toString() ?? '1') ?? 1.0,
            unitPrice:
                double.tryParse(i['unit_price']?.toString() ?? '0') ?? 0.0));
      }

      if (rawItems is List) {
        for (var i in rawItems) {
          processItem(i);
        }
      } else if (rawItems is String) {
        final List decoded = jsonDecode(rawItems);
        for (var i in decoded) {
          processItem(i);
        }
      }

      items.assignAll(newItems);
      Utils.showSnackbar(
          "Imported", "Data from quotation ${quot['quotation_number']} loaded.",
          isError: false);
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to parse quotation data: $e");
    }
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get calculatedTax => subtotal * (taxPercent.value / 100);
  double get total => subtotal + calculatedTax;

  void addItem(
      String desc, double qty, double price, bool shouldSaveToInventory) {
    items.add(InvoiceItem(description: desc, quantity: qty, unitPrice: price));
    if (shouldSaveToInventory) {
      _saveProductToInventory(desc, price);
    }
    update();
  }

  Future<void> _saveProductToInventory(String name, double price) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      await ApiService.post('/business/inventory/', headers: {
        'Content-Type': 'application/json',
        'x-user-id': userId
      }, body: {
        "name": name,
        "price": price,
        "stock_quantity": 0,
        "unit": ""
      });
      fetchProducts();
    } catch (e) {
      debugPrint("Failed to save product to inventory: $e");
    }
  }

  void removeItem(int index) => items.removeAt(index);

  Future<void> createInvoice() async {
    if (isLoading.value) return;
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomerId.value == null) {
      Utils.showSnackbar("Required", "Please select a customer");
      return;
    }
    if (items.isEmpty) {
      Utils.showSnackbar(
          "Required", "Please add at least one item to the invoice");
      return;
    }

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      String? creatorName;
      try {
        creatorName = Get.find<UserInfoController>().myUser.value.name;
      } catch (_) {}

      final payload = {
        "customer_id": selectedCustomerId.value,
        "invoice_number": invoiceNumberController.text.trim(),
        "subtotal": subtotal,
        "tax": calculatedTax,
        "tax_percent": taxPercent.value,
        "total": total,
        "due_date": selectedDueDate?.toIso8601String(),
        "payment_mode": paymentMode.value,
        "creator_name": creatorName,
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.post('/business/invoices',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline
                ? "Invoice queued offline. Will sync when online."
                : "Invoice Generated!",
            isError: false);

        if (!isOffline) {
          // Resolve customer details for notifications
          final bodyData = jsonDecode(response.body);
          final invoiceId = bodyData['id']?.toString() ?? '';
          final selectedCustomer = customers.firstWhere(
            (c) => c['id'].toString() == selectedCustomerId.value,
            orElse: () => {'name': 'Customer', 'phone': ''},
          );
          final customerName =
              (selectedCustomer['name'] ?? 'Customer').toString();

          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            await reminderSvc.scheduleInvoiceNotifications(
              invoiceId: invoiceId,
              invoiceNumber: invoiceNumberController.text.trim(),
              total: total,
              customerName: customerName,
              dueDate: selectedDueDate,
            );
          } catch (_) {}
        }

        Get.offNamed(RoutesName.invoiceList);
      } else {
        Utils.showSnackbar(
            "Error", "Failed to generate invoice: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception generating invoice: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> quickAddCustomer(String name, String phone) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.post('/business/customers',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: {"name": name, "phone": phone});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newCust = jsonDecode(response.body);
        await fetchCustomers();
        selectedCustomerId.value = newCust['id'].toString();
        Utils.showSnackbar("Success", "Customer $name added!", isError: false);
      }
    } catch (e) {
      debugPrint("Quick add customer failed: $e");
    }
  }
}
