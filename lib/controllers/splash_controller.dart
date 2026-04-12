import 'package:get/get.dart';
import 'package:spendly/services/auth_storage_service.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SplashController extends GetxController {
  final AuthStorageService _storageService = Get.put(AuthStorageService());

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for 2 seconds as requested
    await Future.delayed(const Duration(seconds: 2));

    // Check if user ID exists in secure storage
    String? uid = await _storageService.getUser();

    if (uid != null) {
      Get.offAllNamed(RoutesName.homeView);
    } else {
      Get.offAllNamed(RoutesName.loginView);
    }
  }
}
