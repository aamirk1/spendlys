import 'package:get/get.dart';
import 'package:spendly/res/routes/views_routes.dart';
import 'package:spendly/screens/add_lend_borrow/loan_list_screen.dart';

class AppRoutes {
  static appRoutes() => [
        GetPage(
            name: RoutesName.splashScreen,
            page: () => SplashScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRight),
        GetPage(
            name: RoutesName.onboardingView,
            page: () => OnboardingScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRight),
        GetPage(
            name: RoutesName.welcomeView,
            page: () => const WelcomeScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.loginView,
            page: () => SignInScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.signupView,
            page: () => SignUpScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.homeView,
            page: () => HomeScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.profileView,
            page: () => ProfileScreen(
                  myUser: Get.arguments,
                ),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.expenseView,
            page: () => AddExpense(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.incomeView,
            page: () => AddIncome(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.viewAllExpenses,
            page: () => ViewAllExpense(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.categorywiseviewAllExpenses,
            page: () => CategorywiseViewAllExpense(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.viewAllIncome,
            page: () => ViewAllIncome(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.addLendBorrowView,
            page: () => LoansScreen(
                  myUser: Get.arguments,
                ),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
      ];
}
