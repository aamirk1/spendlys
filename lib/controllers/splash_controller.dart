import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SplashController extends GetxController {
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate splash delay

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;

        if (!hasSeenOnboarding) {
          Get.offAllNamed(RoutesName.onboardingView);
        } else {
          MyUser myUser = await _getUserData(
              user.uid); // Modified: Fetch MyUser instead of passing User
          Get.offAllNamed(RoutesName.homeView,
              arguments: myUser); // Passing MyUser now
        }
      } else {
        Get.offAllNamed(RoutesName.welcomeView);
      }
    });
  }

// Helper function to convert User to MyUser
  Future<MyUser> _getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    return MyUser(
      userId: userData['userId'] ?? uid,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
    );
  }
}
