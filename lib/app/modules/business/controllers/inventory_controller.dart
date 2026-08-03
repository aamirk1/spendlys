import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/utils/utils.dart';

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
  final hsnController = TextEditingController();

  // Image Path
  final imagePath = "".obs;
  final ImagePicker _picker = ImagePicker();

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

  int get lowStockCount {
    int count = 0;
    for (var prod in products) {
      final double qty = double.tryParse(prod['stock_quantity']?.toString() ?? '0') ?? 0.0;
      final double minStock = _getProductMinStock(prod);
      if (qty <= minStock && minStock > 0) {
        count++;
      }
    }
    return count;
  }

  double get totalInventoryValue {
    double total = 0.0;
    for (var prod in products) {
      final double price = double.tryParse(prod['price']?.toString() ?? '0') ?? 0.0;
      final double qty = double.tryParse(prod['stock_quantity']?.toString() ?? '0') ?? 0.0;
      total += price * qty;
    }
    return total;
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
        "hsn_sac": hsnController.text.trim(),
        "image_path": imagePath.value,
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
          clearControllers();
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
          clearControllers();
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

  void clearControllers() {
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
    hsnController.clear();
    imagePath.value = "";
  }

  Future<void> pickProductImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File savedFile = await File(image.path).copy('${directory.path}/$fileName');
        imagePath.value = savedFile.path;
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to pick image: $e");
    }
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
      hsnController.text = decoded['hsn_sac'] ?? "";
      imagePath.value = decoded['image_path'] ?? "";
    } catch (_) {
      descController.text = rawDesc;
      skuController.clear();
      barcodeController.clear();
      categoryController.clear();
      purchasePriceController.clear();
      taxController.clear();
      minStockController.clear();
      hsnController.clear();
      imagePath.value = "";
    }
  }
}
