
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/controllers/setup_controller.dart';
// class ProfilePictureUpload extends StatelessWidget {
//   final SetupController controller = Get.find();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Obx(
//           () => controller.profileImage.value != null
//               ? Image.file(File(controller.profileImage.value!.path), height: 150)
//               : Icon(Icons.person, size: 100),
//         ),
//         ElevatedButton(
//           onPressed: controller.pickImage,
//           child: Text('Upload Profile Picture'),
//         ),
//         Obx(
//           () => controller.isFaceDetected.value
//               ? Text('Face Detected ✅')
//               : Text('No Face Detected ❌'),
//         )
//       ],
//     );
//   }
// }