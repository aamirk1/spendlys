import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
import 'package:spendly/services/whatsapp_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
        for (var i in rawItems) processItem(i);
      } else if (rawItems is String) {
        final List decoded = jsonDecode(rawItems);
        for (var i in decoded) processItem(i);
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

  void addItem(String desc, double qty, double price) {
    items.add(InvoiceItem(description: desc, quantity: qty, unitPrice: price));
    if (saveToInventory.value) {
      _saveProductToInventory(desc, price);
      saveToInventory.value = false;
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
      final payload = {
        "customer_id": selectedCustomerId.value,
        "invoice_number": invoiceNumberController.text.trim(),
        "subtotal": subtotal,
        "tax": calculatedTax,
        "tax_percent": taxPercent.value,
        "total": total,
        "due_date": selectedDueDate?.toIso8601String(),
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.post('/business/invoices',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Invoice Generated!", isError: false);

        // Resolve customer details for notifications
        final invoiceId = jsonDecode(response.body)['id']?.toString() ?? '';
        final selectedCustomer = customers.firstWhere(
          (c) => c['id'].toString() == selectedCustomerId.value,
          orElse: () => {'name': 'Customer', 'phone': ''},
        );
        final customerName = selectedCustomer['name'] as String? ?? 'Customer';
        final customerPhone = selectedCustomer['phone'] as String? ?? '';

        // ── Local push + due-date reminders ───────────────────────────
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

  Future<void> quickAddCustomer(String name) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.post('/business/customers',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: {"name": name});
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Invoice",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              controller.fetchQuotations();
              _showQuotationPicker(context, controller);
            },
            icon: const Icon(Icons.file_download_outlined, color: Colors.green),
            label: const Text("Import",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: SafeArea(
          child: Obx(() => Stack(
                children: [
                  Form(
                    key: controller.formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10)
                          .copyWith(bottom: 100),
                      child: AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 600),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 60.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              _buildSectionTitle("Invoice Details"),
                              _buildCard(children: [
                                TextFormField(
                                  controller:
                                      controller.invoiceNumberController,
                                  validator: (v) =>
                                      Validators.requiredField(v, "Invoice #"),
                                  decoration: _inputDeco(
                                      "Invoice Number", Icons.receipt_rounded),
                                ),
                                 const SizedBox(height: 15),
                                // Due Date picker
                                StatefulBuilder(builder: (ctx, setSt) {
                                  return InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: controller.selectedDueDate ??
                                            DateTime.now()
                                                .add(const Duration(days: 30)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2030),
                                        helpText: 'Select Invoice Due Date',
                                      );
                                      if (picked != null) {
                                        setSt(() =>
                                            controller.selectedDueDate = picked);
                                        controller.dueDateController.text =
                                            '${picked.day}/${picked.month}/${picked.year}';
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                            color: controller.selectedDueDate !=
                                                    null
                                                ? Colors.green.shade400
                                                : Colors.green.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded,
                                              color: controller.selectedDueDate !=
                                                      null
                                                  ? Colors.green.shade600
                                                  : Colors.grey),
                                          const SizedBox(width: 12),
                                          Text(
                                            controller.selectedDueDate != null
                                                ? 'Due: ${controller.selectedDueDate!.day}/${controller.selectedDueDate!.month}/${controller.selectedDueDate!.year}'
                                                : 'Set Due Date (optional)',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: controller.selectedDueDate !=
                                                      null
                                                  ? Colors.black87
                                                  : Colors.black54,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.chevron_right,
                                              color: Colors.black38),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 15),
                                InkWell(
                                  onTap: () =>
                                      _showCustomerPicker(context, controller),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 15),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                            color: Colors.green.shade100)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_rounded,
                                            color: Colors.green.shade600),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            controller.customers.firstWhere(
                                                    (c) =>
                                                        c['id'].toString() ==
                                                        controller
                                                            .selectedCustomerId
                                                            .value,
                                                    orElse: () => {
                                                          'name':
                                                              'Select Customer'
                                                        })['name'] ??
                                                'Select Customer',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: controller
                                                            .selectedCustomerId
                                                            .value ==
                                                        null
                                                    ? Colors.black54
                                                    : Colors.black87),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down,
                                            color: Colors.black54),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle("Line Items"),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showAddItemSheet(context, controller),
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.green),
                                    label: const Text("Add Item",
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              if (controller.items.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 50,
                                          color: Colors.green.shade300),
                                      const SizedBox(height: 10),
                                      const Text("No items added.",
                                          style:
                                              TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                )
                              else
                                ...controller.items
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  InvoiceItem item = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.description,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  "${item.quantity} x ₹${item.unitPrice}",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                            "₹${item.amount.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.green)),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.redAccent,
                                              size: 20),
                                          onPressed: () =>
                                              controller.removeItem(idx),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 30),
                              _buildSectionTitle("Summary"),
                              _buildCard(
                                children: [
                                  _summaryRow("Subtotal", controller.subtotal),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                          "Tax (${controller.taxPercent.value.toInt()}%) ",
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Slider(
                                          value: controller.taxPercent.value,
                                          min: 0,
                                          max: 28,
                                          divisions: 28,
                                          activeColor: Colors.green,
                                          label:
                                              "${controller.taxPercent.value.toInt()}%",
                                          onChanged: (v) =>
                                              controller.taxPercent.value = v,
                                        ),
                                      ),
                                      Text(
                                          "₹${controller.calculatedTax.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  _summaryRow("Total", controller.total,
                                      isTotal: true),
                                ],
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.createInvoice,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 8,
                                    shadowColor: Colors.green.withOpacity(0.4),
                                  ),
                                  child: const Text("GENERATE INVOICE",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2)),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green))),
                ],
              )),
        ),
      ),
    );
  }

  void _showCustomerPicker(
      BuildContext context, CreateInvoiceController controller) {
    controller.customerSearchQuery.value = '';
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Customer",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  IconButton(
                      onPressed: () =>
                          _showAddCustomerForm(context, controller),
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: searchCtrl,
                onChanged: (v) => controller.customerSearchQuery.value = v,
                decoration: _inputDeco("Search Customers...", Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final filtered = controller.filteredCustomers;
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No customers found."),
                        TextButton(
                            onPressed: () =>
                                _showAddCustomerForm(context, controller),
                            child: const Text("Add New Customer")),
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
                        backgroundColor: Colors.green.shade50,
                        child: Text(cust['name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.green)),
                      ),
                      title: Text(cust['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(cust['phone'] ?? ''),
                      onTap: () {
                        controller.selectedCustomerId.value =
                            cust['id'].toString();
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

  void _showAddCustomerForm(
      BuildContext context, CreateInvoiceController controller) {
    final nameCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Add New Customer"),
              content: TextFormField(
                controller: nameCtrl,
                decoration: _inputDeco("Customer Name", Icons.person),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        controller.quickAddCustomer(nameCtrl.text.trim());
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Close picker
                      }
                    },
                    child: const Text("Add")),
              ],
            ));
  }

  void _showQuotationPicker(
      BuildContext context, CreateInvoiceController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text("Import from Quotation",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 15),
            Expanded(
              child: Obx(() {
                if (controller.quotations.isEmpty) {
                  return const Center(child: Text("No quotations found."));
                }
                return ListView.builder(
                  itemCount: controller.quotations.length,
                  itemBuilder: (c, i) {
                    final q = controller.quotations[i];
                    return ListTile(
                      title: Text(q['quotation_number'] ?? "QTN-???",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Total: ₹${q['total']} | ${q['date']}"),
                      trailing: const Icon(Icons.chevron_right),
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

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black87 : Colors.black54)),
        Text("₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize: isTotal ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.green.shade700 : Colors.black87)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.green.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: Colors.green.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
    );
  }

  void _showAddItemSheet(
      BuildContext context, CreateInvoiceController controller) {
    final tDesc = TextEditingController();
    final tQty = TextEditingController(text: "1");
    final tPrice = TextEditingController();
    final k = GlobalKey<FormState>();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 25,
                  right: 25,
                  top: 25),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25))),
              child: SingleChildScrollView(
                child: Form(
                  key: k,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Add Item",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 20),
                      if (controller.products.isNotEmpty) ...[
                        const Text("Select from Inventory",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDeco("Search Items...", Icons.search),
                          onChanged: (v) =>
                              controller.productSearchQuery.value = v,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 60,
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
                                    label: Text(p['name']),
                                    onPressed: () {
                                      tDesc.text = p['name'];
                                      tPrice.text = p['price'].toString();
                                    },
                                    avatar: const Icon(Icons.inventory_2_outlined,
                                        size: 16),
                                    backgroundColor: Colors.green.shade50,
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 15),
                        const Divider(),
                        const SizedBox(height: 15),
                      ],
                      TextFormField(
                        controller: tDesc,
                        validator: (v) =>
                            Validators.requiredField(v, "Description"),
                        decoration: _inputDeco("Item Description", Icons.edit),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: tQty,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'))
                              ],
                              validator: (v) =>
                                  Validators.requiredField(v, "Qty"),
                              decoration: _inputDeco("Qty", Icons.numbers),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: tPrice,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d*'))
                              ],
                              validator: (v) =>
                                  Validators.requiredField(v, "Price"),
                              decoration: _inputDeco(
                                  "Unit Price (₹)", Icons.currency_rupee),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (k.currentState!.validate()) {
                              controller.addItem(
                                  tDesc.text.trim(),
                                  double.parse(tQty.text.trim()),
                                  double.parse(tPrice.text.trim()));
                              Get.back();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("ADD TO INVOICE",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ));
  }
}
