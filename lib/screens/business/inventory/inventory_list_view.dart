import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/utils/business_export_helper.dart';
import 'package:spendly/widgets/premium_dialogs.dart';
import 'package:spendly/screens/business/inventory/add_product_screen.dart';

class InventoryController extends GetxController {
  final products = [].obs;
  final isLoading = false.obs;

  // For adding/editing
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController(text: "0");
  final unitController = TextEditingController(text: "pcs");
  
  // Custom mockup fields
  final skuController = TextEditingController();
  final barcodeController = TextEditingController();
  final categoryController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final taxController = TextEditingController();
  final minStockController = TextEditingController();

  // Search and Filter
  final searchQuery = ''.obs;
  final minPriceFilter = Rxn<double>();
  final maxPriceFilter = Rxn<double>();

  List get filteredProducts {
    return products.where((p) {
      final matchesSearch = (p['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase());

      bool matchesPrice = true;
      if (minPriceFilter.value != null) {
        matchesPrice = (p['price'] ?? 0.0) >= minPriceFilter.value!;
      }
      if (matchesPrice && maxPriceFilter.value != null) {
        matchesPrice = (p['price'] ?? 0.0) <= maxPriceFilter.value!;
      }

      return matchesSearch && matchesPrice;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/business/inventory/?';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      products.value = List<Map<String, dynamic>>.from(cachedData);
      return;
    }

    if (cachedData != null && cachedData is List) {
      products.value = List<Map<String, dynamic>>.from(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      String url = '/business/inventory/?';
      if (searchQuery.value.isNotEmpty) url += 'search=${searchQuery.value}&';
      if (minPriceFilter.value != null)
        url += 'min_price=${minPriceFilter.value}&';
      if (maxPriceFilter.value != null)
        url += 'max_price=${maxPriceFilter.value}&';

      final response =
          await ApiService.get(url, headers: {'x-user-id': userId});
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          products.value = jsonDecode(response.body);
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load inventory: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProduct({String? productId}) async {
    if (!formKey.currentState!.validate()) return;

    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.back(); // Close screen/sheet
    isLoading.value = true;
    try {
      final extraData = {
        "description": descController.text.trim(),
        "sku": skuController.text.trim(),
        "barcode": barcodeController.text.trim(),
        "category": categoryController.text.trim(),
        "purchase_price": double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
        "tax": taxController.text.trim(),
        "min_stock": double.tryParse(minStockController.text.trim()) ?? 0.0,
      };

      final payload = {
        "name": nameController.text.trim(),
        "description": jsonEncode(extraData),
        "price": double.tryParse(priceController.text.trim()) ?? 0.0,
        "stock_quantity": double.tryParse(qtyController.text.trim()) ?? 0.0,
        "unit": unitController.text.trim(),
      };

      if (productId == null) {
        // Add
        final response = await ApiService.post('/business/inventory/',
            headers: {'Content-Type': 'application/json', 'x-user-id': userId},
            body: payload);
        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 202) {
          final isOffline = response.statusCode == 202;
          Utils.showSnackbar(
              isOffline ? "Offline" : "Success",
              isOffline
                  ? "Product queued offline. Will sync when online."
                  : "Product added to inventory",
              isError: false);
          _clearControllers();
          fetchProducts(forceRefresh: true);
        } else {
          Utils.showSnackbar(
              "Error", "Failed to add product: ${response.body}");
        }
      } else {
        // Update
        final response = await ApiService.put('/business/inventory/$productId',
            headers: {'Content-Type': 'application/json', 'x-user-id': userId},
            body: payload);
        if (response.statusCode == 200 || response.statusCode == 202) {
          final isOffline = response.statusCode == 202;
          Utils.showSnackbar(
              isOffline ? "Offline" : "Success",
              isOffline
                  ? "Product update queued offline. Will sync when online."
                  : "Product updated",
              isError: false);
          _clearControllers();
          fetchProducts(forceRefresh: true);
        } else {
          Utils.showSnackbar(
              "Error", "Failed to update product: ${response.body}");
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete(
        '/business/inventory/$productId',
        headers: {'x-user-id': userId},
      );
      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Deleted",
            isOffline
                ? "Product deletion scheduled offline. Will sync when online."
                : "Product removed from inventory",
            isError: false);
        fetchProducts(forceRefresh: true);
      } else {
        Utils.showSnackbar(
            "Error", "Failed to delete product: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _clearControllers() {
    nameController.clear();
    descController.clear();
    priceController.clear();
    qtyController.text = "0";
    unitController.text = "pcs";
    skuController.clear();
    barcodeController.clear();
    categoryController.clear();
    purchasePriceController.clear();
    taxController.clear();
    minStockController.clear();
  }

  void setForEdit(dynamic product) {
    nameController.text = product['name'] ?? "";
    priceController.text = (product['price'] ?? 0).toString();
    qtyController.text = (product['stock_quantity'] ?? 0).toString();
    unitController.text = product['unit'] ?? "pcs";

    final rawDesc = product['description'] ?? "";
    try {
      final decoded = jsonDecode(rawDesc);
      descController.text = decoded['description'] ?? "";
      skuController.text = decoded['sku'] ?? "";
      barcodeController.text = decoded['barcode'] ?? "";
      categoryController.text = decoded['category'] ?? "";
      purchasePriceController.text = (decoded['purchase_price'] ?? "").toString();
      taxController.text = decoded['tax'] ?? "";
      minStockController.text = (decoded['min_stock'] ?? "").toString();
    } catch (_) {
      descController.text = rawDesc;
      skuController.clear();
      barcodeController.clear();
      categoryController.clear();
      purchasePriceController.clear();
      taxController.clear();
      minStockController.clear();
    }
  }
}

class InventoryListView extends StatelessWidget {
  const InventoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Management",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Export PDF",
            onPressed: () => _handleExport(context, controller, isPdf: true),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_rounded),
            tooltip: "Export CSV",
            onPressed: () => _handleExport(context, controller, isPdf: false),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchProducts(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Get.to(() => const AddProductScreen()),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text("Add Product",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  onChanged: (v) {
                    controller.searchQuery.value = v;
                  },
                  decoration: InputDecoration(
                    hintText: "Search items name...",
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                                    "Min: ₹${controller.minPriceFilter.value}"),
                                onDeleted: () =>
                                    controller.minPriceFilter.value = null,
                                backgroundColor: Colors.teal.shade50,
                              ),
                            ),
                          if (controller.maxPriceFilter.value != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(
                                    "Max: ₹${controller.maxPriceFilter.value}"),
                                onDeleted: () =>
                                    controller.maxPriceFilter.value = null,
                                backgroundColor: Colors.teal.shade50,
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.products.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.teal));
                  }
                  if (controller.products.isEmpty &&
                      !controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80, color: Colors.teal.withOpacity(0.5)),
                          const SizedBox(height: 20),
                          const Text("No products found.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black54)),
                        ],
                      ),
                    );
                  }
                  final list = controller.filteredProducts;
                  if (list.isEmpty) {
                    return const Center(
                        child: Text("No items match your search."));
                  }
                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)
                          .copyWith(bottom: 80),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final prod = list[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child:
                                  _buildProductCard(context, prod, controller),
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

  void _showFilterSheet(BuildContext context, InventoryController controller) {
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
                        prefixIcon: const Icon(Icons.arrow_downward)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    controller: maxC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Max Price",
                        prefixIcon: const Icon(Icons.arrow_upward)),
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
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(color: Colors.white)),
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

  Widget _buildProductCard(
      BuildContext context, dynamic prod, InventoryController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.category_rounded, color: Colors.teal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod['name'] ?? 'Product',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  _getProductDescription(prod),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "₹${prod['price']}",
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Stock: ${prod['stock_quantity']} ${prod['unit']}",
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.teal,
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
      title: const Text("Delete Product?"),
      content: Text(
          "Are you sure you want to remove '${prod['name']}' from inventory?"),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(prod['id']);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

}
