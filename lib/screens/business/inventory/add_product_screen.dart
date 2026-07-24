import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/screens/business/inventory/inventory_list_view.dart';
import 'package:spendly/utils/validators.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId;
  const AddProductScreen({this.productId, super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final controller = Get.find<InventoryController>();

  @override
  void initState() {
    super.initState();
    // If not editing, clear controllers
    if (widget.productId == null) {
      // Clear controllers using a post frame callback to avoid build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // We call clear manually since clearControllers is private or we can access it
        controller.nameController.clear();
        controller.descController.clear();
        controller.priceController.clear();
        controller.qtyController.text = "0";
        controller.unitController.text = "pcs";
        controller.skuController.clear();
        controller.barcodeController.clear();
        controller.categoryController.clear();
        controller.purchasePriceController.clear();
        controller.taxController.clear();
        controller.minStockController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF5F33E1); // Premium Deep Purple/Indigo
    final Color accentColor = const Color(0xFFF3EFFF); // Light Purple background
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productId == null ? "Add Product" : "Edit Product",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              widget.productId == null ? "Add a new product to your inventory" : "Update product information",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10.0, bottom: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => controller.saveProduct(productId: widget.productId),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
              label: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Product Image Section
                _buildSectionHeader("Product Image", textTheme),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.15)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: primaryColor, size: 32),
                            const SizedBox(height: 8),
                            Text("Upload Image", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("JPG, PNG (Max 2MB)", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, color: primaryColor, size: 18),
                                const SizedBox(width: 6),
                                Text("Tip", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Add a product image to easily identify your product",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Product Details Section
                _buildSectionHeader("Product Details", textTheme),
                const SizedBox(height: 10),
                _buildCard([
                  _buildTextField(
                    controller: controller.nameController,
                    label: "Product Name",
                    icon: CupertinoIcons.tag,
                    required: true,
                    validator: (v) => Validators.requiredField(v, "Product Name"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: controller.skuController,
                          label: "Product Code (SKU)",
                          icon: Icons.qr_code_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: controller.barcodeController,
                          label: "Barcode (Optional)",
                          icon: Icons.barcode_reader,
                          suffixIcon: Icon(Icons.document_scanner_outlined, color: primaryColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    controller: controller.categoryController,
                    label: "Category",
                    icon: Icons.category_outlined,
                    items: ["Electronics", "Clothing", "Food", "Groceries", "Services", "Utilities", "Other"],
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    controller: controller.unitController,
                    label: "Unit",
                    icon: Icons.straighten_rounded,
                    items: ["pcs", "kg", "box", "liter", "meter", "pack", "hours"],
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.descController,
                    label: "HSN / SAC (Optional)",
                    icon: Icons.text_snippet_outlined,
                  ),
                ]),
                const SizedBox(height: 24),

                // 3. Pricing & Stock Section
                _buildSectionHeader("Pricing & Stock", textTheme),
                const SizedBox(height: 10),
                _buildCard([
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: controller.purchasePriceController,
                          label: "Purchase Price (₹)",
                          icon: Icons.shopping_bag_outlined,
                          required: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: controller.priceController,
                          label: "Selling Price (₹)",
                          icon: Icons.currency_rupee_rounded,
                          required: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          validator: (v) => Validators.requiredField(v, "Selling Price"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          controller: controller.taxController,
                          label: "Tax %",
                          icon: Icons.percent_rounded,
                          items: ["GST 0%", "GST 5%", "GST 12%", "GST 18%", "GST 28%", "Exempted"],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: controller.qtyController,
                          label: "Opening Stock",
                          icon: Icons.inventory_2_outlined,
                          required: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.minStockController,
                    label: "Minimum Stock Alert",
                    icon: Icons.warning_amber_rounded,
                    suffixIcon: Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ]),
                const SizedBox(height: 24),

                // 4. Additional Information
                _buildSectionHeader("Additional Information (Optional)", textTheme),
                const SizedBox(height: 10),
                _buildCard([
                  TextFormField(
                    controller: controller.descController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: "Enter product description",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ]),
                const SizedBox(height: 30),

                // 5. Bottom Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Clear manually
                          controller.nameController.clear();
                          controller.descController.clear();
                          controller.priceController.clear();
                          controller.qtyController.text = "0";
                          controller.unitController.text = "pcs";
                          controller.skuController.clear();
                          controller.barcodeController.clear();
                          controller.categoryController.clear();
                          controller.purchasePriceController.clear();
                          controller.taxController.clear();
                          controller.minStockController.clear();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text("Reset", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.saveProduct(productId: widget.productId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shadowColor: primaryColor.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text("Save Product", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF5F33E1).withOpacity(0.7), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    bool required = false,
  }) {
    if (controller.text.isEmpty && items.isNotEmpty) {
      controller.text = items.first;
    }
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty && items.contains(controller.text) ? controller.text : items.first,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (val) {
        if (val != null) {
          controller.text = val;
        }
      },
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF5F33E1).withOpacity(0.7), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
