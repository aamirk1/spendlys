// import "package:flutter/material.dart";
// import "package:local_auth/local_auth.dart";

// //This is used for fingerprint functionality
// class AuthenticationUtils {
//   final LocalAuthentication localAuth = LocalAuthentication();

//   final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//       GlobalKey<ScaffoldMessengerState>();

//   Future<bool> isBiometricsAvailable() async {
//     final bool isBiometricsAvail = await localAuth.canCheckBiometrics;
//     return isBiometricsAvail;
//   }

//   Future<bool> authWithBiometrics() async {
//     if (await isBiometricsAvailable()) {
//       return localAuth.authenticate(
//         localizedReason: "Authenticate to login",
//         options: AuthenticationOptions(
//           biometricOnly: true,
//         ),
//       );
//     } else {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text(
//             "Biometric is not supported",
//           ),
//         ),
//       );
//       return false;
//     }
//   }

//   Future<bool> authWithPattern() async {
//     if (await isBiometricsAvailable()) {
//       return localAuth.authenticate(
//         localizedReason: "Authenticate to login",
//         options: AuthenticationOptions(biometricOnly: false, stickyAuth: true),
//       );
//     } else {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text("Device does not support Authentication"),
//         ),
//       );
//       return false;
//     }
//   }
// }
