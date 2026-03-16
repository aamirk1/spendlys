import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class QuotationItem {
  String description;
  double quantity;
  double unitPrice;
  double get amount => quantity * unitPrice;

  QuotationItem({required this.description, required this.quantity, required this.unitPrice});

  Map<String, dynamic> toJson() => {
    "description": description,
    "quantity": quantity,
    "unit_price": unitPrice,
    "amount": amount
  };
}

class CreateQuotationController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  final customers = [].obs;
  final items = <QuotationItem>[].obs;
  
  final selectedCustomerId = Rxn<String>();
  final quotationNumberController = TextEditingController();
  
  final taxPercent = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    quotationNumberController.text = "QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    String? userId = _auth.currentUser?.uid;
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

  Future<void> createQuotation() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomerId.value == null) {
      Utils.showSnackbar("Required", "Please select a customer");
      return;
    }
    if (items.isEmpty) {
      Utils.showSnackbar("Required", "Please add at least one item to the quotation");
      return;
    }

    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final payload = {
        "customer_id": selectedCustomerId.value,
        "quotation_number": quotationNumberController.text.trim(),
        "subtotal": subtotal,
        "tax": calculatedTax,
        "total": total,
        "items": items.map((i) => i.toJson()).toList()
      };

      final response = await ApiService.post(
        '/business/quotations',
        headers: {'Content-Type': 'application/json', 'x-user-id': userId},
        body: payload
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Quotation Generated Successfully!", isError: false);
        Get.back(); // return to previous screen
      } else {
        Utils.showSnackbar("Error", "Failed to generate quotation: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception generating quotation: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

class CreateQuotationView extends StatelessWidget {
  const CreateQuotationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateQuotationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Quotation", style: TextStyle(fontWeight: FontWeight.bold)),
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
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
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
                          _buildSectionTitle("Quotation Info"),
                          _buildCard(
                            children: [
                              TextFormField(
                                controller: controller.quotationNumberController,
                                validator: (v) => Validators.requiredField(v, "Quote #"),
                                decoration: _inputDeco("Quotation Number", Icons.request_quote_rounded),
                              ),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                value: controller.selectedCustomerId.value,
                                decoration: _inputDeco("Select Customer", Icons.person_rounded),
                                items: controller.customers.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['id'].toString(),
                                    child: Text(c['name'] ?? 'Unknown Customer', style: const TextStyle(fontSize: 15)),
                                  );
                                }).toList(),
                                onChanged: (val) => controller.selectedCustomerId.value = val,
                                validator: (v) => v == null ? 'Customer required' : null,
                              ),
                            ]
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle("Quotation Items"),
                              TextButton.icon(
                                onPressed: () => _showAddItemSheet(context, controller),
                                icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                                label: const Text("Add Item", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
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
                                border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1, style: BorderStyle.none),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.category_outlined, size: 50, color: Colors.teal.shade300),
                                  const SizedBox(height: 10),
                                  const Text("No items added.", style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                            )
                          else
                            ...controller.items.asMap().entries.map((entry) {
                              int idx = entry.key;
                              QuotationItem item = entry.value;
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
                                          Text("${item.quantity} x ₹${item.unitPrice}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Text("₹${item.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => controller.removeItem(idx),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),

                          const SizedBox(height: 30),
                          _buildSectionTitle("Summary"),
                          _buildCard(
                            children: [
                              _summaryRow("Subtotal", controller.subtotal),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text("Tax (%) ", style: TextStyle(color: Colors.black54, fontSize: 14)),
                                  Expanded(
                                    child: Slider(
                                      value: controller.taxPercent.value,
                                      min: 0,
                                      max: 28,
                                      divisions: 28,
                                      activeColor: Colors.teal,
                                      label: "${controller.taxPercent.value.toInt()}%",
                                      onChanged: (v) => controller.taxPercent.value = v,
                                    ),
                                  ),
                                  Text("₹${controller.calculatedTax.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 30),
                              _summaryRow("Estimated Total", controller.total, isTotal: true),
                            ],
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value ? null : controller.createQuotation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade500,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 8,
                                shadowColor: Colors.teal.withOpacity(0.4),
                              ),
                              child: const Text("GENERATE QUOTATION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal))),
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
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black87 : Colors.black54)),
        Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.bold, color: isTotal ? Colors.teal.shade700 : Colors.black87)),
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
          color: Colors.teal.shade800,
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
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.08), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: Colors.teal.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.teal.shade600, width: 2)),
    );
  }

  void _showAddItemSheet(BuildContext context, CreateQuotationController controller) {
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
              const Text("Add Item", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),
              TextFormField(
                controller: tDesc,
                validator: (v) => Validators.requiredField(v, "Description"),
                decoration: _inputDeco("Item Description", Icons.edit),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: tQty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      validator: (v) => Validators.requiredField(v, "Qty"),
                      decoration: _inputDeco("Qty", Icons.numbers),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: tPrice,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      validator: (v) => Validators.requiredField(v, "Price"),
                      decoration: _inputDeco("Unit Price (₹)", Icons.currency_rupee),
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
                        double.parse(tPrice.text.trim())
                      );
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("ADD TO QUOTATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )
    );
  }
}
