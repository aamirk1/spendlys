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
        onPressed: () {
          _showActionSheet(context);
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

  void _showActionSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'choose_action'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    context: context,
                    icon: CupertinoIcons.arrow_up_down_circle_fill,
                    label: 'income_expense'.tr,
                    color: Colors.indigo,
                    onTap: () {
                      Get.back();
                      Get.toNamed(RoutesName.incomeExpenseHome,
                          arguments: myUser);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    context: context,
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    label: 'loan'.tr,
                    color: Colors.deepPurple,
                    onTap: () {
                      Get.back();
                      Get.toNamed(RoutesName.addLoanScreen, arguments: {
                        'controller': LoanController(),
                        'myUser': myUser
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      elevation: 0,
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
