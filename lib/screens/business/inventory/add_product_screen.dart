import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendly/screens/business/inventory/inventory_list_view.dart';
import 'package:spendly/screens/business/inventory/barcode_scanner_screen.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
        controller.hsnController.clear();
        controller.imagePath.value = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF5F33E1); // Premium Deep Purple/Indigo
    final Color accentColor = const Color(0xFFF3EFFF); // Light Purple background

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
                _buildSectionHeader("Product Image"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Obx(() {
                        final String imgPath = controller.imagePath.value;
                        final bool hasImage = imgPath.isNotEmpty && File(imgPath).existsSync();

                        return GestureDetector(
                          onTap: () => _showImagePickerSourceSheet(context, controller),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: hasImage ? Colors.white : accentColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryColor.withOpacity(0.15)),
                              image: hasImage
                                  ? DecorationImage(
                                      image: FileImage(File(imgPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: hasImage
                                ? Stack(
                                    children: [
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            controller.imagePath.value = "";
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined, color: primaryColor, size: 28),
                                      const SizedBox(height: 8),
                                      Text("Upload Image", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text("JPG, PNG (Max 2MB)", style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                                    ],
                                  ),
                          ),
                        );
                      }),
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
                            BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, color: primaryColor, size: 16),
                                const SizedBox(width: 6),
                                Text("Tip", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 12)),
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
                _buildSectionHeader("Product Details"),
                const SizedBox(height: 10),
                _buildCard([
                  _buildLabeledField(
                    label: "Product Name",
                    required: true,
                    child: _buildTextField(
                      controller: controller.nameController,
                      hintText: "Enter product name",
                      validator: (v) => Validators.requiredField(v, "Product Name"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          label: "Product Code (SKU)",
                          child: _buildTextField(
                            controller: controller.skuController,
                            hintText: "Enter product code",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: "Barcode (Optional)",
                          child: _buildTextField(
                            controller: controller.barcodeController,
                            hintText: "Scan or enter barcode",
                            suffixIcon: IconButton(
                              icon: Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 20),
                              onPressed: () async {
                                final scanned = await Get.to(() => const BarcodeScannerScreen());
                                if (scanned != null && scanned is String && scanned.isNotEmpty) {
                                  controller.barcodeController.text = scanned;
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledField(
                    label: "Category",
                    required: true,
                    child: _buildDropdownField(
                      controller: controller.categoryController,
                      items: ["Electronics", "Clothing", "Food", "Groceries", "Services", "Utilities", "Other"],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledField(
                    label: "Unit",
                    required: true,
                    child: _buildDropdownField(
                      controller: controller.unitController,
                      items: ["pcs", "kg", "box", "liter", "meter", "pack", "hours"],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledField(
                    label: "HSN / SAC (Optional)",
                    child: _buildTextField(
                      controller: controller.hsnController,
                      hintText: "Enter HSN or SAC code",
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // 3. Pricing & Stock Section
                _buildSectionHeader("Pricing & Stock"),
                const SizedBox(height: 10),
                _buildCard([
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          label: "Purchase Price (₹)",
                          required: true,
                          child: _buildTextField(
                            controller: controller.purchasePriceController,
                            hintText: "0.00",
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: "Selling Price (₹)",
                          required: true,
                          child: _buildTextField(
                            controller: controller.priceController,
                            hintText: "0.00",
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                            validator: (v) => Validators.requiredField(v, "Selling Price"),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          label: "Tax %",
                          child: _buildDropdownField(
                            controller: controller.taxController,
                            items: ["GST 0%", "GST 5%", "GST 12%", "GST 18%", "GST 28%", "Exempted"],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: "Opening Stock",
                          required: true,
                          child: _buildTextField(
                            controller: controller.qtyController,
                            hintText: "0",
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledField(
                    label: "Minimum Stock Alert",
                    infoIcon: Icon(Icons.info_outline_rounded, color: primaryColor, size: 16),
                    child: _buildTextField(
                      controller: controller.minStockController,
                      hintText: "Enter minimum stock level",
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // 4. Additional Information
                _buildSectionHeader("Additional Information (Optional)"),
                const SizedBox(height: 10),
                _buildCard([
                  _buildLabeledField(
                    label: "Description",
                    child: TextFormField(
                      controller: controller.descController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: "Enter product description",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(16),
                      ),
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
                          controller.hsnController.clear();
                          controller.imagePath.value = "";
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

  void _showImagePickerSourceSheet(BuildContext context, InventoryController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Product Image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF3EFFF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF5F33E1)),
                ),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Get.back();
                  controller.pickProductImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF3EFFF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF5F33E1)),
                ),
                title: const Text("Take a Photo"),
                onTap: () {
                  Get.back();
                  controller.pickProductImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    bool required = false,
    Widget? infoIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (required)
              const Text(
                " *",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (infoIcon != null) ...[
              const SizedBox(width: 4),
              infoIcon,
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
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
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required List<String> items,
  }) {
    if (controller.text.isEmpty && items.isNotEmpty) {
      controller.text = items.first;
    }
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty && items.contains(controller.text) ? controller.text : items.first,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (val) {
        if (val != null) {
          controller.text = val;
        }
      },
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
