import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/bindings/initial_binding.dart';
import 'package:spendly/res/routes/routes.dart';

import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/utils/app_translations.dart';
import 'package:spendly/utils/app_themes.dart';

import 'package:spendly/res/routes/routes_name.dart';

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
      title: "DailyBachaat",
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeController.theme,
      translations: AppTranslations(),
      locale: localizationController.getLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppRoutes.appRoutes(),
      initialRoute: RoutesName.splashScreen,
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
