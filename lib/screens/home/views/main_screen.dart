import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/add_income_and_expense/categorywise_expense_and%20income/categorywise_view_all_expense.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key, required this.myUser});
  final MyUser myUser;

  final ExpenseController expenseController = Get.put(ExpenseController());
  final IncomeController incomeController = Get.put(IncomeController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.yellow[700]),
                        ),
                        Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.yellow[800],
                        )
                      ],
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome!",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.outline),
                        ),
                        Text(
                          myUser.name,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface),
                        )
                      ],
                    ),
                  ],
                ),
                IconButton(
                    onPressed: () {}, icon: const Icon(CupertinoIcons.settings))
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    transform: const GradientRotation(pi / 4),
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 4,
                        color: Colors.grey.shade300,
                        offset: const Offset(5, 5))
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    double totalIncome = incomeController.categoryTotals.values
                        .fold(0, (sum, value) => sum + value);
                    double totalExpense = expenseController
                        .categoryTotals.values
                        .fold(0, (sum, value) => sum + value);
                    double totalAmount = totalIncome - totalExpense;
                    return Text(
                      '₹ ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle),
                              child: const Center(
                                  child: Icon(
                                CupertinoIcons.arrow_up,
                                size: 12,
                                color: Colors.greenAccent,
                              )),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Income',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400),
                                ),
                                Obx(() {
                                  double totalIncome = incomeController
                                      .categoryTotals.values
                                      .fold(0, (sum, value) => sum + value);
                                  return Text(
                                    '₹ ${totalIncome.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  );
                                }),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle),
                              child: const Center(
                                  child: Icon(
                                CupertinoIcons.arrow_down,
                                size: 12,
                                color: Colors.red,
                              )),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expenses',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400),
                                ),
                                Obx(() {
                                  double totalExpense = expenseController
                                      .categoryTotals.values
                                      .fold(0, (sum, value) => sum + value);
                                  return Text(
                                    '₹ ${totalExpense.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  );
                                }),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(RoutesName.viewAllIncome);
                      },
                      child: Text(
                        'All Income',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    Text(
                      ' / ',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w400),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(RoutesName.viewAllExpenses);
                      },
                      child: Text(
                        'All Expenses',
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final expenses = expenseController.expensesList;

              // Group expenses by category and find the latest date
              Map<String, double> categoryTotals = {};
              Map<String, DateTime> latestDatePerCategory = {};

              for (var expense in expenses) {
                String category = expense['category'];
                double amount = expense['amount'];
                DateTime date = expense['date'];

                // Sum amounts per category
                categoryTotals[category] =
                    (categoryTotals[category] ?? 0) + amount;

                // Track the latest date per category
                if (latestDatePerCategory[category] == null ||
                    date.isAfter(latestDatePerCategory[category]!)) {
                  latestDatePerCategory[category] = date;
                }
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: categoryTotals.length,
                  itemBuilder: (context, int i) {
                    String category = categoryTotals.keys.elementAt(i);
                    double totalAmount = categoryTotals[category] ?? 0;
                    DateTime? latestDate = latestDatePerCategory[category];

                    // Fetch category icon and color from expenseCategories
                    var categoryData =
                        expenseController.expenseCategories.firstWhere(
                      (element) => element['name'] == category,
                      orElse: () => {
                        'icon': Icons.category,
                        'color': Colors.grey
                      }, // Default values
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ListTile(
                              onTap: () {
                                Get.to(() => CategorywiseViewAllExpense(),
                                    arguments: category);
                              },
                              contentPadding:
                                  EdgeInsets.zero, // Removes default padding
                              leading: CircleAvatar(
                                radius: 25, // Equivalent to 50x50 Container
                                backgroundColor: Color(
                                  int.parse(
                                    "0x" +
                                        categoryData['color']
                                            .replaceAll("#", ""),
                                  ),
                                ),
                                child: Icon(
                                  expenseController.getIconForCode(
                                      categoryData['icon'] as int),
                                  // ignore: prefer_interpolation_to_compose_strings
                                  
                                  color: Color(int.parse("0x" +
                                      categoryData['color']
                                          .replaceAll("#", ""))),
                                ),
                              ),
                              title: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Aligns text vertically
                                children: [
                                  Text(
                                    "₹${totalAmount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(latestDate!),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ),
                    );
                  },
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
