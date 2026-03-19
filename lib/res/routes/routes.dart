import 'package:get/get.dart';
import 'package:spendly/screens/add_income_and_expense/income_expense_home.dart';
import 'package:spendly/res/routes/views_routes.dart';
import 'package:spendly/screens/add_lend_borrow/loan_list_screen.dart';
import 'package:spendly/screens/chat/chat_view.dart';
import 'package:spendly/screens/chat/message_view.dart';
import 'package:spendly/screens/home/views/profile_screens/app_settings_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/notifications_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/need_help_screen.dart';
import 'package:spendly/screens/business/business_home_view.dart';
import 'package:spendly/screens/business/business_profile_view.dart';
import 'package:spendly/screens/business/customers_list.dart';
import 'package:spendly/screens/business/create_invoice.dart';
import 'package:spendly/screens/business/invoice_list.dart';
import 'package:spendly/screens/business/create_quotation.dart';
import 'package:spendly/screens/business/quotation_list.dart';
import 'package:spendly/screens/business/quotation_detail.dart';
import 'package:spendly/screens/business/invoice_detail.dart';
import 'package:spendly/screens/business/edit_invoice.dart';
import 'package:spendly/screens/business/edit_quotation.dart';

class AppRoutes {
  static List<GetPage<dynamic>> appRoutes() => [
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
        GetPage(
            name: RoutesName.customersList,
            page: () => const CustomersListView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.incomeExpenseHome,
            page: () => const IncomeExpenseHome(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.createInvoice,
            page: () => const CreateInvoiceView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.downToUp),
        GetPage(
            name: RoutesName.invoiceList,
            page: () => const InvoiceListView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.editInvoice,
            page: () => const EditInvoiceView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.rightToLeftWithFade),
        GetPage(
            name: RoutesName.createQuotation,
            page: () => const CreateQuotationView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.downToUp),
        GetPage(
            name: RoutesName.quotationList,
            page: () => const QuotationListView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.leftToRightWithFade),
        GetPage(
            name: RoutesName.editQuotation,
            page: () => const EditQuotationView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.rightToLeftWithFade),
        GetPage(
            name: RoutesName.viewQuotation,
            page: () => const QuotationDetailView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.rightToLeftWithFade),
        GetPage(
            name: RoutesName.viewInvoice,
            page: () => const InvoiceDetailView(),
            transitionDuration: const Duration(milliseconds: 250),
            transition: Transition.rightToLeftWithFade),
      ];
}
