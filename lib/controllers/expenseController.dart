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

  var expenseCategories = <Map<String, dynamic>>[].obs;
  var errorMsg = Rx<String?>(null);
  var isLoading = false.obs;
  var categoryTotals = <String, double>{}.obs;
  var expensesList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchExpenseTotals();
    fetchCategories();
  }

  // Convert fetchCategories to a Future function
  Future<void> fetchCategories() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      var snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      expenseCategories.value = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'icon': doc['icon'],
          'color': doc['color'],
        };
      }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch categories: $e');
    }
  }

  // Convert fetchChartExpenseTotals to a Future function
  Future<void> fetchChartExpenseTotals(String filter) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    DateTime now = DateTime.now();
    DateTime startDate;

    if (filter == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1)); // Start of week
    } else if (filter == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1); // Start of month
    } else {
      startDate = DateTime(now.year, 1, 1); // Start of year
    }

    categoryTotals.clear();

    try {
      var snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      Map<String, double> tempTotals = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        String category = data['category'] ?? "Unknown";
        double amount = (data['amount'] as num).toDouble();

        DateTime expenseDate = (data['date'] as Timestamp).toDate();

        if (expenseDate.isAfter(startDate) || expenseDate.isAtSameMomentAs(startDate)) {
          tempTotals[category] = (tempTotals[category] ?? 0) + amount;
        }
      }

      categoryTotals.assignAll(tempTotals);
      categoryTotals.refresh();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch expense totals: $e');
    }
  }

  // Convert fetchExpenseTotals to a Future function
  Future<void> fetchExpenseTotals() async {
    String? userId = _auth.currentUser?.uid;

    try {
      var snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

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

      categoryTotals.value = tempTotals;
      expensesList.value = tempExpenses;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch expenses: $e');
    }
  }

  // Convert addExpense to a Future function
  Future<void> addExpense() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in.');
      return;
    }

    isLoading.value = true;

    try {
      DocumentReference expenseRef = await _firestore.collection('expenses').add({
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

  // Convert updateExpense to a Future function
  Future<void> updateExpense(String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('expenses').doc(docId).update(updatedData);
      Get.snackbar('Success', 'Expense updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update expense: $e');
    }
  }

  // Convert deleteExpense to a Future function
  Future<void> deleteExpense(String docId) async {
    try {
      await _firestore.collection('expenses').doc(docId).delete();
      Get.snackbar('Deleted', 'Expense removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete expense: $e');
    }
  }

  final Map<int, IconData> iconMapping = {
    0xe318: Icons.home,
    0xe8f4: Icons.shopping_cart,
    0xe8b5: Icons.restaurant,
    0xeb44: Icons.school,
    0xe8d3: Icons.local_hospital,
    0xe332: Icons.directions_car,
    0xe8f8: Icons.movie,
    0xe8f7: Icons.local_gas_station,
    0xe57f: Icons.attach_money,
    // Add more mappings as needed
  };

  // Helper method to get icon
  IconData getIconForCode(int code) {
    return iconMapping[code] ?? Icons.category; // Default icon
  }
}
