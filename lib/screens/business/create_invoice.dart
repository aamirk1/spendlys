import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/controllers/user_info_controller.dart';

class InvoiceItem {
  String description;
  double quantity;
  double unitPrice;
  double get amount => quantity * unitPrice;

  InvoiceItem(
      {required this.description,
      required this.quantity,
      required this.unitPrice});

  Map<String, dynamic> toJson() => {
        "description": description,
        "quantity": quantity,
        "unit_price": unitPrice,
        "amount": amount
      };
}

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

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline ? "Invoice queued offline. Will sync when online." : "Invoice Generated!",
            isError: false);

        if (!isOffline) {
          // Resolve customer details for notifications
          final bodyData = jsonDecode(response.body);
          final invoiceId = bodyData['id']?.toString() ?? '';
          final selectedCustomer = customers.firstWhere(
            (c) => c['id'].toString() == selectedCustomerId.value,
            orElse: () => {'name': 'Customer', 'phone': ''},
          );
          final customerName = (selectedCustomer['name'] ?? 'Customer').toString();

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
        Utils.showSnackbar("Error", "Failed to generate invoice: ${response.body}");
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

class CreateInvoiceView extends StatelessWidget {
  const CreateInvoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateInvoiceController());
    const Color primaryColor = Color(0xFF5F33E1);
    const Color accentColor = Color(0xFFF3EFFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "New Invoice",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              controller.fetchQuotations();
              _showQuotationPicker(context, controller);
            },
            icon: const Icon(Icons.file_download_outlined, color: primaryColor, size: 18),
            label: const Text("Import",
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Obx(() => Stack(
              children: [
                Form(
                  key: controller.formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 40.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            _buildSectionTitle("Invoice Details"),
                            _buildCard(children: [
                              TextFormField(
                                controller: controller.invoiceNumberController,
                                validator: (v) => Validators.requiredField(v, "Invoice #"),
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                decoration: _inputDeco("Invoice Number", Icons.receipt_rounded),
                              ),
                              const SizedBox(height: 16),
                              // Due Date picker
                              StatefulBuilder(builder: (ctx, setSt) {
                                return InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: controller.selectedDueDate ??
                                          DateTime.now().add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2030),
                                      helpText: 'Select Invoice Due Date',
                                    );
                                    if (picked != null) {
                                      setSt(() => controller.selectedDueDate = picked);
                                      controller.dueDateController.text =
                                          '${picked.day}/${picked.month}/${picked.year}';
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: controller.selectedDueDate != null
                                              ? primaryColor.withOpacity(0.3)
                                              : Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded,
                                            color: controller.selectedDueDate != null
                                                ? primaryColor
                                                : Colors.grey.shade400,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          controller.selectedDueDate != null
                                              ? 'Due: ${controller.selectedDueDate!.day}/${controller.selectedDueDate!.month}/${controller.selectedDueDate!.year}'
                                              : 'Set Due Date (optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: controller.selectedDueDate != null
                                                ? Colors.black87
                                                : Colors.black54,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _showCustomerPicker(context, controller),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey.shade200)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_rounded, color: primaryColor, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          controller.customers.firstWhere(
                                              (c) => c['id'].toString() == controller.selectedCustomerId.value,
                                              orElse: () => {'name': 'Select Customer'})['name'] ??
                                              'Select Customer',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: controller.selectedCustomerId.value == null
                                                  ? Colors.black54
                                                  : Colors.black87),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Obx(() => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: controller.paymentMode.value,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                                        items: controller.paymentModes.map((String mode) {
                                          return DropdownMenuItem<String>(
                                            value: mode,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  mode == 'Cash'
                                                      ? Icons.money_rounded
                                                      : mode == 'Bank Transfer'
                                                          ? Icons.account_balance_rounded
                                                          : mode == 'Credit Card'
                                                              ? Icons.credit_card_rounded
                                                              : mode == 'UPI'
                                                                  ? Icons.qr_code_rounded
                                                                  : Icons.payment_rounded,
                                                  color: primaryColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(mode,
                                                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            controller.paymentMode.value = newValue;
                                          }
                                        },
                                      ),
                                    ),
                                  )),
                            ]),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle("Line Items"),
                                TextButton.icon(
                                  onPressed: () => _showAddItemSheet(context, controller),
                                  icon: const Icon(Icons.add_circle_outline, color: primaryColor, size: 18),
                                  label: const Text("Add Item",
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            if (controller.items.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text("No items added yet.",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            else
                              ...controller.items.asMap().entries.map((entry) {
                                int idx = entry.key;
                                InvoiceItem item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.01),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.description,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black87)),
                                            const SizedBox(height: 4),
                                            Text(
                                                "${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                          "₹${item.amount.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: primaryColor)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                        onPressed: () => controller.removeItem(idx),
                                      )
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),
                            _buildSectionTitle("Summary"),
                            _buildCard(
                              children: [
                                _summaryRow("Subtotal", controller.subtotal),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                        "Tax (${controller.taxPercent.value.toInt()}%) ",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                    Expanded(
                                      child: Slider(
                                        value: controller.taxPercent.value,
                                        min: 0,
                                        max: 28,
                                        divisions: 28,
                                        activeColor: primaryColor,
                                        inactiveColor: accentColor,
                                        label: "${controller.taxPercent.value.toInt()}%",
                                        onChanged: (v) => controller.taxPercent.value = v,
                                      ),
                                    ),
                                    Text(
                                        "₹${controller.calculatedTax.toStringAsFixed(2)}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  ],
                                ),
                                const Divider(height: 24),
                                _summaryRow("Total", controller.total, isTotal: true),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value ? null : controller.createInvoice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text("GENERATE INVOICE",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (controller.isLoading.value)
                  const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
              ],
            )),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black87 : Colors.grey.shade600)),
        Text("₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: isTotal ? const Color(0xFF5F33E1) : Colors.black87)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF5F33E1), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5)),
    );
  }

  void _showAddItemSheet(BuildContext context, CreateInvoiceController controller) {
    final tDesc = TextEditingController();
    final tQty = TextEditingController(text: "1");
    final tPrice = TextEditingController();
    final k = GlobalKey<FormState>();
    const Color primaryColor = Color(0xFF5F33E1);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
              child: SingleChildScrollView(
                child: Form(
                  key: k,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Add Item",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 16),
                      if (controller.products.isNotEmpty) ...[
                        TextFormField(
                          decoration: _inputDeco("Search Items...", Icons.search),
                          onChanged: (v) => controller.productSearchQuery.value = v,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: Obx(() {
                            final filtered = controller.filteredProducts;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final p = filtered[i];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    label: Text(p['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    onPressed: () {
                                      tDesc.text = p['name'];
                                      tPrice.text = p['price'].toString();
                                    },
                                    avatar: const Icon(Icons.inventory_2_outlined, size: 14, color: primaryColor),
                                    backgroundColor: const Color(0xFFF3EFFF),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: tDesc,
                        validator: (v) => Validators.requiredField(v, "Description"),
                        decoration: _inputDeco("Item Description", Icons.edit_rounded),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tQty,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                              ],
                              validator: (v) => Validators.requiredField(v, "Qty"),
                              decoration: _inputDeco("Qty", Icons.numbers_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: tPrice,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                              ],
                              validator: (v) => Validators.requiredField(v, "Price"),
                              decoration: _inputDeco("Unit Price (₹)", Icons.currency_rupee_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Obx(() => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Save to Inventory",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                            value: controller.saveToInventory.value,
                            activeColor: primaryColor,
                            onChanged: (v) => controller.saveToInventory.value = v ?? false,
                            controlAffinity: ListTileControlAffinity.leading,
                          )),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (k.currentState!.validate()) {
                              controller.addItem(
                                  tDesc.text.trim(),
                                  double.parse(tQty.text.trim()),
                                  double.parse(tPrice.text.trim()),
                                  controller.saveToInventory.value);
                              Get.back();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("ADD TO INVOICE",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ));
  }

  void _showCustomerPicker(BuildContext context, CreateInvoiceController controller) {
    controller.customerSearchQuery.value = '';
    final searchCtrl = TextEditingController();
    const Color primaryColor = Color(0xFF5F33E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Customer",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(
                      onPressed: () => _showAddCustomerForm(context, controller),
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: searchCtrl,
                onChanged: (v) => controller.customerSearchQuery.value = v,
                decoration: _inputDeco("Search Customers...", Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final filtered = controller.filteredCustomers;
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No customers found", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextButton(
                            onPressed: () => _showAddCustomerForm(context, controller),
                            child: const Text("Add New Customer", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final cust = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF3EFFF),
                        child: Text((cust['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(cust['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(cust['phone'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      onTap: () {
                        controller.selectedCustomerId.value = cust['id'].toString();
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerForm(BuildContext context, CreateInvoiceController controller) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Add New Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDeco("Customer Name", Icons.person_rounded),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco("Phone Number", Icons.phone_rounded),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        controller.quickAddCustomer(nameCtrl.text.trim(), phoneCtrl.text.trim());
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Close picker
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F33E1)),
                    child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ));
  }

  void _showQuotationPicker(BuildContext context, CreateInvoiceController controller) {
    const Color primaryColor = Color(0xFF5F33E1);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Import from Quotation",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.quotations.isEmpty) {
                  return Center(child: Text("No quotations found", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)));
                }
                return ListView.builder(
                  itemCount: controller.quotations.length,
                  itemBuilder: (c, i) {
                    final q = controller.quotations[i];
                    return ListTile(
                      title: Text(q['quotation_number'] ?? "QTN-???",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("Total: ₹${q['total']} | ${q['date']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: primaryColor, size: 20),
                      onTap: () {
                        controller.importFromQuotation(q);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
