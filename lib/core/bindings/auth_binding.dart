import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/controllers/auth_controller.dart';
import 'package:spendly/services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignInController());
    Get.lazyPut(() => AuthController());
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut(() => AuthService());
    }
  }
}
