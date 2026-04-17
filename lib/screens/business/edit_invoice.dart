import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/screens/business/invoice_list.dart';
import 'package:spendly/screens/business/create_quotation.dart' show QuotationItem;

class EditInvoiceController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final customers = [].obs;
  final items = <QuotationItem>[].obs;
  final products = [].obs;
  
  final selectedCustomerId = Rxn<String>();
  final invoiceNumberController = TextEditingController();
  final dueDateController = TextEditingController();
  
  final taxPercent = 0.0.obs;
  final isLoading = false.obs;
  
  late String invoiceId;

  void initData(Map<String, dynamic> inv) {
    invoiceId = inv['id'];
    invoiceNumberController.text = inv['invoice_number'] ?? "";
    selectedCustomerId.value = inv['customer_id']?.toString();
    taxPercent.value = (inv['tax'] ?? 0.0) / (inv['subtotal'] ?? 1.0) * 100;
    
    if (inv['due_date'] != null) {
      dueDateController.text = inv['due_date'].toString().split(" ")[0];
    }
    
    final List invItems = inv['items'] ?? [];
    items.clear();
    for (var it in invItems) {
      items.add(QuotationItem(
        description: it['description'] ?? "",
        quantity: (it['quantity'] ?? 1.0).toDouble(),
        unitPrice: (it['unit_price'] ?? 0.0).toDouble()
      ));
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
      final response = await ApiService.get('/business/customers', headers: {'x-user-id': userId});
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
    items.add(QuotationItem(description: desc, quantity: qty, unitPrice: price));
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
        "due_date": dueDateController.text.isNotEmpty ? dueDateController.text : null,
        "subtotal": subtotal,
        "tax": calculatedTax,
        "tax_percent": taxPercent.value,
        "total": total,
        "status": "pending", // Keep status as pending or use existing
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.put(
        '/business/invoices/$invoiceId',
        headers: {'Content-Type': 'application/json', 'x-user-id': userId},
        body: payload
      );

      if (response.statusCode == 200) {
        Utils.showSnackbar("Success", "Invoice Updated Successfully!", isError: false);
        if (Get.isRegistered<InvoiceListController>()) {
          Get.find<InvoiceListController>().fetchInvoices();
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

class EditInvoiceView extends StatelessWidget {
  const EditInvoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Utils.showSnackbar("Error", "Required data missing. Please try again.");
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Map<String, dynamic> inv = args;
    final controller = Get.put(EditInvoiceController());
    controller.initData(inv);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Invoice", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: SafeArea(
          child: Obx(() => Stack(
            children: [
              Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 100),
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
                          _buildSectionTitle("Invoice Info"),
                          _buildCard(
                            children: [
                              TextFormField(
                                controller: controller.invoiceNumberController,
                                validator: (v) => Validators.requiredField(v, "Invoice #"),
                                decoration: _inputDeco("Invoice Number", Icons.receipt_long),
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                initialValue: controller.selectedCustomerId.value,
                                decoration: _inputDeco("Select Customer", Icons.person_rounded),
                                items: controller.customers.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['id'].toString(),
                                    child: Text(c['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15)),
                                  );
                                }).toList(),
                                onChanged: (val) => controller.selectedCustomerId.value = val,
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: controller.dueDateController,
                                readOnly: true,
                                onTap: () async {
                                  DateTime? d = await showDatePicker(
                                    context: context, 
                                    initialDate: DateTime.now(), 
                                    firstDate: DateTime.now(), 
                                    lastDate: DateTime.now().add(const Duration(days: 365))
                                  );
                                  if (d!=null) controller.dueDateController.text = d.toString().split(" ")[0];
                                },
                                decoration: _inputDeco("Due Date", Icons.calendar_today),
                              ),
                            ]
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle("Invoice Items"),
                              TextButton.icon(
                                onPressed: () => _showAddItemSheet(context, controller),
                                icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                                label: const Text("Add Item", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          if (controller.items.isEmpty)
                            const Center(child: Text("No items added."))
                          else
                            ...controller.items.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var item = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text("${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Text("₹${item.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => controller.removeItem(idx),
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
                                  Text("Tax (${controller.taxPercent.value.toInt()}%) ", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                                  Expanded(
                                    child: Slider(
                                      value: controller.taxPercent.value,
                                      min: 0,
                                      max: 28,
                                      divisions: 28,
                                      activeColor: Colors.indigo,
                                      label: "${controller.taxPercent.value.toInt()}%",
                                      onChanged: (v) => controller.taxPercent.value = v,
                                    ),
                                  ),
                                  Text("₹${controller.calculatedTax.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 30),
                              _summaryRow("Grand Total", controller.total, isTotal: true),
                            ],
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value ? null : controller.updateInvoice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade500,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("UPDATE INVOICE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator()),
            ],
          )),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.bold, color: isTotal ? Colors.indigo.shade700 : Colors.black87)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.indigo.shade800)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  void _showAddItemSheet(BuildContext context, EditInvoiceController controller) {
    final tDesc = TextEditingController();
    final tQty = TextEditingController(text: "1");
    final tPrice = TextEditingController();
    final k = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                      color: Colors.indigo)),
              const SizedBox(height: 20),
              if (controller.products.isNotEmpty) ...[
                const Text("Select from Inventory",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const SizedBox(height: 10),
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.products.length,
                    itemBuilder: (ctx, i) {
                      final p = controller.products[i];
                      return ActionChip(
                        label: Text(p['name']),
                        onPressed: () {
                          tDesc.text = p['name'];
                          tPrice.text = p['price'].toString();
                        },
                        avatar:
                            const Icon(Icons.inventory_2_outlined, size: 16),
                        backgroundColor: Colors.indigo.shade50,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
              ],
              TextFormField(
                  controller: tDesc,
                  validator: (v) => Validators.requiredField(v, "Description"),
                  decoration: _inputDeco("Description", Icons.edit)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: tQty,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco("Qty", Icons.numbers))),
                  const SizedBox(width: 15),
                  Expanded(
                      child: TextFormField(
                          controller: tPrice,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco("Price", Icons.currency_rupee))),
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
                      backgroundColor: Colors.indigo.shade500),
                  child: const Text("ADD ITEM",
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
