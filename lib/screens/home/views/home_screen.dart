// import 'dart:math';
// import 'package:get/get.dart';
// import 'package:spendly/models/myuser.dart';
// import 'package:spendly/screens/add_income_and_expense/income_expense_home.dart';
// import 'package:spendly/screens/add_lend_borrow/loan_list_screen.dart';
// import 'package:spendly/screens/home/views/main_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// import '../../stats/stats.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final MyUser myUser = Get.arguments;
//   int index = 0;
//   late Color selectedItem = Colors.blue;
//   Color unselectedItem = Colors.grey;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         bottomNavigationBar: ClipRRect(
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//           child: BottomNavigationBar(
//               onTap: (value) {
//                 setState(() {
//                   index = value;
//                 });
//               },
//               showSelectedLabels: false,
//               showUnselectedLabels: false,
//               elevation: 3,
//               items: [
//                 BottomNavigationBarItem(
//                     icon: Icon(CupertinoIcons.home,
//                         color: index == 0 ? selectedItem : unselectedItem),
//                     label: 'Home'),
//                 BottomNavigationBarItem(
//                     icon: Icon(CupertinoIcons.graph_square_fill,
//                         color: index == 1 ? selectedItem : unselectedItem),
//                     label: 'Stats')
//               ]),
//         ),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//         floatingActionButton: FloatingActionButton(
//           onPressed: () async {
//             Get.to(() => IncomeExpenseHome(), arguments: myUser);
//           },
//           shape: const CircleBorder(),
//           child: Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   colors: [
//                     Theme.of(context).colorScheme.tertiary,
//                     Theme.of(context).colorScheme.secondary,
//                     Theme.of(context).colorScheme.primary,
//                   ],
//                   transform: const GradientRotation(pi / 4),
//                 )),
//             child: const Icon(CupertinoIcons.add),
//           ),
//         ),
//         body: index == 0
//             ? MainScreen(myUser: myUser)
//             : LoansScreen(
//                 myUser: myUser,
//               ));
//     // body: index == 0 ? MainScreen(myUser: myUser) : const StatScreen());
//   }
// }

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/add_income_and_expense/income_expense_home.dart';
import 'package:spendly/screens/add_lend_borrow/add_loan_screen.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/screens/add_lend_borrow/loan_list_screen.dart';
import 'package:spendly/screens/home/views/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MyUser myUser = Get.arguments;
  // final LoanController loanController = Get.arguments;
  int index = 0;
  late Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
              onTap: (value) {
                setState(() {
                  index = value;
                });
              },
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 3,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.home,
                        color: index == 0 ? selectedItem : unselectedItem),
                    label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.graph_square_fill,
                        color: index == 1 ? selectedItem : unselectedItem),
                    label: 'Stats')
              ]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (index == 0) {
              Get.to(() => IncomeExpenseHome(), arguments: myUser);
            } else if (index == 1) {
              Get.to(() => AddLoanScreen(
                    controller: LoanController(),
                    myUser: myUser,
                  ));
            }
          },
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
        body: index == 0
            ? MainScreen(
                myUser: myUser,
              )
            : LoansScreen(
                myUser: myUser,
              ));
  }
}
