import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:intl/intl.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/res/utils/colors.dart';
import 'loan_controller.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatelessWidget {
  final MyUser myUser;

  LoansScreen({required this.myUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoanController controller = Get.put(LoanController(myUser: myUser));

    // Fetch loans on screen build
    controller.fetchLoans();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Loans",
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
            tabs: [
              Tab(text: "Borrowed"),
              Tab(text: "Lent"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // Borrowed Loans
            Obx(() => controller.borrowed.isEmpty
                ? Center(
                    child: Text("No borrowed loans",
                        style: TextStyle(color: AppColors.grey)))
                : ListView.builder(
                    itemCount: controller.borrowed.length,
                    itemBuilder: (context, index) {
                      final loan = controller.borrowed[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(loan.personName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "₹${loan.amount} • Due: ${loan.expectedReturnDate != null ? DateFormat.yMMMd().format(loan.expectedReturnDate!) : 'N/A'}",
                            style:
                                TextStyle(fontSize: 16, color: AppColors.grey),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              Get.dialog(
                                AlertDialog(
                                  title: const Text("Delete Loan"),
                                  content: const Text(
                                      "Are you sure you want to delete this loan?"),
                                  backgroundColor: AppColors.red50,
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(Get.context!,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.purple),
                                      onPressed: () async {
                                        await controller
                                            .deleteLoan(loan.id ?? '');
                                        // Close dialog reliably
                                        Navigator.of(Get.context!,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                      child: const Text("Yes, Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_forever,
                                color: AppColors.red, size: 28),
                          ),
                          onTap: () => Get.to(() => LoanDetailScreen(
                              loan: loan, controller: controller)),
                        ),
                      );
                    },
                  )),

            // Lent Loans
            Obx(() => controller.lent.isEmpty
                ? Center(
                    child: Text("No lent loans",
                        style: TextStyle(color: AppColors.grey)))
                : ListView.builder(
                    itemCount: controller.lent.length,
                    itemBuilder: (context, index) {
                      final loan = controller.lent[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(loan.personName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "₹${loan.amount} • Due: ${loan.expectedReturnDate != null ? DateFormat.yMMMd().format(loan.expectedReturnDate!) : 'N/A'}",
                            style:
                                TextStyle(fontSize: 16, color: AppColors.grey),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              Get.dialog(
                                AlertDialog(
                                  title: const Text("Delete Loan"),
                                  content: const Text(
                                      "Are you sure you want to delete this loan?"),
                                  backgroundColor: AppColors.red50,
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(Get.context!,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.purple),
                                      onPressed: () async {
                                        await controller
                                            .deleteLoan(loan.id ?? '');
                                        // Close dialog reliably
                                        Navigator.of(Get.context!,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                      child: const Text("Yes, Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_forever,
                                color: AppColors.red, size: 28),
                          ),
                          onTap: () => Get.to(() => LoanDetailScreen(
                              loan: loan, controller: controller)),
                        ),
                      );
                    },
                  )),
          ],
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.to(() => AddLoanScreen(controller: controller)),
          shape: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary,
                  ],
                  transform: const GradientRotation(pi / 4),
                )),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: AppColors.purple,
        //   child: Icon(Icons.add, color: AppColors.white),
        //   onPressed: () => Get.to(() => AddLoanScreen(controller: controller)),
        // ),
      ),
    );
  }
}
