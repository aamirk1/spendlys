// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'dart:typed_data'; // Import for Uint8List

// class FaceCameraController extends GetxController {
//   CameraController? cameraController; // Make it nullable
//   late FaceDetector faceDetector;
//   var isDetecting = false.obs;
//   var isFaceDetected = false.obs; // Track face detection status
//   CameraImage? _cameraImage;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeCamera(); // Call the async function
//     // ignore: deprecated_member_use
//     faceDetector = GoogleMlKit.vision.faceDetector(
//       FaceDetectorOptions(
//         enableContours: true,
//         enableClassification: true,
//       ),
//     );
//   }

//   Future<void> _initializeCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         print("No cameras available");
//         return; // Important: Exit if no cameras
//       }
//       cameraController = CameraController(
//         cameras.firstWhere(
//           (camera) => camera.lensDirection == CameraLensDirection.front,
//           orElse: () => cameras.first,
//         ),
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );

//       await cameraController!.initialize();
//       if (cameraController != null && cameraController!.value.isInitialized) {
//         _startImageStream(); // Start the stream after successful initialization
//       }
//     } catch (e) {
//       print("Error initializing camera: $e");
//       // Show error to user (optional, using Get)
//       Get.snackbar(
//         "Camera Error",
//         "Failed to initialize camera: $e",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }

//   void _startImageStream() {
//     if (cameraController == null || !cameraController!.value.isInitialized) {
//       return;
//     }

//     cameraController!.startImageStream((CameraImage image) async {
//       if (isDetecting.value) return;
//       isDetecting.value = true;
//       _cameraImage = image; //store the image

//       try {
//         final inputImage = _getInputImage();
//         if (inputImage == null) {
//           isDetecting.value = false;
//           return;
//         }

//         final List<Face> faces = await faceDetector.processImage(inputImage);

//         if (faces.isNotEmpty) {
//           isFaceDetected.value = true;
//           print("Face detected!");
//         } else {
//           isFaceDetected.value = false;
//         }
//       } catch (e) {
//         print("Face detection error: $e");
//         isFaceDetected.value = false; // Ensure to reset on error
//       } finally {
//         isDetecting.value = false;
//       }
//     });
//   }

//   InputImage? _getInputImage() {
//     final CameraImage? cameraImage = _cameraImage;
//     if (cameraImage == null) return null;

//     // Get image format
//     InputImageFormat inputImageFormat;
//     switch (cameraImage.format.raw) {
//       case 842083655: // YUV420
//         inputImageFormat = InputImageFormat.yuv420;
//         break;
//       case 35: // NV21
//         inputImageFormat = InputImageFormat.nv21;
//         break;
//       default:
//         inputImageFormat = InputImageFormat.yuv_420_888;
//     }

//     // Create InputImageMetadata
//     final InputImageMetadata metadata = InputImageMetadata(
//       size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
//       format: inputImageFormat,
//       rotation: InputImageRotation.rotation0deg, // Or get from camera
//       bytesPerRow: cameraImage.planes.first.bytesPerRow, // Add this line
//     );

//     // Create InputImage
//     final inputImage = InputImage.fromBytes(
//       bytes: _convertCameraImageToUint8List(cameraImage),
//       metadata: metadata,
//     );

//     return inputImage;
//   }

//   Uint8List _convertCameraImageToUint8List(CameraImage cameraImage) {
//     final bytes = <int>[];
//     for (final Plane plane in cameraImage.planes) {
//       final buffer = plane.bytes;
//       bytes.addAll(buffer);
//     }
//     return Uint8List.fromList(bytes);
//   }

//   @override
//   void onClose() {
//     if (cameraController != null) {
//       cameraController?.dispose();
//     }
//     faceDetector.close();
//     super.onClose();
//   }

//   bool get isCameraControllerInitialized =>
//       cameraController != null && cameraController!.value.isInitialized;
// }
