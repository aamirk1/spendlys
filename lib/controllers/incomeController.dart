// // ignore_for_file: file_names

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
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Business',
      'icon': CupertinoIcons.briefcase_fill,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Gift',
      'icon': CupertinoIcons.gift_fill,
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Loan',
      'icon': CupertinoIcons.creditcard_fill,
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'Sales',
      'icon': CupertinoIcons.cart_fill,
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Investment',
      'icon': CupertinoIcons.chart_bar_alt_fill,
      'color': Color(0xFF673AB7),
    },
    {
      'name': 'Rental Income',
      'icon': CupertinoIcons.house_fill,
      'color': Color(0xFF3F51B5),
    },
    {
      'name': 'Freelance',
      'icon': CupertinoIcons.device_laptop,
      'color': Color(0xFF009688),
    },
    {
      'name': 'Bonus',
      'icon': CupertinoIcons.star_circle_fill,
      'color': Color(0xFFFFC107),
    },
    {
      'name': 'Royalty',
      'icon': CupertinoIcons.music_note_2,
      'color': Color(0xFF9C27B0),
    },
    {
      'name': 'Dividend',
      'icon': CupertinoIcons.arrowtriangle_up_circle_fill,
      'color': Color(0xFF4DB6AC),
    },
    {
      'name': 'Refund',
      'icon': CupertinoIcons.arrow_2_squarepath,
      'color': Color(0xFF607D8B),
    },
    {
      'name': 'Scholarship',
      'icon': CupertinoIcons.book_fill,
      'color': Color(0xFFCDDC39),
    },
    {
      'name': 'Other',
      'icon': CupertinoIcons.question_circle_fill,
      'color': Color(0xFF9E9E9E),
    },
  ].obs;

  var errorMsg = Rx<String?>(null);
  var isLoading = false.obs;
  var categoryTotals = <String, double>{}.obs;
  var incomeList = <Map<String, dynamic>>[].obs;
  var totalIncome = 0.0.obs;
  var chartData = <Map<String, dynamic>>[].obs;
  var filteredIncomes = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchIncomes();
  }

  void fetchIncomes() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    isLoading(true);
    _firestore
        .collection('incomes')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> tempIncomes = [];
      Map<String, double> tempTotals = {};
      double total = 0;

      for (var doc in snapshot.docs) {
        String id = doc.id;
        Map<String, dynamic> data = doc.data();
        String category = data['category'] ?? 'Unknown';
        double amount = (data['amount'] as num).toDouble();
        DateTime date = (data['date'] as Timestamp).toDate();

        tempTotals[category] = (tempTotals[category] ?? 0) + amount;
        total += amount;

        tempIncomes.add({
          'id': id,
          'description': data['description'] ?? '',
          'category': category,
          'amount': amount,
          'date': date,
        });
      }

      incomeList.value = tempIncomes;
      categoryTotals.value = tempTotals;
      totalIncome.value = total;
      updateChartData();
      isLoading(false);
    });
  }

  // Inside your IncomeController
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

    categoryTotals.clear();

    try {
      // Fetch data from Firestore based on the selected filter (Weekly, Monthly, or Yearly)
      var snapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('date', descending: true)
          .get();

      Map<String, double> tempTotals = {};

      for (var doc in snapshot.docs) {
        String category = doc['category'] ?? 'Unknown';
        double amount = (doc['amount'] as num).toDouble();

        tempTotals[category] = (tempTotals[category] ?? 0) + amount;
      }

      // Update the categoryTotals with the new data
      categoryTotals.assignAll(tempTotals);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch chart data: $e');
    }
  }

  void updateChartData() {
    final Map<String, double> dataMap = {};
    for (var income in incomeList) {
      final dateKey = income['date'].toIso8601String().substring(0, 10);
      dataMap[dateKey] = (dataMap[dateKey] ?? 0) + income['amount'];
    }
    chartData.value =
        dataMap.entries.map((e) => {'date': e.key, 'amount': e.value}).toList();
  }

  Future<void> addIncome() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'User not logged in.');
      return;
    }

    isLoading(true);
    try {
      DocumentReference incomeRef = await _firestore.collection('incomes').add({
        'userId': userId,
        'amount': double.parse(amountController.text.trim()),
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value,
        'date': Timestamp.now(),
      });

      await incomeRef.update({'id': incomeRef.id});

      Get.snackbar('Success', 'Income added successfully!');
      amountController.clear();
      descriptionController.clear();
      selectedCategory.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to add income: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateIncome(
      String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('incomes').doc(docId).update(updatedData);
      Get.snackbar('Success', 'Income updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update income: $e');
    }
  }

  Future<void> deleteIncome(String docId) async {
    try {
      await _firestore.collection('incomes').doc(docId).delete();
      Get.snackbar('Deleted', 'Income removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete income: $e');
    }
  }
}

// ignore_for_file: file_names

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class IncomeController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final amountController = TextEditingController();
//   final descriptionController = TextEditingController();
//   var selectedCategory = ''.obs;
//   final formKey = GlobalKey<FormState>();

//   final RxList<Map<String, dynamic>> incomeCategories = <Map<String, dynamic>>[
//     {
//       'name': 'Salary',
//       'icon': CupertinoIcons.money_dollar_circle_fill,
//       'color': Colors.greenAccent,
//     },
//     {
//       'name': 'Business',
//       'icon': CupertinoIcons.briefcase_fill,
//       'color': Colors.blueAccent,
//     },
//     {
//       'name': 'Gift',
//       'icon': CupertinoIcons.gift_fill,
//       'color': Colors.purpleAccent,
//     },
//     {
//       'name': 'Loan',
//       'icon': CupertinoIcons.creditcard_fill,
//       'color': Colors.orangeAccent,
//     },
//     {
//       'name': 'Sales',
//       'icon': CupertinoIcons.cart_fill,
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
//   var incomeList = <Map<String, dynamic>>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _listenToIncomeUpdates(); // Start real-time listener
//   }

//   // Real-time listener for income updates
//   void _listenToIncomeUpdates() {
//     String? userId = _auth.currentUser?.uid;
//     if (userId == null) return;

//     // CHANGE 3: Updated orderBy to descending to match the Firestore index
//     _firestore
//         .collection('incomes')
//         .where('userId', isEqualTo: userId)
//         .orderBy('date', descending: true) // Changed to descending
//         .orderBy('__name__', descending: true) // Changed to descending
//         .snapshots() // Real-time listener
//         .listen((snapshot) {
//       Map<String, double> tempTotals = {};
//       List<Map<String, dynamic>> tempIncomes = [];

//       for (var doc in snapshot.docs) {
//         String id = doc.id;
//         Map<String, dynamic> data = doc.data();

//         String category = data['category'] ?? "Unknown";
//         String description = data['description'] ?? "";
//         double amount = (data['amount'] as num).toDouble();
//         DateTime date = (data['date'] as Timestamp).toDate();

//         tempTotals[category] = (tempTotals[category] ?? 0) + amount;

//         tempIncomes.add({
//           'id': id,
//           'description': description,
//           'category': category,
//           'amount': amount,
//           'date': date,
//         });
//       }

//       // Update reactive variables
//       categoryTotals.assignAll(tempTotals);
//       incomeList.assignAll(tempIncomes);
//     }, onError: (e) {
//       if (e.toString().contains('requires an index')) {
//         Get.snackbar('Index Required',
//             'Please create the required Firestore index for incomes. Check the logs for the link.');
//       } else {
//         Get.snackbar('Error', 'Failed to listen to incomes: $e');
//       }
//     });
//   }

//   // Fetch filtered income totals for charts (non-real-time)
//   Future<void> fetchChartIncomeTotals(String filter) async {
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
//       // CHANGE 4: Updated orderBy to descending to match the Firestore index
//       var snapshot = await _firestore
//           .collection('incomes')
//           .where('userId', isEqualTo: userId)
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
//           .orderBy('date', descending: true) // Changed to descending
//           .orderBy('__name__', descending: true) // Changed to descending
//           .get();

//       Map<String, double> tempTotals = {};

//       for (var doc in snapshot.docs) {
//         Map<String, dynamic> data = doc.data();
//         String category = data['category'] ?? "Unknown";
//         double amount = (data['amount'] as num).toDouble();
//         DateTime incomeDate = (data['date'] as Timestamp).toDate();

//         if (incomeDate.isAfter(startDate) ||
//             incomeDate.isAtSameMomentAs(startDate)) {
//           tempTotals[category] = (tempTotals[category] ?? 0) + amount;
//         }
//       }

//       categoryTotals.assignAll(tempTotals);
//       categoryTotals.refresh();
//     } catch (e) {
//       if (e.toString().contains('requires an index')) {
//         Get.snackbar('Index Required',
//             'Please create the required Firestore index for incomes. Check the logs for the link.');
//       } else {
//         Get.snackbar('Error', 'Failed to fetch chart income totals: $e');
//       }
//     }
//   }

//   // Add a new income
//   Future<void> addIncome() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) {
//       Get.snackbar('Error', 'User not logged in.');
//       return;
//     }

//     isLoading.value = true;

//     try {
//       DocumentReference incomeRef = await _firestore.collection('incomes').add({
//         'userId': userId,
//         'amount': double.parse(amountController.text.trim()),
//         'description': descriptionController.text.trim(),
//         'category': selectedCategory.value,
//         'date': Timestamp.now(),
//       });

//       await incomeRef.update({'id': incomeRef.id});

//       Get.snackbar('Success', 'Income added successfully!');

//       amountController.clear();
//       descriptionController.clear();
//       selectedCategory.value = '';
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to add income: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Update an existing income
//   Future<void> updateIncome(
//       String docId, Map<String, dynamic> updatedData) async {
//     try {
//       await _firestore.collection('incomes').doc(docId).update(updatedData);
//       Get.snackbar('Success', 'Income updated successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to update income: $e');
//     }
//   }

//   // Delete an income
//   Future<void> deleteIncome(String docId) async {
//     try {
//       await _firestore.collection('incomes').doc(docId).delete();
//       Get.snackbar('Deleted', 'Income removed successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to delete income: $e');
//     }
//   }

//   @override
//   void onClose() {
//     amountController.dispose();
//     descriptionController.dispose();
//     super.onClose();
//   }
// }
