import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/bindings/initial_binding.dart';
import 'package:spendly/res/routes/routes.dart';

import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/utils/app_translations.dart';
import 'package:spendly/utils/app_themes.dart';

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
      getPages: AppRoutes.appRoutes(),
      initialRoute: '/splash',
      builder: (context, child) {
        return child!;
      },
    );
  }
}
