// ignore_for_file: file_names

import 'dart:convert';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/utils.dart';


class ExpenseController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  var selectedCategory = ''.obs;
  final formKey = GlobalKey<FormState>();
  final RxList<Map<String, dynamic>> filteredExpenseCategories =
      <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> expenseCategories = <Map<String, dynamic>>[
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Color(0xFFFFA500)},
    {
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': Color(0xFF0000FF)
    },
    {
      'name': 'Travel',
      'icon': Icons.airplanemode_active,
      'color': Color(0xFF008080)
    },
    {
      'name': 'Groceries',
      'icon': Icons.shopping_cart,
      'color': Color(0xFF00FF00)
    },
    {'name': 'Bills', 'icon': Icons.receipt, 'color': Color(0xFFFFC0CB)},
    {'name': 'Rent', 'icon': Icons.home, 'color': Color(0xFFFFD700)},
    {'name': 'Utilities', 'icon': Icons.lightbulb, 'color': Color(0xFF808080)},
    {'name': 'Insurance', 'icon': Icons.security, 'color': Color(0xFF800000)},
    {
      'name': 'Subscriptions',
      'icon': Icons.subscriptions,
      'color': Color(0xFF000080)
    },
    {'name': 'Gifts', 'icon': Icons.card_giftcard, 'color': Color(0xFFFF69B4)},
    {
      'name': 'Entertainment',
      'icon': Icons.videogame_asset,
      'color': Color(0xFF00FFFF)
    },
    {
      'name': 'Dining Out',
      'icon': Icons.restaurant,
      'color': Color(0xFFADFF2F)
    },
    {'name': 'Clothing', 'icon': Icons.checkroom, 'color': Color(0xFFFF4500)},
    {
      'name': 'Hobbies',
      'icon': Icons.sports_baseball,
      'color': Color(0xFF8A2BE2)
    },
    {'name': 'Pets', 'icon': Icons.pets, 'color': Color(0xFF7FFF00)},
    {
      'name': 'Home Improvement',
      'icon': Icons.build,
      'color': Color(0xFFB22222)
    },
    {'name': 'Personal Care', 'icon': Icons.face, 'color': Color(0xFFDAA520)},
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center,
      'color': Color(0xFF32CD32)
    },
    {'name': 'Childcare', 'icon': Icons.child_care, 'color': Color(0xFF4169E1)},
    {'name': 'Charity', 'icon': Icons.favorite, 'color': Color(0xFFFF6347)},
    {
      'name': 'Medical',
      'icon': Icons.local_hospital,
      'color': Color(0xFF8B0000)
    },
    {
      'name': 'Miscellaneous',
      'icon': Icons.category,
      'color': Color(0xFF808000)
    },
    {
      'name': 'Electronics',
      'icon': Icons.electrical_services,
      'color': Color(0xFF7B68EE)
    },
    {'name': 'Sports', 'icon': Icons.sports, 'color': Color(0xFF4682B4)},
    {'name': 'Beauty', 'icon': Icons.brush, 'color': Color(0xFFFF1493)},
    {'name': 'Books', 'icon': Icons.book, 'color': Color(0xFF8B4513)},
    {'name': 'Gardening', 'icon': Icons.grass, 'color': Color(0xFF228B22)},
    {
      'name': 'Photography',
      'icon': Icons.camera_alt,
      'color': Color(0xFFDC143C)
    },
    {'name': 'Music', 'icon': Icons.music_note, 'color': Color(0xFF00FA9A)},
    {'name': 'Events', 'icon': Icons.event, 'color': Color(0xFFB8860B)},
    {'name': 'Streaming', 'icon': Icons.tv, 'color': Color(0xFFADFF2F)},
    {'name': 'Social', 'icon': Icons.people, 'color': Color(0xFF6495ED)},
    {
      'name': 'Dining',
      'icon': Icons.restaurant_menu,
      'color': Color(0xFFB22222)
    },
    {
      'name': 'Wellness',
      'icon': Icons.self_improvement,
      'color': Color(0xFF8B0000)
    },
    {'name': 'Home', 'icon': Icons.home_work, 'color': Color(0xFF8B4513)},
    {
      'name': 'Family',
      'icon': Icons.family_restroom,
      'color': Color(0xFF228B22)
    },
    {'name': 'Friends', 'icon': Icons.group, 'color': Color(0xFFDC143C)},
    {'name': 'Work', 'icon': Icons.work, 'color': Color(0xFF00FA9A)},
    {'name': 'Shopping', 'icon': Icons.local_mall, 'color': Color(0xFF008000)},
    {
      'name': 'Health',
      'icon': Icons.medical_services,
      'color': Color(0xFFFF0000)
    },
    {'name': 'Education', 'icon': Icons.school, 'color': Color(0xFF008080)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF808080)},
  ].obs;

  var errorMsg = Rx<String?>(null);
  var isLoading = false.obs;
  var categoryTotals = <String, double>{}.obs;
  var expensesList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchExpenses(); // Start fetching expenses
  }


  // Real-time listener for expense updates
  Future<void> fetchExpenses() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get('/transactions/?user_id=$userId&type=expense');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        Map<String, double> tempTotals = {};
        List<Map<String, dynamic>> tempExpenses = [];

        for (var item in data) {
          String category = item['category'] ?? "Unknown";
          double amount = (item['amount'] as num).toDouble();
          DateTime date = DateTime.parse(item['date']);

          tempTotals[category] = (tempTotals[category] ?? 0) + amount;

          tempExpenses.add({
            'id': item['id'].toString(),
            'description': item['description'] ?? "",
            'category': category,
            'amount': amount,
            'date': date,
          });
        }

        categoryTotals.assignAll(tempTotals);
        expensesList.assignAll(tempExpenses);
      } else {
        Utils.showSnackbar('Error', 'Failed to fetch expenses: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }


  // Fetch filtered expense totals for charts (non-real-time)
  Future<void> fetchChartExpenseTotals(String filter) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    // For now, we fetch all and filter in app, or you can add filter params to API
    await fetchExpenses();
    
    // Filtering logic can be more specific if needed
  }


  // Add a new expense
  Future<void> addExpense() async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) {
      Utils.showSnackbar('Error', 'User not logged in.');
      return;
    }

    final amountStr = amountController.text.trim();
    if (amountStr.isEmpty) {
      Utils.showSnackbar('Error', 'Please enter an amount.');
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null) {
      Utils.showSnackbar('Error', 'Please enter a valid amount.');
      return;
    }

    if (selectedCategory.value.isEmpty) {
      Utils.showSnackbar('Error', 'Please select a category.');
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.post('/transactions/', body: {
        'user_id': userId,
        'amount': amount,
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value,
        'type': 'expense',
        'date': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar('Success', 'Expense added successfully!', isError: false);
        amountController.clear();
        descriptionController.clear();
        selectedCategory.value = '';
        fetchExpenses(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to add expense: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to add expense: $e');
    } finally {
      isLoading.value = false;
    }
  }


  // Update an existing expense
  Future<void> updateExpense(
      String docId, Map<String, dynamic> updatedData) async {
    isLoading.value = true;
    try {
      final response = await ApiService.put('/transactions/$docId', body: updatedData);
      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Expense updated successfully', isError: false);
        fetchExpenses(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to update expense: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to update expense: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String docId) async {
    isLoading.value = true;
    try {
      final response = await ApiService.delete('/transactions/$docId');
      if (response.statusCode == 200) {
        Utils.showSnackbar('Deleted', 'Expense removed successfully', isError: false);
        fetchExpenses(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to delete expense: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to delete expense: $e');
    } finally {
      isLoading.value = false;
    }
  }


}