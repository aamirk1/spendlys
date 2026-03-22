import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/screens/ledger/ledger_screen.dart';
import 'package:spendly/screens/home/views/main_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/profile_screen.dart';
import 'package:spendly/screens/business/business_home_view.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MyUser myUser = Get.arguments;
  int index = 0;

  late final List<Widget> screens = [
    MainScreen(myUser: myUser),
    const BusinessHomeView(),
    LedgerScreen(myUser: myUser),
    ProfileScreen(myUser: myUser),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            onTap: (value) {
              setState(() {
                index = value;
              });
            },
            currentIndex: index,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.house_fill),
                activeIcon: const Icon(CupertinoIcons.house_fill),
                label: 'home'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.briefcase),
                activeIcon: const Icon(CupertinoIcons.briefcase_fill),
                label: 'business'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.list_bullet),
                activeIcon: const Icon(CupertinoIcons.list_bullet_indent),
                label: 'ledger'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.person),
                activeIcon: const Icon(CupertinoIcons.person_fill),
                label: 'profile'.tr,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (index == 2) {
            Get.toNamed(RoutesName.addLoanScreen,
                arguments: {'controller': LoanController(), 'myUser': myUser});
          } else {
            Get.toNamed(RoutesName.incomeExpenseHome, arguments: myUser);
          }
        },
        shape: const CircleBorder(),
        elevation: 8,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 30),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: screens,
      ),
    );
  }
}
