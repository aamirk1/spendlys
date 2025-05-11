// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpenseController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _listenToExpenseUpdates(); // Start real-time listener
  }

  // Real-time listener for expense updates
  void _listenToExpenseUpdates() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots() // Real-time listener
        .listen((snapshot) {
      Map<String, double> tempTotals = {};
      List<Map<String, dynamic>> tempExpenses = [];

      for (var doc in snapshot.docs) {
        String id = doc.id;
        Map<String, dynamic> data = doc.data();

        String category = data['category'] ?? "Unknown";
        String description = data['description'] ?? "";
        double amount = (data['amount'] as num).toDouble();
        DateTime date = (data['date'] as Timestamp).toDate();

        tempTotals[category] = (tempTotals[category] ?? 0) + amount;

        tempExpenses.add({
          'id': id,
          'description': description,
          'category': category,
          'amount': amount,
          'date': date,
        });
      }

      // Update reactive variables
      categoryTotals.assignAll(tempTotals);
      expensesList.assignAll(tempExpenses);
    }, onError: (e) {
      Get.snackbar('Error', 'Failed to listen to expenses: $e');
    });
  }

  // Fetch filtered expense totals for charts (non-real-time)
  Future<void> fetchChartExpenseTotals(String filter) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    DateTime now = DateTime.now();
    DateTime startDate;

    if (filter == 'Weekly') {
      startDate =
          now.subtract(Duration(days: now.weekday - 1)); // Start of week
    } else if (filter == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1); // Start of month
    } else {
      startDate = DateTime(now.year, 1, 1); // Start of year
    }

    categoryTotals.clear();

    try {
      // Fetch expense data from Firestore based on the selected filter (Weekly, Monthly, or Yearly)
      var snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();

      Map<String, double> tempTotals = {};

      for (var doc in snapshot.docs) {
        String category = doc['category'] ?? 'Unknown';
        double amount = (doc['amount'] as num).toDouble();

        // Add the amount to the category total
        tempTotals[category] = (tempTotals[category] ?? 0) + amount;
      }

      // Update categoryTotals with the new data
      categoryTotals.assignAll(tempTotals);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch chart expense totals: $e');
    }
  }

  // Add a new expense
  Future<void> addExpense() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in.');
      return;
    }

    isLoading.value = true;

    try {
      DocumentReference expenseRef =
          await _firestore.collection('expenses').add({
        'userId': userId,
        'amount': double.parse(amountController.text.trim()),
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value,
        'date': Timestamp.now(),
      });

      await expenseRef.update({'id': expenseRef.id});

      Get.snackbar('Success', 'Expense added successfully!');

      amountController.clear();
      descriptionController.clear();
      selectedCategory.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing expense
  Future<void> updateExpense(
      String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('expenses').doc(docId).update(updatedData);
      Get.snackbar('Success', 'Expense updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update expense: $e');
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String docId) async {
    try {
      await _firestore.collection('expenses').doc(docId).delete();
      Get.snackbar('Deleted', 'Expense removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete expense: $e');
    }
  }

  @override
  void onClose() {
    // Clean up controllers when the controller is disposed
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}