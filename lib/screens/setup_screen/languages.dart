// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/controllers/setup_controller.dart';

// class LanguageSelection extends StatelessWidget {
//   final SetupController controller = Get.find();
//   final List<String> languages = ['English', 'Spanish', 'French', 'German'];

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       children: languages
//           .map((lang) => ListTile(
//                 title: Text(lang),
//                 leading: Obx(
//                   () => Radio(
//                     value: lang,
//                     groupValue: controller.selectedLanguage.value,
//                     onChanged: (value) =>
//                         controller.selectedLanguage.value = value!,
//                   ),
//                 ),
//               ))
//           .toList(),
//     );
//   }
// }
