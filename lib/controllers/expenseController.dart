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

  final RxList<Map<String, dynamic>> expenseCategories = <Map<String, dynamic>>[
    {
      'name': 'Food',
      'icon': CupertinoIcons.cart_fill,
      'color': Colors.redAccent,
    },
    {
      'name': 'Transportation',
      'icon': CupertinoIcons.car_fill,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Shopping',
      'icon': CupertinoIcons.bag_fill,
      'color': Colors.purpleAccent,
    },
    {
      'name': 'Health',
      'icon': CupertinoIcons.heart_fill,
      'color': Colors.greenAccent,
    },
    {
      'name': 'Education',
      'icon': CupertinoIcons.book_fill,
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Entertainment',
      'icon': CupertinoIcons.tv_fill,
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

        if (expenseDate.isAfter(startDate) ||
            expenseDate.isAtSameMomentAs(startDate)) {
          tempTotals[category] = (tempTotals[category] ?? 0) + amount;
        }
      }

      categoryTotals.assignAll(tempTotals);
      categoryTotals.refresh();
      update();
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

// ignore_for_file: file_names

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ExpenseController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final amountController = TextEditingController();
//   final descriptionController = TextEditingController();
//   var selectedCategory = ''.obs;
//   final formKey = GlobalKey<FormState>();

//   final RxList<Map<String, dynamic>> expenseCategories = <Map<String, dynamic>>[
//     {
//       'name': 'Food',
//       'icon': CupertinoIcons.cart_fill,
//       'color': Colors.redAccent,
//     },
//     {
//       'name': 'Transportation',
//       'icon': CupertinoIcons.car_fill,
//       'color': Colors.blueAccent,
//     },
//     {
//       'name': 'Shopping',
//       'icon': CupertinoIcons.bag_fill,
//       'color': Colors.purpleAccent,
//     },
//     {
//       'name': 'Health',
//       'icon': CupertinoIcons.heart_fill,
//       'color': Colors.greenAccent,
//     },
//     {
//       'name': 'Education',
//       'index': CupertinoIcons.book_fill,
//       'color': Colors.orangeAccent,
//     },
//     {
//       'name': 'Entertainment',
//       'icon': CupertinoIcons.tv_fill,
//       'color': Colors.tealAccent,
//     },
//     {
//       'name': 'Other',
//       'icon': CupertinoIcons.question_circle_fill,
//       'color': Colors.grey,
//     },
//   ].obs;

//   var errorMsg = Rx<String?>(null);
//   var isLoading = false.obs;
//   var categoryTotals = <String, double>{}.obs;
//   var expensesList = <Map<String, dynamic>>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _listenToExpenseUpdates(); // Start real-time listener
//   }

//   // Real-time listener for expense updates
//   void _listenToExpenseUpdates() {
//     String? userId = _auth.currentUser?.uid;
//     if (userId == null) return;

//     // CHANGE 1: Added orderBy to match the required composite index
//     _firestore
//         .collection('expenses')
//         .where('userId', isEqualTo: userId)
//         .orderBy('date') // Added to match the index requirement
//         .orderBy('__name__') // Added to match the index requirement
//         .snapshots() // Real-time listener
//         .listen((snapshot) {
//       Map<String, double> tempTotals = {};
//       List<Map<String, dynamic>> tempExpenses = [];

//       for (var doc in snapshot.docs) {
//         String id = doc.id;
//         Map<String, dynamic> data = doc.data();

//         String category = data['category'] ?? "Unknown";
//         String description = data['description'] ?? "";
//         double amount = (data['amount'] as num).toDouble();
//         DateTime date = (data['date'] as Timestamp).toDate();

//         tempTotals[category] = (tempTotals[category] ?? 0) + amount;

//         tempExpenses.add({
//           'id': id,
//           'description': description,
//           'category': category,
//           'amount': amount,
//           'date': date,
//         });
//       }

//       // Update reactive variables
//       categoryTotals.assignAll(tempTotals);
//       expensesList.assignAll(tempExpenses);
//     }, onError: (e) {
//       // CHANGE 2: Improved error handling for index-related errors
//       if (e.toString().contains('requires an index')) {
//         Get.snackbar('Index Required',
//             'Please create the required Firestore index for expenses. Check the logs for the link.');
//       } else {
//         Get.snackbar('Error', 'Failed to listen to expenses: $e');
//       }
//     });
//   }

//   // Fetch filtered expense totals for charts (non-real-time)
//   Future<void> fetchChartExpenseTotals(String filter) async {
//     String? userId = _auth.currentUser?.uid;
//     if (userId == null) return;

//     DateTime now = DateTime.now();
//     DateTime startDate;

//     if (filter == 'Weekly') {
//       startDate =
//           now.subtract(Duration(days: now.weekday - 1)); // Start of week
//     } else if (filter == 'Monthly') {
//       startDate = DateTime(now.year, now.month, 1); // Start of month
//     } else {
//       startDate = DateTime(now.year, 1, 1); // Start of year
//     }

//     categoryTotals.clear();

//     try {
//       // CHANGE 3: Added orderBy to match the required composite index
//       var snapshot = await _firestore
//           .collection('expenses')
//           .where('userId', isEqualTo: userId)
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
//           .orderBy('date') // Added to match the index requirement
//           .orderBy('__name__') // Added to match the index requirement
//           .get();

//       Map<String, double> tempTotals = {};

//       for (var doc in snapshot.docs) {
//         Map<String, dynamic> data = doc.data();
//         String category = data['category'] ?? "Unknown";
//         double amount = (data['amount'] as num).toDouble();
//         DateTime expenseDate = (data['date'] as Timestamp).toDate();

//         if (expenseDate.isAfter(startDate) ||
//             expenseDate.isAtSameMomentAs(startDate)) {
//           tempTotals[category] = (tempTotals[category] ?? 0) + amount;
//         }
//       }

//       categoryTotals.assignAll(tempTotals);
//       categoryTotals.refresh();
//       update();
//     } catch (e) {
//       // CHANGE 4: Improved error handling for index-related errors
//       if (e.toString().contains('requires an index')) {
//         Get.snackbar('Index Required',
//             'Please create the required Firestore index for expenses. Check the logs for the link.');
//       } else {
//         Get.snackbar('Error', 'Failed to fetch chart expense totals: $e');
//       }
//     }
//   }

//   // Add a new expense
//   Future<void> addExpense() async {
//     final userId = _auth.currentUser?.uid;
//     if (userId == null) {
//       Get.snackbar('Error', 'User not logged in.');
//       return;
//     }

//     isLoading.value = true;

//     try {
//       DocumentReference expenseRef =
//           await _firestore.collection('expenses').add({
//         'userId': userId,
//         'amount': double.parse(amountController.text.trim()),
//         'description': descriptionController.text.trim(),
//         'category': selectedCategory.value,
//         'date': Timestamp.now(),
//       });

//       await expenseRef.update({'id': expenseRef.id});

//       Get.snackbar('Success', 'Expense added successfully!');

//       amountController.clear();
//       descriptionController.clear();
//       selectedCategory.value = '';
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to add expense: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Update an existing expense
//   Future<void> updateExpense(
//       String docId, Map<String, dynamic> updatedData) async {
//     try {
//       await _firestore.collection('expenses').doc(docId).update(updatedData);
//       Get.snackbar('Success', 'Expense updated successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to update expense: $e');
//     }
//   }

//   // Delete an expense
//   Future<void> deleteExpense(String docId) async {
//     try {
//       await _firestore.collection('expenses').doc(docId).delete();
//       Get.snackbar('Deleted', 'Expense removed successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to delete expense: $e');
//     }
//   }

//   @override
//   void onClose() {
//     // Clean up controllers when the controller is disposed
//     amountController.dispose();
//     descriptionController.dispose();
//     super.onClose();
//   }
// }
