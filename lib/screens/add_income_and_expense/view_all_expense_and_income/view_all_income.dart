import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/incomeController.dart';

class ViewAllIncome extends StatelessWidget {
  ViewAllIncome({super.key});

  final IncomeController incomeController = Get.find<IncomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFFE064F7),
          automaticallyImplyLeading: false,
          title: Center(child: const Text("All Incomes"))),
      body: Obx(() {
        final incomes = incomeController.incomeList;

        if (incomes.isEmpty) {
          return const Center(child: Text("No incomes found."));
        }

        return ListView.builder(
          itemCount: incomes.length,
          itemBuilder: (context, index) {
            var income = incomes[index];
            // String id = income['id'];
            // print('income $id');
            print('income $income');

            String category = income['category'];
            String description = income['description'];
            double amount = income['amount'];
            DateTime date = income['date'];

            // Get category icon & color
            var categoryData = incomeController.incomeCategories.firstWhere(
              (c) => c['name'] == category,
              orElse: () => {'icon': Icons.category, 'color': Colors.grey},
            );

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: categoryData['color'],
                  child: Icon(categoryData['icon'], color: Colors.white),
                ),
                title: Text("₹${amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    Text(DateFormat('dd/MM/yyyy hh:mm a')
                        .format(date)), // ✅ Date & Time
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editIncome(context, income),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, income),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ✅ EDIT INCOME FUNCTION
  void _editIncome(BuildContext context, Map<String, dynamic> income) {
    TextEditingController amountController =
        TextEditingController(text: income['amount'].toString());
    TextEditingController descriptionController =
        TextEditingController(text: income['description']);
    String selectedCategory = income['category'];

    Get.defaultDialog(
      title: "Edit Income",
      content: Column(
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Amount"),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          DropdownButtonFormField(
            value: selectedCategory,
            items: incomeController.incomeCategories.map((category) {
              return DropdownMenuItem(
                value: category['name'],
                child: Text(category['name']),
              );
            }).toList(),
            onChanged: (value) {
              selectedCategory = value as String;
            },
            decoration: const InputDecoration(labelText: "Category"),
          ),
        ],
      ),
      textConfirm: "Save",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        incomeController.updateIncome(income['id'], {
          'amount': double.parse(amountController.text.trim()),
          'description': descriptionController.text.trim(),
          'category': selectedCategory,
          'date': Timestamp.now(),
        });
        Get.back();
      },
    );
  }

  // ✅ DELETE CONFIRMATION FUNCTION
  void _confirmDelete(BuildContext context, Map<String, dynamic> income) {
    Get.defaultDialog(
      title: "Delete Income?",
      middleText: "Are you sure you want to delete this income?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        incomeController.deleteIncome(income['id']);
        Get.back();
      },
    );
  }
}
