// // First, add these dependencies to your pubspec.yaml:
// // 
// // dependencies:
// //   flutter:
// //     sdk: flutter
// //   get: ^4.6.5
// //   firebase_core: ^2.15.1
// //   firebase_auth: ^4.9.0
// //   cloud_firestore: ^4.9.1
// //   firebase_storage: ^11.2.6
// //   image_picker: ^1.0.4
// //   google_mlkit_face_detection: ^0.8.0
// //   intl: ^0.18.1
// //   country_picker: ^2.0.20
// //   lottie: ^2.6.0

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:country_picker/country_picker.dart';
// import 'package:lottie/lottie.dart';
// import 'package:intl/intl.dart';

// // Main colors from your brand
// class AppColors {
//   static const Color primary = Color(0xFF00B2E7);
//   static const Color secondary = Color(0xFFE064F7);
//   static const Color tertiary = Color(0xFFFF8D6C);
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // Initialize Firebase
//   // await Firebase.initializeApp();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Onboarding Flow',
//       theme: ThemeData(
//         primaryColor: AppColors.primary,
//         colorScheme: ColorScheme.light(
//           primary: AppColors.primary,
//           secondary: AppColors.secondary,
//         ),
//       ),
//       home: OnboardingFlow(),
//     );
//   }
// }

// class SetupController extends GetxController {
//   final RxString selectedCurrency = 'USD'.obs;
//   final RxString selectedLanguage = 'English'.obs;
//   final Rx<Country?> selectedCountry = Rx<Country?>(null);
//   final Rx<File?> profileImage = Rx<File?>(null);
//   final RxBool isUploading = false.obs;
//   final RxBool faceDetected = false.obs;
//   final RxInt currentStep = 0.obs;
  
//   // List of available currencies
//   final List<String> currencies = [
//     'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CNY', 'INR'
//   ];
  
//   // List of available languages
//   final List<Map<String, String>> languages = [
//     {'code': 'en', 'name': 'English'},
//     {'code': 'es', 'name': 'Spanish'},
//     {'code': 'fr', 'name': 'French'},
//     {'code': 'de', 'name': 'German'},
//     {'code': 'zh', 'name': 'Chinese'},
//     {'code': 'ja', 'name': 'Japanese'},
//     {'code': 'ar', 'name': 'Arabic'},
//     {'code': 'hi', 'name': 'Hindi'},
//   ];
  
//   // Face detector instance
//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableContours: true,
//       enableClassification: true,
//     ),
//   );
  
//   void nextStep() {
//     if (currentStep.value < 3) {
//       currentStep.value++;
//     }
//   }
  
//   void previousStep() {
//     if (currentStep.value > 0) {
//       currentStep.value--;
//     }
//   }
  
//   Future<void> pickImage(ImageSource source) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: source,
//         imageQuality: 80,
//       );
      
//       if (image != null) {
//         isUploading.value = true;
//         faceDetected.value = false;
        
//         // Check for face in the image
//         final File imageFile = File(image.path);
//         final InputImage inputImage = InputImage.fromFile(imageFile);
//         final List<Face> faces = await _faceDetector.processImage(inputImage);
        
//         if (faces.isNotEmpty) {
//           profileImage.value = imageFile;
//           faceDetected.value = true;
//         } else {
//           Get.snackbar(
//             'No Face Detected',
//             'Please upload an image containing a face.',
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         }
//         isUploading.value = false;
//       }
//     } catch (e) {
//       isUploading.value = false;
//       Get.snackbar(
//         'Error',
//         'Failed to process image: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
  
//   Future<bool> saveUserPreferences() async {
//     try {
//       isUploading.value = true;
//       final User? user = FirebaseAuth.instance.currentUser;
      
//       if (user == null) {
//         throw Exception('User not authenticated');
//       }
      
//       String? profileImageUrl;
      
//       // Upload profile image if available
//       if (profileImage.value != null) {
//         final Reference storageRef = FirebaseStorage.instance
//             .ref()
//             .child('profile_images')
//             .child('${user.uid}.jpg');
            
//         await storageRef.putFile(profileImage.value!);
//         profileImageUrl = await storageRef.getDownloadURL();
//       }
      
//       // Save user preferences to Firestore
//       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//         'currency': selectedCurrency.value,
//         'language': selectedLanguage.value,
//         'country': selectedCountry.value?.displayNameNoCountryCode ?? '',
//         'countryCode': selectedCountry.value?.countryCode ?? '',
//         'profileImageUrl': profileImageUrl,
//         'setupCompleted': true,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
      
//       isUploading.value = false;
//       return true;
//     } catch (e) {
//       isUploading.value = false;
//       Get.snackbar(
//         'Error',
//         'Failed to save preferences: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return false;
//     }
//   }
  
//   @override
//   void onClose() {
//     _faceDetector.close();
//     super.onClose();
//   }
// }

// class OnboardingFlow extends StatelessWidget {
//   final SetupController controller = Get.put(SetupController());
//   final PageController pageController = PageController();
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Progress indicator
//             Obx(() => LinearProgressIndicator(
//               value: (controller.currentStep.value + 1) / 4,
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//             )),
            
//             // Skip button
//             Align(
//               alignment: Alignment.topRight,
//               child: TextButton(
//                 onPressed: () => _confirmSkip(context),
//                 child: Text('Skip', style: TextStyle(color: AppColors.tertiary)),
//               ),
//             ),
            
//             // Main content
//             Expanded(
//               child: Obx(() => PageView(
//                 controller: pageController,
//                 physics: NeverScrollableScrollPhysics(),
//                 onPageChanged: (index) => controller.currentStep.value = index,
//                 children: [
//                   WelcomeScreen(),
//                   CurrencyLanguageScreen(),
//                   CountrySelectionScreen(),
//                   ProfilePictureScreen(),
//                 ],
//               )),
//             ),
            
//             // Navigation buttons
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Obx(() {
//                 return Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Back button
//                     controller.currentStep.value > 0
//                         ? TextButton(
//                             onPressed: () {
//                               controller.previousStep();
//                               pageController.animateToPage(
//                                 controller.currentStep.value,
//                                 duration: Duration(milliseconds: 300),
//                                 curve: Curves.easeInOut,
//                               );
//                             },
//                             child: Text('Back'),
//                           )
//                         : SizedBox(width: 80),
                    
//                     // Next/Finish button
//                     ElevatedButton(
//                       onPressed: controller.isUploading.value
//                           ? null
//                           : () async {
//                               if (controller.currentStep.value == 3) {
//                                 // Final step - save preferences and navigate to home
//                                 final success = await controller.saveUserPreferences();
//                                 if (success) {
//                                   // Navigate to home screen
//                                   Get.offAll(() => HomeScreen());
//                                 }
//                               } else {
//                                 // Go to next step
//                                 controller.nextStep();
//                                 pageController.animateToPage(
//                                   controller.currentStep.value,
//                                   duration: Duration(milliseconds: 300),
//                                   curve: Curves.easeInOut,
//                                 );
//                               }
//                             },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: Text(
//                         controller.currentStep.value == 3 ? 'Finish' : 'Next',
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   void _confirmSkip(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Skip Setup?'),
//         content: Text(
//           'You can always change these settings later. '
//           'Would you like to skip the setup process?'
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('No'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Save default preferences
//               controller.saveUserPreferences().then((success) {
//                 if (success) {
//                   // Navigate to home screen
//                   Get.offAll(() => HomeScreen());
//                 }
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//             ),
//             child: Text('Yes', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Welcome Screen
// class WelcomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Animation
//           Lottie.network(
//             'https://assets2.lottiefiles.com/packages/lf20_8pL7DHZXvo.json',
//             height: 200,
//           ),
//           SizedBox(height: 40),
//           Text(
//             'Welcome!',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Let\'s set up your account to get started.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'We\'ll need to collect some basic information to customize your experience.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Currency and Language Selection Screen
// class CurrencyLanguageScreen extends StatelessWidget {
//   final SetupController controller = Get.find<SetupController>();
  
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Animation
//           Center(
//             child: Lottie.network(
//               'https://assets3.lottiefiles.com/packages/lf20_rbtawnwz.json',
//               height: 150,
//             ),
//           ),
//           SizedBox(height: 30),
          
//           // Currency selection
//           Text(
//             'Select Currency',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: AppColors.secondary,
//             ),
//           ),
//           SizedBox(height: 16),
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Obx(() => DropdownButtonHideUnderline(
//               child: ButtonTheme(
//                 alignedDropdown: true,
//                 child: DropdownButton<String>(
//                   isExpanded: true,
//                   value: controller.selectedCurrency.value,
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.selectedCurrency.value = value;
//                     }
//                   },
//                   items: controller.currencies
//                       .map((currency) => DropdownMenuItem(
//                             value: currency,
//                             child: Text(
//                               '$currency - ${_getCurrencySymbol(currency)}',
//                               style: TextStyle(fontSize: 16),
//                             ),
//                           ))
//                       .toList(),
//                   icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                 ),
//               ),
//             )),
//           ),
//           SizedBox(height: 30),
          
//           // Language selection
//           Text(
//             'Select Language',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: AppColors.secondary,
//             ),
//           ),
//           SizedBox(height: 16),
//           Container(
//             height: 250,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Obx(() => ListView.separated(
//               padding: EdgeInsets.symmetric(vertical: 8),
//               itemCount: controller.languages.length,
//               separatorBuilder: (context, index) => Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final language = controller.languages[index];
//                 final isSelected = controller.selectedLanguage.value == language['name'];
                
//                 return ListTile(
//                   title: Text(language['name']!),
//                   trailing: isSelected
//                       ? Icon(Icons.check_circle, color: AppColors.primary)
//                       : null,
//                   tileColor: isSelected ? Colors.grey[100] : null,
//                   onTap: () {
//                     controller.selectedLanguage.value = language['name']!;
//                   },
//                 );
//               },
//             )),
//           ),
//         ],
//       ),
//     );
//   }
  
//   String _getCurrencySymbol(String currencyCode) {
//     switch (currencyCode) {
//       case 'USD': return '₹';
//       case 'EUR': return '€';
//       case 'GBP': return '£';
//       case 'JPY': return '¥';
//       case 'CAD': return 'C₹';
//       case 'AUD': return 'A₹';
//       case 'CNY': return '¥';
//       case 'INR': return '₹';
//       default: return currencyCode;
//     }
//   }
// }

// // Country Selection Screen
// class CountrySelectionScreen extends StatelessWidget {
//   final SetupController controller = Get.find<SetupController>();
  
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Animation
//           Center(
//             child: Lottie.network(
//               'https://assets5.lottiefiles.com/packages/lf20_AMBEWz.json',
//               height: 200,
//             ),
//           ),
//           SizedBox(height: 30),
          
//           Text(
//             'Select Your Country',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: AppColors.tertiary,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'This helps us provide relevant content based on your location.',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//           SizedBox(height: 30),
          
//           // Selected country display
//           Obx(() {
//             if (controller.selectedCountry.value != null) {
//               final country = controller.selectedCountry.value!;
//               return Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors.primary.withOpacity(0.5)),
//                 ),
//                 child: Row(
//                   children: [
//                     Text(
//                       country.flagEmoji,
//                       style: TextStyle(fontSize: 24),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             country.name,
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             country.displayNameNoCountryCode,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             } else {
//               return Container();
//             }
//           }),
          
//           SizedBox(height: 24),
          
//           // Country picker button
//           ElevatedButton.icon(
//             onPressed: () {
//               showCountryPicker(
//                 context: context,
//                 showPhoneCode: false,
//                 countryListTheme: CountryListThemeData(
//                   borderRadius: BorderRadius.circular(12),
//                   inputDecoration: InputDecoration(
//                     hintText: 'Search country',
//                     prefixIcon: Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 onSelect: (Country country) {
//                   controller.selectedCountry.value = country;
//                 },
//               );
//             },
//             icon: Icon(Icons.public, color: Colors.white),
//             label: Text(
//               controller.selectedCountry.value == null
//                   ? 'Select Country'
//                   : 'Change Country',
//               style: TextStyle(color: Colors.white),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Profile Picture Screen
// class ProfilePictureScreen extends StatelessWidget {
//   final SetupController controller = Get.find<SetupController>();
  
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           SizedBox(height: 16),
//           Text(
//             'Add Profile Picture',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 8),
//           Text(
//             'We use face recognition to ensure your profile picture contains a face.',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 40),
          
//           // Profile image
//           Obx(() {
//             return Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: controller.faceDetected.value 
//                     ? AppColors.secondary 
//                     : Colors.grey[300]!,
//                   width: 4,
//                 ),
//                 image: controller.profileImage.value != null
//                     ? DecorationImage(
//                         image: FileImage(controller.profileImage.value!),
//                         fit: BoxFit.cover,
//                       )
//                     : null,
//               ),
//               child: controller.profileImage.value == null
//                   ? Icon(
//                       Icons.person,
//                       size: 100,
//                       color: Colors.grey[400],
//                     )
//                   : null,
//             );
//           }),
          
//           SizedBox(height: 30),
          
//           // Upload buttons
//           Obx(() {
//             if (controller.isUploading.value) {
//               return CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//               );
//             }
            
//             return Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Camera button
//                 ElevatedButton.icon(
//                   onPressed: () => controller.pickImage(ImageSource.camera),
//                   icon: Icon(Icons.camera_alt, color: Colors.white),
//                   label: Text('Camera', style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 16),
                
//                 // Gallery button
//                 ElevatedButton.icon(
//                   onPressed: () => controller.pickImage(ImageSource.gallery),
//                   icon: Icon(Icons.photo_library, color: Colors.white),
//                   label: Text('Gallery', style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.secondary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }),
          
//           SizedBox(height: 16),
          
//           // Skip text
//           TextButton(
//             onPressed: () {
//               controller.profileImage.value = null;
//               controller.faceDetected.value = false;
//             },
//             child: Text(
//               'Skip this step',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 decoration: TextDecoration.underline,
//               ),
//             ),
//           ),
          
//           Spacer(),
          
//           // Info box
//           Obx(() {
//             if (controller.faceDetected.value) {
//               return Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green[300]!),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Face detected successfully! You look great!',
//                         style: TextStyle(color: Colors.green[800]),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             } else {
//               return Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.info_outline, color: AppColors.primary),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Your profile picture should clearly show your face.',
//                         style: TextStyle(color: Colors.grey[700]),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//           }),
//         ],
//       ),
//     );
//   }
// }

// // Home Screen (placeholder for after setup)
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home'),
//         backgroundColor: AppColors.primary,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Lottie.network(
//               'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json',
//               height: 200,
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Setup Completed Successfully!',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.primary,
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Welcome to the app.',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 // Here you would typically navigate to the main app experience
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.secondary,
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: Text(
//                 'Get Started',
//                 style: TextStyle(fontSize: 18, color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }