// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IncomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  var selectedCategory = ''.obs;
  final formKey = GlobalKey<FormState>();

  final RxList<Map<String, dynamic>> incomeCategories = <Map<String, dynamic>>[
    {
      'name': 'Salary',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'color': Colors.greenAccent,
    },
    {
      'name': 'Business',
      'icon': CupertinoIcons.briefcase_fill,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Gift',
      'icon': CupertinoIcons.gift_fill,
      'color': Colors.purpleAccent,
    },
    {
      'name': 'Loan',
      'icon': CupertinoIcons.creditcard_fill,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Sales',
      'icon': CupertinoIcons.cart_fill,
      'color': Colors.tealAccent,
    },
    {
      'name': 'Other',
      'icon': CupertinoIcons.question_circle_fill,
      'color': Colors.grey,
    },
  ].obs;

  var errorMsg = Rx<String?>(null);
  var isLoading = false.obs;
  var categoryTotals = <String, double>{}.obs;
  var incomeList = <Map<String, dynamic>>[].obs; // ✅ Income list for UI

  @override
  void onInit() {
    super.onInit();
    fetchIncomeTotals();
  }

  // Convert fetchIncomeTotals to a Future function
  Future<void> fetchIncomeTotals() async {
    String? userId = _auth.currentUser?.uid;

    try {
      var snapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, double> tempTotals = {};
      List<Map<String, dynamic>> tempIncomes = [];

      for (var doc in snapshot.docs) {
        String id = doc.id; // 🔥 Get Firestore's auto-generated ID
        Map<String, dynamic> data = doc.data();

        String category = data['category'] ?? "Unknown";
        String description = data['description'] ?? "";
        double amount = (data['amount'] as num).toDouble();
        DateTime date = (data['date'] as Timestamp).toDate();

        tempTotals[category] = (tempTotals[category] ?? 0) + amount;

        tempIncomes.add({
          'id': id, // ✅ Ensure ID is correctly stored
          'description': description,
          'category': category,
          'amount': amount,
          'date': date,
        });
      }

      categoryTotals.value = tempTotals;
      incomeList.value = tempIncomes;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch income totals: $e');
    }
  }

  // Convert fetchChartIncomeTotals to a Future function
  Future<void> fetchChartIncomeTotals(String filter) async {
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

    categoryTotals.clear(); // Clear previous totals

    try {
      var snapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      Map<String, double> tempTotals = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String category = data['category'] ?? "Unknown";
        double amount = (data['amount'] as num).toDouble();
        DateTime incomeDate = (data['date'] as Timestamp).toDate();

        if (incomeDate.isAfter(startDate) ||
            incomeDate.isAtSameMomentAs(startDate)) {
          tempTotals[category] = (tempTotals[category] ?? 0) + amount;
        }
      }

      categoryTotals.assignAll(tempTotals); // Update the reactive data
      categoryTotals.refresh(); // Ensure UI is updated
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch chart income totals: $e');
    }
  }

  // Convert addIncome to a Future function
  Future<void> addIncome() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in.');
      return;
    }

    isLoading.value = true;

    try {
      // Generate document reference
      DocumentReference incomeRef = await _firestore.collection('incomes').add({
        'userId': userId,
        'amount': double.parse(amountController.text.trim()),
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value,
        'date': Timestamp.now(),
      });

      // Update document with its ID
      await incomeRef.update({'id': incomeRef.id});

      Get.snackbar('Success', 'Income added successfully!');

      // Clear inputs
      amountController.clear();
      descriptionController.clear();
      selectedCategory.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to add income: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Convert updateIncome to a Future function
  Future<void> updateIncome(
      String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('incomes').doc(docId).update(updatedData);
      Get.snackbar('Success', 'Income updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update income: $e');
    }
  }

  // Convert deleteIncome to a Future function
  Future<void> deleteIncome(String docId) async {
    try {
      await _firestore.collection('incomes').doc(docId).delete();
      Get.snackbar('Deleted', 'Income removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete income: $e');
    }
  }
}
