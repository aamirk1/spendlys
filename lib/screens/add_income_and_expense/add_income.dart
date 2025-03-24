import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';

class AddIncome extends StatelessWidget {
  AddIncome({super.key});

  final controller = Get.put(IncomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Amount Field
                  Obx(() => MyTextField(
                        controller: controller.amountController,
                        hintText: 'Amount',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        errorMsg: controller.errorMsg.value,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(val) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      )),

                  const SizedBox(height: 10),

                  // Description Field
                  Obx(() => MyTextField(
                        controller: controller.descriptionController,
                        hintText: 'Write a description',
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        errorMsg: controller.errorMsg.value,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      )),

                  const SizedBox(height: 10),

                  // Category Dropdown
                  Obx(() {
                    return DropdownButtonFormField<String>(
                      value: controller.selectedCategory.value.isEmpty
                          ? null
                          : controller.selectedCategory.value,
                      decoration: InputDecoration(
                        hintText: 'Select a category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.add),
                        ),
                      ),
                      items: controller.incomeCategories
                          .map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['name']
                              as String, // Explicitly cast to String
                          child: Row(
                            children: [
                              Icon(category['icon'] as IconData,
                                  color: category['color'] as Color),
                              SizedBox(width: 10),
                              Text(category['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        controller.selectedCategory.value = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    );
                  }),

                  const SizedBox(height: 20),

                  // Submit Button
                  Obx(() => controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextButton(
                            onPressed: () {
                              if (controller.formKey.currentState!.validate()) {
                                controller.addIncome();
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(60),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 5),
                              child: Text(
                                'Add Income',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'Last Ten Expenses',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
// Show Last 10 Incomes
          Obx(() {
            final incomes = controller.incomeList;

            if (incomes.isEmpty) {
              return const Center(child: Text("No incomes found."));
            }

            // Convert to normal list and sort by date (latest first)
            final recentIncomes = incomes.toList()
              ..sort((a, b) => b['date'].compareTo(a['date']));

            final last10Incomes = recentIncomes.take(10).toList();

            return Expanded(
              child: ListView.builder(
                itemCount: last10Incomes.length,
                itemBuilder: (context, int i) {
                  var income = last10Incomes[i];
                  String category = income['category'];
                  double amount = income['amount'];
                  DateTime date = income['date'];
                  String description = income['description'];

                  // Fetch category icon and color
                  var categoryData = controller.incomeCategories.firstWhere(
                    (element) => element['name'] == category,
                    orElse: () => {
                      'icon': Icons.attach_money,
                      'color': Colors.grey
                    }, // Default values
                  );

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: categoryData['color'],
                        child: Icon(
                          categoryData['icon'],
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy hh:mm a').format(date),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Text(
                        "₹${amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
            );
          })
        ],
      ),
    );
  }
}
