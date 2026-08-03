import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/modules/premium/controllers/payment_controller.dart';
import 'package:spendly/app/utils/business_export_helper.dart';
import 'package:spendly/app/common_widgets/premium_dialogs.dart';
import 'package:spendly/app/modules/business/views/inventory/add_product_view.dart';
import 'package:spendly/app/modules/business/views/inventory/barcode_scanner_view.dart';
import 'package:spendly/app/modules/business/controllers/inventory_controller.dart';

class InventoryListView extends StatelessWidget {
  const InventoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());
    final Color primaryColor = const Color(0xFF5F33E1);
    final Color bgLight = const Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          "Inventory Management",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        elevation: 0.5,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.black87),
            onPressed: () =>
                _showFilterSheet(context, controller, primaryColor),
          ),
          IconButton(
            icon:
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.black87),
            tooltip: "Export PDF",
            onPressed: () => _handleExport(context, controller, isPdf: true),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_rounded, color: Colors.black87),
            tooltip: "Export CSV",
            onPressed: () => _handleExport(context, controller, isPdf: false),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: () => controller.fetchProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Get.to(() => const AddProductScreen()),
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Product",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search Bar & Scan Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextFormField(
                        onChanged: (v) {
                          controller.searchQuery.value = v;
                        },
                        decoration: InputDecoration(
                          hintText: "Search products by name...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.qr_code_scanner_rounded,
                                    color: primaryColor),
                                tooltip: "Scan Barcode/QR to Search",
                                onPressed: () async {
                                  final scanned = await Get.to(
                                      () => const BarcodeScannerScreen());
                                  if (scanned != null &&
                                      scanned is String &&
                                      scanned.isNotEmpty) {
                                    controller.searchQuery.value = scanned;
                                    // Search matches
                                    final matches =
                                        controller.products.where((p) {
                                      return _getProductBarcode(p) == scanned;
                                    }).toList();

                                    if (matches.isEmpty) {
                                      Get.dialog(
                                        AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          title: const Text("Product Not Found",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          content: Text(
                                              "No product with barcode '$scanned' was found. Would you like to add it now?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: Text("Cancel",
                                                  style: TextStyle(
                                                      color: Colors
                                                          .grey.shade600)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.clearControllers();
                                                controller.barcodeController
                                                    .text = scanned;
                                                Get.to(() =>
                                                    const AddProductScreen());
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              child: const Text("Add Product",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dashboard Summary Stats Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() => Row(
                    children: [
                      _buildStatCard(
                          "Total Products",
                          "${controller.products.length}",
                          Icons.inventory_2_outlined,
                          primaryColor),
                      const SizedBox(width: 8),
                      _buildStatCard("Low Stock", "${controller.lowStockCount}",
                          Icons.warning_amber_rounded, Colors.orange.shade700),
                      const SizedBox(width: 8),
                      _buildStatCard(
                          "Stock Value",
                          "₹${controller.totalInventoryValue.toStringAsFixed(0)}",
                          Icons.currency_rupee_rounded,
                          Colors.green.shade700),
                    ],
                  )),
            ),
            const SizedBox(height: 12),

            Obx(() => (controller.minPriceFilter.value != null ||
                    controller.maxPriceFilter.value != null)
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (controller.minPriceFilter.value != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                  "Min: ₹${controller.minPriceFilter.value}",
                                  style: TextStyle(
                                      color: primaryColor, fontSize: 12)),
                              onDeleted: () =>
                                  controller.minPriceFilter.value = null,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.05),
                              deleteIconColor: primaryColor,
                              side: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        if (controller.maxPriceFilter.value != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                  "Max: ₹${controller.maxPriceFilter.value}",
                                  style: TextStyle(
                                      color: primaryColor, fontSize: 12)),
                              onDeleted: () =>
                                  controller.maxPriceFilter.value = null,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.05),
                              deleteIconColor: primaryColor,
                              side: BorderSide(
                                  color: primaryColor.withValues(alpha: 0.1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 4),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.products.isEmpty) {
                  return Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }
                if (controller.products.isEmpty &&
                    !controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 70,
                            color: primaryColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text("No products found.",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }
                final list = controller.filteredProducts;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("No items match your search.",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return AnimationLimiter(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                            .copyWith(bottom: 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final prod = list[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: _buildProductCard(
                                context, prod, controller, primaryColor),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(
      BuildContext context, InventoryController controller,
      {required bool isPdf}) async {
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog(
          message:
              "Exporting inventory details is a premium feature. Upgrade now to unlock professional branding and unlimited exports.");
      return;
    }

    if (controller.products.isEmpty) {
      Utils.showSnackbar("No Data", "There are no products to export.");
      return;
    }

    Utils.showLoadingDialog();

    try {
      if (isPdf) {
        final pdfData = await BusinessExportHelper.generatePdfData(
          type: BusinessExportType.inventory,
          data: controller.products,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showPrintPreview(
            pdfData, BusinessExportType.inventory);
      } else {
        final csvPath = await BusinessExportHelper.generateCsvFile(
          type: BusinessExportType.inventory,
          data: controller.products,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showShareSheet(
            csvPath, BusinessExportType.inventory);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Utils.showSnackbar("Error", "Export failed: $e");
    }
  }

  void _showFilterSheet(BuildContext context, InventoryController controller,
      Color primaryColor) {
    final minC = TextEditingController(
        text: controller.minPriceFilter.value?.toString() ?? "");
    final maxC = TextEditingController(
        text: controller.maxPriceFilter.value?.toString() ?? "");

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filter Inventory",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: minC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Min Price",
                        prefixIcon: const Icon(Icons.arrow_downward),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor))),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    controller: maxC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Max Price",
                        prefixIcon: const Icon(Icons.arrow_upward),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  controller.minPriceFilter.value =
                      double.tryParse(minC.text.trim());
                  controller.maxPriceFilter.value =
                      double.tryParse(maxC.text.trim());
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _getProductDescription(dynamic prod) {
    final String raw = prod['description'] ?? '';
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        return decoded['description'] ?? '';
      } catch (_) {}
    }
    return raw.isNotEmpty ? raw : 'No description';
  }

  String _getProductBarcode(dynamic prod) {
    final String raw = prod['description'] ?? '';
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        return decoded['barcode'] ?? '';
      } catch (_) {}
    }
    return '';
  }

  String _getProductImagePath(dynamic prod) {
    final String raw = prod['description'] ?? '';
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        return decoded['image_path'] ?? '';
      } catch (_) {}
    }
    return '';
  }

  double _getProductMinStock(dynamic prod) {
    final String raw = prod['description'] ?? '';
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        return double.tryParse(decoded['min_stock']?.toString() ?? '0') ?? 0.0;
      } catch (_) {}
    }
    return 0.0;
  }

  String _getProductCategory(dynamic prod) {
    final String raw = prod['description'] ?? '';
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        return decoded['category'] ?? 'Other';
      } catch (_) {}
    }
    return 'Other';
  }

  Widget _buildProductCard(BuildContext context, dynamic prod,
      InventoryController controller, Color primaryColor) {
    final String imgPath = _getProductImagePath(prod);
    Widget imageWidget;
    if (imgPath.isNotEmpty && File(imgPath).existsSync()) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imgPath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else {
      final String name = prod['name'] ?? 'Product';
      final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
      imageWidget = Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    final double qty =
        double.tryParse(prod['stock_quantity']?.toString() ?? '0') ?? 0.0;
    final double minStock = _getProductMinStock(prod);
    final bool isLowStock = qty <= minStock && minStock > 0;
    final String category = _getProductCategory(prod);
    final String barcode = _getProductBarcode(prod);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Row(
        children: [
          imageWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prod['name'] ?? 'Product',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getProductDescription(prod),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (barcode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      // Barcode icon/text
                      Icon(Icons.barcode_reader,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        barcode,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "₹${prod['price']}",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Stock: ${prod['stock_quantity']} ${prod['unit']}",
                        style: TextStyle(
                            fontSize: 10,
                            color: isLowStock
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text("Edit")),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
            onSelected: (val) {
              if (val == 'edit') {
                controller.setForEdit(prod);
                Get.to(() => AddProductScreen(productId: prod['id']));
              } else if (val == 'delete') {
                _confirmDelete(context, prod, controller);
              }
            },
          )
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, dynamic prod, InventoryController controller) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Delete Product?",
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(
          "Are you sure you want to remove '${prod['name']}' from inventory?"),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
        TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(prod['id']);
            },
            child: const Text("Delete",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ],
    ));
  }
}
