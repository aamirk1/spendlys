import 'dart:convert';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/utils.dart';

class CategoryController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;


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

    isLoading.value = true;
    try {
      final response = await ApiService.get('/categories/?user_id=$userId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        categories.value = data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        Utils.showSnackbar('Error', 'Failed to fetch categories: ${response.body}');
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar('Success', 'Category added successfully!', isError: false);
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

      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Category updated successfully!', isError: false);
        nameController.clear();
        selectedIcon.value = Icons.shopping_cart;
        selectedColor.value = Color(0xFFFFA500);
        fetchCategories(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to update category: ${response.body}');
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
      if (response.statusCode == 200) {
        Utils.showSnackbar('Deleted', 'Category removed successfully', isError: false);
        fetchCategories(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to delete category: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to delete category: $e');
    }
  }

}
