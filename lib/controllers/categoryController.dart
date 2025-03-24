import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  void fetchCategories() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      categories.value = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'icon': doc['icon'], // Now stores icon name instead of emoji
          'color': doc['color'],
        };
      }).toList();
    });
  }

  Future<void> addCategory() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Category name and icon are required.');
      return;
    }

    isLoading.value = true;

    try {
      await _firestore.collection('categories').add({
        'userId': userId,
        'name': nameController.text.trim(),
        'icon': selectedIcon.value.codePoint, // Store as integer
        'color':
            // ignore: deprecated_member_use
            selectedColor.value.value.toRadixString(16), // Store as HEX string
      });

      Get.snackbar('Success', 'Category added successfully!');
      nameController.clear();
      selectedIcon.value = Icons.shopping_cart; // Reset
      selectedColor.value = Color(0xFFFFA500); // Reset
    } catch (e) {
      Get.snackbar('Error', 'Failed to add category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCategory(String categoryId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Category name and icon are required.');
      return;
    }

    isLoading.value = true;

    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'name': nameController.text.trim(),
        'icon': selectedIcon.value.codePoint, // Store as integer (codePoint)
        'color':
            // ignore: deprecated_member_use
            selectedColor.value.value.toRadixString(16), // Store as HEX string
      });

      Get.snackbar('Success', 'Category updated successfully!');
      nameController.clear();
      selectedIcon.value = Icons.shopping_cart; // Reset icon
      selectedColor.value = Color(0xFFFFA500); // Reset color
    } catch (e) {
      Get.snackbar('Error', 'Failed to update category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      Get.snackbar('Deleted', 'Category removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: $e');
    }
  }
}
