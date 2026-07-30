import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/bindings/initial_binding.dart';
import 'package:spendly/app/routes/app_pages.dart';

import 'package:spendly/app/data/services/localization_controller.dart';
import 'package:spendly/app/data/services/theme_controller.dart';
import 'package:spendly/app/utils/app_translations.dart';
import 'package:spendly/app/utils/app_themes.dart';

import 'package:firebase_analytics/firebase_analytics.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController =
        Get.put(LocalizationController());
    final ThemeController themeController = Get.put(ThemeController());

    return GetMaterialApp(
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      title: "DailyBachat",
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeController.theme,
      translations: AppTranslations(),
      locale: localizationController.getLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppPages.routes,
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
