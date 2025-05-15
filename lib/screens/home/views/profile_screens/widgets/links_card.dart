import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_list_tile.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/home/views/profile_screens/change_password_dialog.dart';

class LinksCard extends StatelessWidget {
  const LinksCard({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 5,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Card(
            elevation: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // CustomListTile(
                //     icon: Icon(Icons.contact_emergency_outlined),
                //     title: "Borrow/Lend Money",
                //     onPressed: () {
                //       Get.toNamed(
                //         RoutesName.addLendBorrowView,
                //       );
                //     }),
                CustomListTile(
                    icon: Icon(Icons.person),
                    title: "Customer Profile Updation",
                    onPressed: () {}),
                CustomListTile(
                    icon: Icon(Icons.contact_emergency_outlined),
                    title: "Contact Details",
                    onPressed: () {}),
                CustomListTile(
                    icon: Icon(Icons.password),
                    title: "Change Password",
                    onPressed: () {
                      Get.dialog(
                        ChangePasswordDialog(myUser: myUser),
                        barrierDismissible: false,
                      );
                    }),
              ],
            ),
          ),
        ));
  }
}
