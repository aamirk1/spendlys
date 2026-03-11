import 'package:get/get.dart';
import 'package:spendly/res/routes/views_routes.dart';
import 'package:spendly/screens/add_lend_borrow/loan_list_screen.dart';
import 'package:spendly/screens/chat/chat_view.dart';
import 'package:spendly/screens/chat/message_view.dart';
import 'package:spendly/screens/home/views/profile_screens/app_settings_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/notifications_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/need_help_screen.dart';
import 'package:spendly/screens/business/business_home_view.dart';
import 'package:spendly/screens/business/business_profile_view.dart';
import 'package:spendly/res/routes/routes_name.dart';

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
        GetPage(
            name: RoutesName.chatListView,
            page: () => const ChatView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.messageView,
            page: () => const MessageView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.appSettingScreen,
            page: () => const AppSettingsScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.notificationsScreen,
            page: () => const NotificationsScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.needHelpScreen,
            page: () => const NeedHelpScreen(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),

        // Business Module
        GetPage(
            name: RoutesName.businessHome,
            page: () => const BusinessHomeView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.businessProfile,
            page: () => const BusinessProfileView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
      ];
}
