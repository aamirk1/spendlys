import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/ledger/ledger_screen.dart';
import 'package:spendly/screens/home/views/main_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/profile_screen.dart';
import 'package:spendly/screens/business/business_home_view.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/screens/home/widgets/radial_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MyUser myUser;
  int index = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    // 1. Resolve arguments safely to avoid TypeError: '_Map<String, int>' is not a subtype of 'MyUser'
    final args = Get.arguments;
    if (args is MyUser) {
      myUser = args;
    } else if (args is Map) {
      myUser = args['myUser'] is MyUser ? args['myUser'] : MyUser.fromStorage();
      if (args['index'] != null) {
        index = args['index'];
      }
    } else {
      myUser = MyUser.fromStorage();
    }

    // Always check premium status on home screen load
    final paymentController = Get.put(PaymentController());
    paymentController.checkPremiumStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = GetStorage();
      bool benefitOnboardingShown = box.read("benefitOnboardingShown") ?? false;
      if (!benefitOnboardingShown) {
        Get.toNamed(RoutesName.benefitOnboarding);
      }

      // Trigger background silent login and sync asynchronously
      final signInController = Get.find<SignInController>();
      signInController.performBackgroundSilentLogin();
    });

    screens = [
      MainScreen(myUser: myUser),
      const BusinessHomeView(),
      LedgerScreen(myUser: myUser),
      ProfileScreen(myUser: myUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000), // black ~5% opacity
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
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
                unselectedItemColor: Theme.of(context).disabledColor,
                elevation: 0,
                backgroundColor: Theme.of(context).cardColor,
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
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          _showActionSheet(context);
        },
        shape: const CircleBorder(),
        elevation: 8,
        child: Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [cs.tertiary, cs.secondary, cs.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child:
                const Icon(CupertinoIcons.add, color: Colors.white, size: 30),
          );
        }),
      ),
      body: IndexedStack(
        index: index,
        children: screens,
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.transparent, // Handled by overlay blur animation
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return RadialMenuOverlay(myUser: myUser);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }
}
