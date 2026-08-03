import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/modules/business/models/quotation_item.dart';
import 'package:spendly/app/modules/business/controllers/create_quotation_controller.dart';

class CreateQuotationView extends StatelessWidget {
  const CreateQuotationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateQuotationController());
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
          "New Quotation",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
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
                                controller: controller.quotationNumberController,
                                validator: (v) => Validators.requiredField(v, "Quote #"),
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                decoration: _inputDeco("Quotation Number", Icons.request_quote_rounded),
                              ),
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
                              TextFormField(
                                controller: controller.advanceAmountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                                ],
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                decoration: _inputDeco("Advance Amount (₹)", Icons.payments_outlined),
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
                                _buildSectionTitle("Items list"),
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
                                QuotationItem item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade100),
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
                                _summaryRow("Estimated Total", controller.total, isTotal: true),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value ? null : controller.createQuotation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text("GENERATE QUOTATION",
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
              color: Colors.black.withValues(alpha: 0.01),
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

  void _showAddItemSheet(BuildContext context, CreateQuotationController controller) {
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
                          child: const Text("ADD TO QUOTATION",
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

  void _showCustomerPicker(BuildContext context, CreateQuotationController controller) {
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

  void _showAddCustomerForm(BuildContext context, CreateQuotationController controller) {
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
}
