
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/controllers/setup_controller.dart';

// class CurrencySelection extends StatelessWidget {
//   final SetupController controller = Get.find();
//   final List<String> currencies = ['USD', 'EUR', 'INR', 'GBP'];

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       children: currencies
//           .map((currency) => ListTile(
//                 title: Text(currency),
//                 leading: Obx(
//                   () => Radio(
//                     value: currency,
//                     groupValue: controller.selectedCurrency.value,
//                     onChanged: (value) => controller.selectedCurrency.value = value!,
//                   ),
//                 ),
//               ))
//           .toList(),
//     );
//   }
// }