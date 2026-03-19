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
                    InkWell(
                      onTap: () {
                        Get.toNamed(RoutesName.profileView, arguments: myUser);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.yellow[700]),
                          ),
                          Text(
                            (myUser.name.isNotEmpty)
                                ? myUser.name[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        ],
                      ),
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
                    onPressed: () {
                      Get.toNamed(RoutesName.chatListView);
                    },
                    icon: Icon(CupertinoIcons.chat_bubble_2_fill, color: Theme.of(context).colorScheme.primary))
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
            const SizedBox(height: 25),
            _buildQuickModules(context),
            const SizedBox(height: 25),
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
                                radius: 25,
                                backgroundColor: categoryData['color'] as Color,
                                child: Icon(
                                  categoryData['icon'] as IconData,
                                  color: Colors.white,
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

  Widget _buildQuickModules(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {
        'name': 'Income/Exp',
        'icon': CupertinoIcons.money_dollar_circle,
        'color': Colors.blue,
        'route': RoutesName.incomeExpenseHome
      },
      {
        'name': 'Loans',
        'icon': CupertinoIcons.square_arrow_left_fill,
        'color': Colors.orange,
        'route': RoutesName.addLendBorrowView
      },
      {
        'name': 'Chat',
        'icon': CupertinoIcons.chat_bubble_2_fill,
        'color': Colors.green,
        'route': RoutesName.chatListView
      },
      {
        'name': 'Business',
        'icon': CupertinoIcons.briefcase_fill,
        'color': Colors.purple,
        'route': RoutesName.businessHome
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Services',
          style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return GestureDetector(
              onTap: () {
                if (module['route'] == RoutesName.addLendBorrowView ||
                    module['route'] == RoutesName.profileView) {
                  Get.toNamed(module['route'], arguments: myUser);
                } else {
                  Get.toNamed(module['route']);
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: module['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      module['icon'],
                      color: module['color'],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    module['name'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
