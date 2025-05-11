// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/controllers/faceCameraController.dart';

// class FaceCameraScreen extends StatelessWidget {
//   // final FaceCameraController controller = Get.put(FaceCameraController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Face Detection")),
//       body: Obx(() {
//         if (!controller.isCameraControllerInitialized) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         return Stack(
//           children: [
//             CameraPreview(controller.cameraController!),
//             Positioned(
//               bottom: 20,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     controller.isFaceDetected.value
//                         ? "😃 Face Detected"
//                         : "😐 No Face",
//                     style: const TextStyle(color: Colors.white, fontSize: 20),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
// }
