import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/modules/business/views/quotation_list_view.dart';
import 'package:spendly/app/modules/business/models/quotation_item.dart';
import 'package:spendly/app/modules/business/controllers/edit_quotation_controller.dart';

class EditQuotationView extends StatelessWidget {
  const EditQuotationView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Utils.showSnackbar("Error", "Required data missing. Please try again.");
      });
      return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

    final Map<String, dynamic> quot = args;
    final controller = Get.put(EditQuotationController());
    controller.initData(quot);
    const Color primaryColor = Color(0xFF5F33E1);
    const Color accentColor = Color(0xFFF3EFFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Edit Quotation",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        centerTitle: true,
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
                            _buildSectionTitle("Quotation Details"),
                            _buildCard(children: [
                              TextFormField(
                                controller:
                                    controller.quotationNumberController,
                                validator: (v) =>
                                    Validators.requiredField(v, "Quote #"),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                                decoration: _inputDeco("Quotation Number",
                                    Icons.request_quote_rounded),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: controller.selectedCustomerId.value,
                                decoration: _inputDeco(
                                    "Select Customer", Icons.person_rounded),
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                                items: controller.customers.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['id'].toString(),
                                    child:
                                        Text(c['name'] ?? 'Unknown Customer'),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    controller.selectedCustomerId.value = val,
                                validator: (v) =>
                                    v == null ? 'Customer required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: controller.advanceAmountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d*'))
                                ],
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                                decoration: _inputDeco("Advance Amount (₹)",
                                    Icons.payments_outlined),
                              ),
                              const SizedBox(height: 16),
                              Obx(() => DropdownButtonFormField<String>(
                                    value: controller.paymentMode.value,
                                    decoration: _inputDeco(
                                        "Payment Mode", Icons.payment_rounded),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                    items: controller.paymentModes.map((mode) {
                                      return DropdownMenuItem<String>(
                                        value: mode,
                                        child: Text(mode),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        controller.paymentMode.value = val;
                                    },
                                  )),
                            ]),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle("Items list"),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showAddItemSheet(context, controller),
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: primaryColor, size: 18),
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
                                  border:
                                      Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 48, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text("No items added yet.",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            else
                              ...controller.items.asMap().entries.map((entry) {
                                int idx = entry.key;
                                QuotationItem item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.01),
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
                                      Text("₹${item.amount.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: primaryColor)),
                                      const SizedBox(width: 8),
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
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Expanded(
                                      child: Slider(
                                        value: controller.taxPercent.value,
                                        min: 0,
                                        max: 28,
                                        divisions: 28,
                                        activeColor: primaryColor,
                                        inactiveColor: accentColor,
                                        label:
                                            "${controller.taxPercent.value.toInt()}%",
                                        onChanged: (v) =>
                                            controller.taxPercent.value = v,
                                      ),
                                    ),
                                    Text(
                                        "₹${controller.calculatedTax.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black87)),
                                  ],
                                ),
                                const Divider(height: 24),
                                _summaryRow("Estimated Total", controller.total,
                                    isTotal: true),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.updateQuotation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text("SAVE CHANGES",
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor))),
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
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5)),
    );
  }

  void _showAddItemSheet(
      BuildContext context, EditQuotationController controller) {
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
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(22))),
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
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.products.length,
                            itemBuilder: (ctx, i) {
                              final p = controller.products[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(p['name'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                  onPressed: () {
                                    tDesc.text = p['name'];
                                    tPrice.text = p['price'].toString();
                                  },
                                  avatar: const Icon(Icons.inventory_2_outlined,
                                      size: 14, color: primaryColor),
                                  backgroundColor: const Color(0xFFF3EFFF),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: tDesc,
                        validator: (v) =>
                            Validators.requiredField(v, "Description"),
                        decoration:
                            _inputDeco("Item Description", Icons.edit_rounded),
                      ),
                      const SizedBox(height: 16),
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
                              decoration:
                                  _inputDeco("Qty", Icons.numbers_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              decoration: _inputDeco("Unit Price (₹)",
                                  Icons.currency_rupee_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
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
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("ADD ITEM",
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
