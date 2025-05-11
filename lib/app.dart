import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/bindings/initial_binding.dart';
import 'package:spendly/res/routes/routes.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/network_checker.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      title: "DailyBachat",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade100,
          onSurface: Colors.black,
          primary: const Color(0xFF00B2E7),
          secondary: const Color(0xFFE064F7),
          tertiary: const Color(0xFFFF8D6C),
          outline: Colors.grey,
        ),
      ),
      getPages: AppRoutes.appRoutes(),
      initialRoute: RoutesName.splashScreen,
      builder: (context, child) {
        return NetworkChecker(child: child!);
      },
    );
  }
}
