// // ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/utils.dart';

class IncomeController extends GetxController {
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

  Future<void> fetchIncomes() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading(true);
    try {
      final response =
          await ApiService.get('/transactions/?user_id=$userId&type=income');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> tempIncomes = [];
        Map<String, double> tempTotals = {};
        double total = 0;

        for (var item in data) {
          String category = item['category'] ?? 'Unknown';
          double amount = (item['amount'] as num).toDouble();
          DateTime date = DateTime.parse(item['date']);

          tempTotals[category] = (tempTotals[category] ?? 0) + amount;
          total += amount;

          tempIncomes.add({
            'id': item['id'].toString(),
            'description': item['description'] ?? '',
            'category': category,
            'amount': amount,
            'date': date,
          });
        }

        incomeList.value = tempIncomes;
        categoryTotals.value = tempTotals;
        totalIncome.value = total;
        updateChartData();
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to fetch incomes: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading(false);
    }
  }

  // Inside your IncomeController
  Future<void> fetchChartIncomeTotals(String filter) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    await fetchIncomes();
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

    isLoading(true);
    try {
      final response = await ApiService.post('/transactions/', body: {
        'user_id': userId,
        'amount': amount,
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value,
        'type': 'income',
        'date': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar('Success', 'Income added successfully!',
            isError: false);
        amountController.clear();
        descriptionController.clear();
        selectedCategory.value = '';
        fetchIncomes(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to add income: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to add income: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateIncome(
      String docId, Map<String, dynamic> updatedData) async {
    isLoading(true);
    try {
      final response =
          await ApiService.put('/transactions/$docId', body: updatedData);
      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Income updated successfully',
            isError: false);
        fetchIncomes(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update income: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to update income: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteIncome(String docId) async {
    isLoading(true);
    try {
      final response = await ApiService.delete('/transactions/$docId');
      if (response.statusCode == 200) {
        Utils.showSnackbar('Deleted', 'Income removed successfully',
            isError: false);
        fetchIncomes(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to delete income: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Failed to delete income: $e');
    } finally {
      isLoading(false);
    }
  }
}
