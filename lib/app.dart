// import 'package:flutter/material.dart';
// import 'package:spendly/app_view.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MyAppView();
//   }
// }
import 'package:flutter/material.dart';
import 'package:spendly/app_view.dart';
import 'package:spendly/no_internet_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged.expand((result) => result),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
          return const NoInternetScreen();
        }
        return MyAppView();
      },
    );
  }
}
