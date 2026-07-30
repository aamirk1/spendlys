import 'dart:convert';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/utils/utils.dart';

class CategoryController extends GetxController {
  var categories = <Map<String, dynamic>>[].obs;
  final nameController = TextEditingController();
  final iconController = TextEditingController();
  final colorController = TextEditingController();
  // List of available icons
  List<IconData> availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.home,
    Icons.car_repair,
    Icons.flight,
    Icons.medical_services,
    Icons.movie,
    Icons.savings,
    Icons.fitness_center,
    Icons.directions_bus,
    Icons.school,
    Icons.local_grocery_store,
  ];
  var selectedIcon = Icons.shopping_cart.obs;
  var selectedColor = Color(0xFFFFA500).obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/categories/?user_id=$userId';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (cachedData != null && cachedData is List) {
      categories.value =
          cachedData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/categories/?user_id=$userId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          categories.value =
              data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to fetch categories: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    if (nameController.text.trim().isEmpty) {
      Utils.showSnackbar('Error', 'Category name and icon are required.');
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.post('/categories/', body: {
        'user_id': userId,
        'name': nameController.text.trim(),
        'icon': selectedIcon.value.codePoint,
        'color': selectedColor.value.value.toRadixString(16),
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Category added offline. Will sync when online.'
                : 'Category added successfully!',
            isError: false);
        nameController.clear();
        selectedIcon.value = Icons.shopping_cart;
        selectedColor.value = Color(0xFFFFA500);
        fetchCategories(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to add category: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to add category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCategory(String categoryId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    if (nameController.text.trim().isEmpty) {
      Utils.showSnackbar('Error', 'Category name and icon are required.');
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.put('/categories/$categoryId', body: {
        'name': nameController.text.trim(),
        'icon': selectedIcon.value.codePoint,
        'color': selectedColor.value.value.toRadixString(16),
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Category update saved offline. Will sync when online.'
                : 'Category updated successfully!',
            isError: false);
        nameController.clear();
        selectedIcon.value = Icons.shopping_cart;
        selectedColor.value = Color(0xFFFFA500);
        fetchCategories(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update category: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to update category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final response = await ApiService.delete('/categories/$categoryId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Deleted',
            isOffline
                ? 'Category deletion scheduled offline. Will sync when online.'
                : 'Category removed successfully',
            isError: false);
        fetchCategories(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to delete category: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to delete category: $e');
    }
  }
}
