import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import 'package:spendly/core/di/service_locator.dart';
import 'package:spendly/core/routes/routes.dart';
import 'package:spendly/core/localization/app_translations.dart';
import 'package:spendly/core/theme/app_themes.dart';
import 'package:spendly/core/routes/routes_name.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import Cubits
import 'package:spendly/core/theme/theme_cubit.dart';
import 'package:spendly/core/localization/localization_cubit.dart';
import 'package:spendly/features/auth/presentation/cubits/onboarding_cubit.dart';
import 'package:spendly/features/user_profile/presentation/cubits/user_info_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/expense_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/income_cubit.dart';
import 'package:spendly/features/category/presentation/cubits/category_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/ledger_cubit.dart';
import 'package:spendly/features/lend_borrow/presentation/cubits/loan_cubit.dart';
import 'package:spendly/features/premium/presentation/cubits/payment_cubit.dart';
import 'package:spendly/features/chat/presentation/cubits/chat_cubit.dart';

import 'package:spendly/core/bindings/initial_binding.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (context) => getIt<ThemeCubit>()),
        BlocProvider<LocalizationCubit>(create: (context) => getIt<LocalizationCubit>()),
        BlocProvider<OnboardingCubit>(create: (context) => getIt<OnboardingCubit>()),
        BlocProvider<UserInfoCubit>(create: (context) => getIt<UserInfoCubit>()),
        BlocProvider<ExpenseCubit>(create: (context) => getIt<ExpenseCubit>()),
        BlocProvider<IncomeCubit>(create: (context) => getIt<IncomeCubit>()),
        BlocProvider<CategoryCubit>(create: (context) => getIt<CategoryCubit>()),
        BlocProvider<LedgerCubit>(create: (context) => getIt<LedgerCubit>()),
        BlocProvider<LoanCubit>(create: (context) => getIt<LoanCubit>()),
        BlocProvider<PaymentCubit>(create: (context) => getIt<PaymentCubit>()),
        BlocProvider<ChatCubit>(create: (context) => getIt<ChatCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationCubit, LocalizationState>(
            builder: (context, locState) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: "DailyBachat",
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: themeState.themeMode,
                translations: AppTranslations(),
                locale: locState.locale,
                fallbackLocale: const Locale('en', 'US'),
                initialBinding: InitialBinding(),
                getPages: AppRoutes.appRoutes(),
                initialRoute: RoutesName.splashScreen,
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
                ],
                // Global: fastest-feeling transition with no jank
                defaultTransition: Transition.fadeIn,
                // Remove overscroll glow for a smoother feel
                scrollBehavior: const _NoGlowScrollBehavior(),
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Removes the Android overscroll glow indicator for a silky-smooth scroll feel.
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // No glow
  }
}
