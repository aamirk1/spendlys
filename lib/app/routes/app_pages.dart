import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:spendly/app/modules/splash/views/splash_view.dart';
import 'package:spendly/app/modules/onboarding/views/onboarding_view.dart';

import 'package:spendly/app/modules/auth/views/welcome_view.dart';
import 'package:spendly/app/modules/auth/views/sign_in_view.dart';
import 'package:spendly/app/modules/auth/views/sign_up_view.dart';
import 'package:spendly/app/modules/auth/views/otp_verification_view.dart';
import 'package:spendly/app/modules/auth/views/forgot_password_view.dart';
import 'package:spendly/app/modules/auth/bindings/auth_binding.dart';

import 'package:spendly/app/modules/home/views/home_view.dart';
import 'package:spendly/app/modules/home/bindings/home_binding.dart';

import 'package:spendly/app/modules/profile/views/profile_view.dart';
import 'package:spendly/app/modules/profile/views/edit_profile_view.dart';
import 'package:spendly/app/modules/profile/views/app_settings_view.dart';
import 'package:spendly/app/modules/profile/views/notifications_view.dart';
import 'package:spendly/app/modules/profile/views/need_help_view.dart';
import 'package:spendly/app/data/models/myuser.dart';

import 'package:spendly/app/modules/expense/views/add_expense_view.dart';
import 'package:spendly/app/modules/expense/views/add_income_view.dart';
import 'package:spendly/app/modules/expense/views/view_all_expense_view.dart';
import 'package:spendly/app/modules/expense/views/view_all_income_view.dart';
import 'package:spendly/app/modules/expense/views/categorywise_view_all_expense_view.dart';
import 'package:spendly/app/modules/expense/views/income_expense_home_view.dart';

import 'package:spendly/app/modules/loan/views/loan_list_view.dart';
import 'package:spendly/app/modules/loan/views/add_loan_view.dart';
import 'package:spendly/app/modules/loan/views/loan_detail_view.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';

import 'package:spendly/app/modules/chat/views/chat_view.dart';
import 'package:spendly/app/modules/chat/views/message_view.dart';

import 'package:spendly/app/modules/business/views/business_home_view.dart';
import 'package:spendly/app/modules/business/views/business_profile_view.dart';
import 'package:spendly/app/modules/business/views/customers_list_view.dart';
import 'package:spendly/app/modules/business/views/add_customer_view.dart';
import 'package:spendly/app/modules/business/views/customer_detail_view.dart';
import 'package:spendly/app/modules/business/views/create_invoice_view.dart';
import 'package:spendly/app/modules/business/views/invoice_list_view.dart';
import 'package:spendly/app/modules/business/views/invoice_detail_view.dart';
import 'package:spendly/app/modules/business/views/edit_invoice_view.dart';
import 'package:spendly/app/modules/business/views/create_quotation_view.dart';
import 'package:spendly/app/modules/business/views/quotation_list_view.dart';
import 'package:spendly/app/modules/business/views/quotation_detail_view.dart';
import 'package:spendly/app/modules/business/views/edit_quotation_view.dart';
import 'package:spendly/app/modules/business/views/inventory/inventory_list_view.dart';
import 'package:spendly/app/modules/business/views/inventory/add_product_view.dart';

import 'package:spendly/app/modules/premium/views/premium_view.dart';
import 'package:spendly/app/modules/premium/views/benefit_onboarding_view.dart';

import 'package:spendly/app/modules/group_split/views/group_split_list_view.dart';
import 'package:spendly/app/modules/group_split/views/add_group_split_view.dart';
import 'package:spendly/app/modules/group_split/views/group_split_detail_view.dart';
import 'package:spendly/app/modules/group_split/controllers/group_split_controller.dart';

part 'app_routes.dart';

const _kFast = Duration(milliseconds: 200);
const _kTransition = Transition.fadeIn;

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const DailyBachatSplashScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.onboarding,
      page: () => OnboardingScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.welcome,
      page: () => const WelcomeScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.login,
      page: () => SignInScreen(),
      binding: AuthBinding(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.signup,
      page: () => SignUpScreen(),
      binding: AuthBinding(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.otpVerify,
      page: () => OtpVerificationScreen(),
      binding: AuthBinding(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: AuthBinding(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.profile,
      page: () => ProfileScreen(
        myUser: Get.arguments is MyUser ? Get.arguments : MyUser.fromStorage(),
      ),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.editProfile,
      page: () => EditProfileScreen(
        myUser: Get.arguments is MyUser ? Get.arguments : MyUser.fromStorage(),
      ),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.expense,
      page: () => AddExpense(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.income,
      page: () => AddIncome(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.viewAllExpenses,
      page: () => ViewAllExpense(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.categorywiseviewAllExpenses,
      page: () => CategorywiseViewAllExpense(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.viewAllIncome,
      page: () => ViewAllIncome(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.addLendBorrow,
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
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.addLoan,
      page: () {
        final args = Get.arguments;
        if (args is MyUser) {
          return AddLoanScreen(
            myUser: args,
            controller: Get.find<LoanController>(),
          );
        } else if (args is Map) {
          return AddLoanScreen(
            myUser: args['myUser'] ?? MyUser.fromStorage(),
            controller: args['controller'] ?? Get.find<LoanController>(),
            loan: args['loan'],
          );
        } else {
          return AddLoanScreen(
            myUser: MyUser.fromStorage(),
            controller: Get.find<LoanController>(),
          );
        }
      },
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.viewLoan,
      page: () {
        final args = Get.arguments;
        if (args is Map && args['loan'] != null) {
          return LoanDetailScreen(
            loan: args['loan'],
            controller: args['controller'] ?? Get.find<LoanController>(),
          );
        }
        return const Scaffold(
          body: Center(child: Text("Invalid Loan Arguments")),
        );
      },
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.chatList,
      page: () => const ChatView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.message,
      page: () => const MessageView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.appSetting,
      page: () => const AppSettingsScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.notifications,
      page: () => const NotificationsScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.needHelp,
      page: () => const NeedHelpScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.businessHome,
      page: () => const BusinessHomeView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.businessProfile,
      page: () => const BusinessProfileView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.customersList,
      page: () => const CustomersListView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.addCustomer,
      page: () => const AddCustomerView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.customerDetail,
      page: () {
        final args = Get.arguments;
        if (args is Map<String, dynamic>) {
          return CustomerDetailView(customer: args);
        } else if (args is Map) {
          return CustomerDetailView(
            customer: Map<String, dynamic>.from(args),
          );
        }
        return const Scaffold(
          body: Center(child: Text("Invalid Customer Arguments")),
        );
      },
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.incomeExpenseHome,
      page: () => const IncomeExpenseHome(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.createInvoice,
      page: () => const CreateInvoiceView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.invoiceList,
      page: () => const InvoiceListView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.editInvoice,
      page: () => const EditInvoiceView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.createQuotation,
      page: () => const CreateQuotationView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.quotationList,
      page: () => const QuotationListView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.editQuotation,
      page: () => const EditQuotationView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.viewQuotation,
      page: () => const QuotationDetailView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.viewInvoice,
      page: () => const InvoiceDetailView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.inventoryList,
      page: () => const InventoryListView(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.addProduct,
      page: () => const AddProductScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.editProduct,
      page: () => AddProductScreen(productId: Get.arguments as String?),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.premium,
      page: () => const PremiumScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.benefitOnboarding,
      page: () => const BenefitOnboardingScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.groupSplitList,
      page: () => const GroupSplitListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => GroupSplitController());
      }),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.addGroupSplit,
      page: () => const AddGroupSplitScreen(),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
    GetPage(
      name: _Paths.groupSplitDetail,
      page: () => GroupSplitDetailScreen(
        split: Get.arguments,
      ),
      transitionDuration: _kFast,
      transition: _kTransition,
    ),
  ];
}
