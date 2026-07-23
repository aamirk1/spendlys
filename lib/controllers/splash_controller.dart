import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/services/app_update_service.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SplashController extends GetxController {
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 1. App Update Check (Triggered in the background, does not block the splash transition)
    final updateService = Get.find<AppUpdateService>();
    updateService.checkForUpdate();

    // 2. Wait for the splash screen entrance and progress bar animations to complete (1.2s)
    await Future.delayed(const Duration(milliseconds: 1200));

    // 3. Check if user is logged in
    bool isLoggedIn = _box.read("isLoggedIn") ?? false;

    if (isLoggedIn) {
      try {
        // Reconstruct MyUser from local storage and navigate immediately
        MyUser myUser = MyUser.fromStorage();
        Get.offAllNamed(RoutesName.homeView, arguments: myUser);
      } catch (e) {
        print("Error reading user from storage: $e");
        Get.offAllNamed(RoutesName.loginView);
      }
    } else {
      Get.offAllNamed(RoutesName.loginView);
    }
  }
}
