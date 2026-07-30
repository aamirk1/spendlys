import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationController extends GetxController {
  final box = GetStorage();
  final currentLocale = 'en_US'.obs;

  @override
  void onInit() {
    super.onInit();
    String? storedLocale = box.read('languageCode');
    if (storedLocale != null) {
      currentLocale.value = storedLocale;
    } else {
      currentLocale.value = Get.deviceLocale?.toString() ?? 'en_US';
    }
  }

  void changeLanguage(String languageCode, String countryCode) {
    var locale = Locale(languageCode, countryCode);
    Get.updateLocale(locale);
    currentLocale.value = '${languageCode}_$countryCode';
    box.write('languageCode', currentLocale.value);
  }

  Locale get getLocale {
    if (currentLocale.value.contains('_')) {
      List<String> parts = currentLocale.value.split('_');
      return Locale(parts[0], parts[1]);
    }
    return const Locale('en', 'US');
  }
}
