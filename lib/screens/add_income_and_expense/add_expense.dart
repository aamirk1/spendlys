// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:spendly/controllers/expenseController.dart';
// import 'package:spendly/screens/auth/components/my_text_field.dart';

// class AddExpense extends StatelessWidget {
//   AddExpense({super.key});

//   // final controller = Get.put(ExpenseController());
//   final controller = Get.find<ExpenseController>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Form(
//             key: controller.formKey,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),

//                   // Amount Field
//                   Obx(() => MyTextField(
//                         controller: controller.amountController,
//                         hintText: 'Amount',
//                         obscureText: false,
//                         keyboardType: TextInputType.number,
//                         errorMsg: controller.errorMsg.value,
//                         validator: (val) {
//                           if (val == null || val.isEmpty) {
//                             return 'Please enter an amount';
//                           }
//                           if (double.tryParse(val) == null) {
//                             return 'Please enter a valid number';
//                           }
//                           return null;
//                         },
//                       )),

//                   const SizedBox(height: 10),

//                   // Description Field
//                   Obx(() => MyTextField(
//                         controller: controller.descriptionController,
//                         hintText: 'Write a description',
//                         obscureText: false,
//                         keyboardType: TextInputType.text,
//                         errorMsg: controller.errorMsg.value,
//                         validator: (val) {
//                           if (val == null || val.isEmpty) {
//                             return 'Please enter a description';
//                           }
//                           return null;
//                         },
//                       )),

//                   const SizedBox(height: 10),

//                   // Category Dropdown
//                   Obx(() {
//                     return DropdownButtonFormField<String>(
//                       value: controller.selectedCategory.value.isEmpty
//                           ? null
//                           : controller.selectedCategory.value,
//                       decoration: InputDecoration(
//                         hintText: 'Select a category',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         // suffixIcon: IconButton(
//                         //   onPressed: () {
//                         //     Get.to(() => ManageCategoriesScreen());
//                         //   },
//                         //   icon: Icon(Icons.add),
//                         // ),
//                       ),
//                       items: controller.expenseCategories
//                           .map<DropdownMenuItem<String>>((category) {
//                         return DropdownMenuItem<String>(
//                           value: category['name'] as String, // Category name
//                           child: Row(
//                             children: [
//                               // Use dynamic IconData from code
//                               Icon(
//                                 category['icon'] as IconData,
//                                 color: category['color'] as Color,
//                               ),
//                               SizedBox(width: 10),
//                               Text(category['name']
//                                   as String), // Display category name
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         controller.selectedCategory.value =
//                             value ?? ''; // Update selected category
//                       },
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please select a category';
//                         }
//                         return null;
//                       },
//                     );
//                   }),

//                   const SizedBox(height: 20),

//                   // Submit Button
//                   Obx(() => controller.isLoading.value
//                       ? const CircularProgressIndicator()
//                       : SizedBox(
//                           width: MediaQuery.of(context).size.width * 0.5,
//                           child: TextButton(
//                             onPressed: () {
//                               if (controller.formKey.currentState!.validate()) {
//                                 controller.addExpense();
//                               }
//                             },
//                             style: TextButton.styleFrom(
//                               backgroundColor:
//                                   Theme.of(context).colorScheme.primary,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(60),
//                               ),
//                             ),
//                             child: const Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 25, vertical: 5),
//                               child: Text(
//                                 'Add Expense',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(left: 15.0),
//                 child: Text(
//                   'Last Ten Expenses',
//                   style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.onSurface,
//                       fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//           // const SizedBox(height: 5),
//           // ✅ Show Last 10 Expenses
//           Obx(() {
//             final expenses = controller.expensesList;

//             if (expenses.isEmpty) {
//               return const Center(child: Text("No expenses found."));
//             }

//             // Convert to normal list and sort by date (latest first)
//             final recentExpenses = expenses.toList()
//               ..sort((a, b) => b['date'].compareTo(a['date']));

//             final last10Expenses = recentExpenses.take(5).toList();

//             return Expanded(
//               child: ListView.builder(
//                 itemCount: last10Expenses.length,
//                 itemBuilder: (context, int i) {
//                   var expense = last10Expenses[i];
//                   String category = expense['category'];
//                   double amount = expense['amount'];
//                   DateTime date = expense['date'];
//                   String description = expense['description'];

//                   // Fetch category icon and color
//                   var categoryData = controller.expenseCategories.firstWhere(
//                     (element) => element['name'] == category,
//                     orElse: () => {
//                       'icon': Icons.category,
//                       'color': Colors.grey
//                     }, // Default values
//                   );

//                   return Card(
//                     elevation: 2,
//                     margin:
//                         const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         radius: 25,
//                         backgroundColor: categoryData['color'] as Color,
//                         child: Icon(
//                           categoryData['icon'] as IconData,
//                           color: Colors.white,
//                         ),
//                       ),
//                       title: Text(
//                         description,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.w500),
//                       ),
//                       subtitle: Text(
//                         DateFormat('dd/MM/yyyy hh:mm a').format(date),
//                         style:
//                             const TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                       trailing: Text(
//                         "₹${amount.toStringAsFixed(2)}",
//                         style: const TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.w500),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           })
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';

class AddExpense extends StatelessWidget {
  AddExpense({super.key});

  // final controller = Get.put(ExpenseController());
  final controller = Get.find<ExpenseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Category Dropdown (with search)
                  // Category Selector Field
                  Obx(() {
                    final selectedCategoryData =
                        controller.expenseCategories.firstWhere(
                      (cat) => cat['name'] == controller.selectedCategory.value,
                      orElse: () => <String, dynamic>{},
                    );

                    return GestureDetector(
                      onTap: () {
                        _showCategoryPicker(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: controller.selectedCategory.value.isEmpty
                                ? ''
                                : controller.selectedCategory.value,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Select a category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor:
                                    (selectedCategoryData['color'] as Color?) ??
                                        Colors.grey,
                                radius: 14,
                                child: Icon(
                                  (selectedCategoryData['icon'] as IconData?) ??
                                      Icons.category,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                          readOnly: true,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Submit Button
                  Obx(() => controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: CustomButton(
                            borderRadius: 60,
                            text: 'Add Expense',
                            onPressed: () {
                              if (controller.formKey.currentState!.validate()) {
                                controller.addExpense();
                              }
                            },
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            isLoading: controller.isLoading.value,
                          )

                          //  TextButton(
                          //   onPressed: () {
                          //     if (controller.formKey.currentState!.validate()) {
                          //       controller.addExpense();
                          //     }
                          //   },
                          //   style: TextButton.styleFrom(
                          //     backgroundColor:
                          //         Theme.of(context).colorScheme.primary,
                          //     foregroundColor: Colors.white,
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(60),
                          //     ),
                          //   ),
                          //   child: const Padding(
                          //     padding: EdgeInsets.symmetric(
                          //         horizontal: 25, vertical: 5),
                          //     child: Text(
                          //       'Add Expense',
                          //       style: TextStyle(
                          //         fontSize: 16,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Ten Expenses',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(RoutesName.viewAllExpenses);
                  },
                  child: Text(
                    'All Expenses',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
          // Show Last 10 Expenses
          Obx(() {
            final expenses = controller.expensesList;

            if (expenses.isEmpty) {
              return const Center(child: Text("No expenses found."));
            }

            // Convert to normal list and sort by date (latest first)
            final recentExpenses = expenses.toList()
              ..sort((a, b) => b['date'].compareTo(a['date']));

            final last10Expenses = recentExpenses.take(5).toList();

            return Expanded(
              child: ListView.builder(
                itemCount: last10Expenses.length,
                itemBuilder: (context, int i) {
                  var expense = last10Expenses[i];
                  String category = expense['category'];
                  double amount = expense['amount'];
                  DateTime date = expense['date'];
                  String description = expense['description'];

                  // Fetch category icon and color
                  var categoryData = controller.expenseCategories.firstWhere(
                    (element) => element['name'] == category,
                    orElse: () => {
                      'icon': Icons.category,
                      'color': Colors.grey
                    }, // Default values
                  );

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: categoryData['color'] as Color,
                        child: Icon(
                          categoryData['icon'] as IconData,
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

  void _showCategoryPicker(BuildContext context) {
    final searchController = TextEditingController();
    Get.dialog(
      Dialog(
        child: Container(
          height: 500,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search category',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  controller.filteredExpenseCategories.value = controller
                      .expenseCategories
                      .where((category) => category['name']
                          .toString()
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList();
                },
              ),
              SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final listToShow =
                      controller.filteredExpenseCategories.isEmpty
                          ? controller.expenseCategories
                          : controller.filteredExpenseCategories;
                  return ListView.builder(
                    itemCount: listToShow.length,
                    itemBuilder: (context, index) {
                      final category = listToShow[index];
                      return ListTile(
                        leading: Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                        ),
                        title: Text(category['name'] as String),
                        onTap: () {
                          controller.selectedCategory.value =
                              category['name'] as String;
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
