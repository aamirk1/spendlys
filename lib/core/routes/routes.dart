import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/bindings/home_binding.dart';
import 'package:spendly/core/bindings/auth_binding.dart';
import 'package:spendly/features/lend_borrow/presentation/screens/loan_detail_screen.dart';
import 'package:spendly/features/income_expense/presentation/screens/income_expense_home.dart';
import 'package:spendly/core/routes/views_routes.dart';
import 'package:spendly/features/lend_borrow/presentation/screens/loan_list_screen.dart';
import 'package:spendly/features/lend_borrow/presentation/screens/add_loan_screen.dart';
import 'package:spendly/features/chat/presentation/screens/chat_view.dart';
import 'package:spendly/features/chat/presentation/screens/message_view.dart';
import 'package:spendly/features/user_profile/presentation/screens/app_settings_screen.dart';
import 'package:spendly/features/user_profile/presentation/screens/notifications_screen.dart';
import 'package:spendly/features/user_profile/presentation/screens/need_help_screen.dart';
import 'package:spendly/features/business/presentation/screens/business_home_view.dart';
import 'package:spendly/features/business/presentation/screens/business_profile_view.dart';
import 'package:spendly/features/business/presentation/screens/customers_list.dart';
import 'package:spendly/features/business/presentation/screens/create_invoice.dart';
import 'package:spendly/features/business/presentation/screens/invoice_list.dart';
import 'package:spendly/features/business/presentation/screens/create_quotation.dart';
import 'package:spendly/features/business/presentation/screens/quotation_list.dart';
import 'package:spendly/features/business/presentation/screens/quotation_detail.dart';
import 'package:spendly/features/business/presentation/screens/invoice_detail.dart';
import 'package:spendly/features/business/presentation/screens/edit_invoice.dart';
import 'package:spendly/features/business/presentation/screens/edit_quotation.dart';

import 'package:spendly/features/business/presentation/screens/inventory/inventory_list_view.dart';
import 'package:spendly/features/premium/presentation/screens/premium_screen.dart';
import 'package:spendly/features/premium/presentation/screens/benefit_onboarding_screen.dart';
import 'package:spendly/features/auth/presentation/screens/otp_verification_screen.dart';

/// Shared transition config — rightToLeftWithFade at 280ms is smooth and modern.
const _kFast = Duration(milliseconds: 280);
const _kTransition = Transition.rightToLeftWithFade;

class AppRoutes {
  static List<GetPage<dynamic>> appRoutes() => [
        GetPage(
            name: RoutesName.splashScreen,
            page: () => DailyBachatSplashScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.onboardingView,
            page: () => OnboardingScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.welcomeView,
            page: () => const WelcomeScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.loginView,
            page: () => SignInScreen(),
            binding: AuthBinding(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.signupView,
            page: () => SignInScreen(),
            binding: AuthBinding(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.otpVerifyView,
            page: () => OtpVerificationScreen(),
            binding: AuthBinding(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.forgotPasswordView,
            page: () => ForgotPasswordScreen(),
            binding: AuthBinding(),
            transitionDuration: _kFast,
            transition: _kTransition),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.homeView,
            page: () => const HomeScreen(),
            binding: HomeBinding(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.profileView,
            page: () => ProfileScreen(
                  myUser: Get.arguments is MyUser
                      ? Get.arguments
                      : MyUser.fromStorage(),
                ),
            transitionDuration: _kFast,
            transition: _kTransition),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.expenseView,
            page: () => AddExpense(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.incomeView,
            page: () => AddIncome(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.viewAllExpenses,
            page: () => ViewAllExpense(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.categorywiseviewAllExpenses,
            page: () => CategorywiseViewAllExpense(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.viewAllIncome,
            page: () => ViewAllIncome(),
            transitionDuration: _kFast,
            transition: _kTransition),

// ---------------------------------------------------------------------------------
        GetPage(
            name: RoutesName.addLendBorrowView,
            page: () {
              final args = Get.arguments;
              if (args is MyUser) {
                return LoansScreen(myUser: args);
              } else if (args is Map) {
                return LoansScreen(
                  myUser: args['myUser'] ?? MyUser.fromStorage(),
                );
              } else {
                return LoansScreen(myUser: MyUser.fromStorage());
              }
            },
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.addLoanScreen,
            page: () {
              final args = Get.arguments;
              if (args is MyUser) {
                return AddLoanScreen(
                  myUser: args,
                );
              } else if (args is Map) {
                return AddLoanScreen(
                  myUser: args['myUser'] ?? MyUser.fromStorage(),
                  loan: args['loan'],
                );
              } else {
                return AddLoanScreen(
                  myUser: MyUser.fromStorage(),
                );
              }
            },
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.viewLoan,
            page: () {
              final args = Get.arguments;
              if (args is Map && args['loan'] != null) {
                return LoanDetailScreen(
                  loan: args['loan'],
                );
              }
              return const Scaffold(
                  body: Center(child: Text("Invalid Loan Arguments")));
            },
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.chatListView,
            page: () => const ChatView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.messageView,
            page: () => const MessageView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.appSettingScreen,
            page: () => const AppSettingsScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.notificationsScreen,
            page: () => const NotificationsScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.needHelpScreen,
            page: () => const NeedHelpScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.editProfile,
            page: () => EditProfileScreen(
                  myUser: Get.arguments is MyUser
                      ? Get.arguments
                      : MyUser.fromStorage(),
                ),
            transitionDuration: _kFast,
            transition: _kTransition),

        // Business Module
        GetPage(
            name: RoutesName.businessHome,
            page: () => const BusinessHomeView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.businessProfile,
            page: () => const BusinessProfileView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.customersList,
            page: () => const CustomersListView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.incomeExpenseHome,
            page: () => const IncomeExpenseHome(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.createInvoice,
            page: () => const CreateInvoiceView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.invoiceList,
            page: () => const InvoiceListView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.editInvoice,
            page: () => const EditInvoiceView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.createQuotation,
            page: () => const CreateQuotationView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.quotationList,
            page: () => const QuotationListView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.editQuotation,
            page: () => const EditQuotationView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.viewQuotation,
            page: () => const QuotationDetailView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.viewInvoice,
            page: () => const InvoiceDetailView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.inventoryList,
            page: () => const InventoryListView(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.premiumView,
            page: () => const PremiumScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
        GetPage(
            name: RoutesName.benefitOnboarding,
            page: () => const BenefitOnboardingScreen(),
            transitionDuration: _kFast,
            transition: _kTransition),
      ];
}
