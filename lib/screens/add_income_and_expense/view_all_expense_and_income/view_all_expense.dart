import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';

class ViewAllExpense extends StatelessWidget {
  ViewAllExpense({super.key});

  final ExpenseController expenseController = Get.find<ExpenseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFFFF8D6C),
          automaticallyImplyLeading: false,
          title: Center(child: const Text("All Expenses"))),
      body: Obx(() {
        final expenses = expenseController.expensesList;

        if (expenses.isEmpty) {
          return const Center(child: Text("No expenses found."));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            var expense = expenses[index];
            String category = expense['category'];
            String description = expense['description'];
            double amount = expense['amount'];
            DateTime date = expense['date'];

            // Get category icon & color
            var categoryData = expenseController.expenseCategories.firstWhere(
              (c) => c['name'] == category,
              orElse: () => {'icon': Icons.category, 'color': Colors.grey},
            );

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25, // Equivalent to 50x50 Container
                  backgroundColor: Color(
                    int.parse(
                      "0x" + categoryData['color'].replaceAll("#", ""),
                    ),
                  ),
                  child: Icon(
                    expenseController
                        .getIconForCode(categoryData['icon'] as int),
                    color: Color(int.parse(
                        "0x" + categoryData['color'].replaceAll("#", ""))),
                  ),
                ),
                title: Text('₹$amount',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    Text(DateFormat('dd/MM/yyyy hh:mm a').format(date)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editExpense(context, expense),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, expense),
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

  // ✅ EDIT EXPENSE FUNCTION
  void _editExpense(BuildContext context, Map<String, dynamic> expense) {
    TextEditingController amountController =
        TextEditingController(text: expense['amount'].toString());
    TextEditingController descriptionController =
        TextEditingController(text: expense['description']);
    String selectedCategory = expense['category'];

    Get.defaultDialog(
      title: "Edit Expense",
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
            items: expenseController.expenseCategories.map((category) {
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
        expenseController.updateExpense(expense['id'], {
          'amount': double.parse(amountController.text.trim()),
          'description': descriptionController.text.trim(),
          'category': selectedCategory,
        });
        Get.back();
      },
    );
  }

  // ✅ DELETE CONFIRMATION FUNCTION
  void _confirmDelete(BuildContext context, Map<String, dynamic> expense) {
    Get.defaultDialog(
      title: "Delete Expense?",
      middleText: "Are you sure you want to delete this expense?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        expenseController.deleteExpense(expense['id']);
        Get.back();
      },
    );
  }
}
