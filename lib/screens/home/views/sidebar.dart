import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/controllers/sign_in_controller.dart';


class SidebarController extends GetxController {
  var isExpanded = false.obs;
  void toggleSidebar() => isExpanded.value = !isExpanded.value;
}

class AnimatedSidebar extends StatelessWidget {
  final SidebarController controller = Get.put(SidebarController());
  final SignInController signInController = Get.put(SignInController());


   AnimatedSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: controller.isExpanded.value ? 250 : 70,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
                onPressed: controller.toggleSidebar,
              ),
              SizedBox(height: 20),
              sidebarButton(Icons.category, "Category", onTap: () {}, context: context),
              sidebarButton(Icons.business_center, "Business Center", onTap: () => Get.toNamed(RoutesName.businessHome), context: context),
              sidebarButton(Icons.message, "Messages", onTap: () => Get.toNamed(RoutesName.chatListView), context: context),
              sidebarButton(Icons.settings, "Settings", onTap: () {}, context: context),
              sidebarButton(Icons.logout, "Logout", onTap: () => signInController.logout(), context: context),

            ],
          ),
        ));
  }

  Widget sidebarButton(IconData icon, String label, {required VoidCallback onTap, required BuildContext context}) {
    return Obx(() => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).iconTheme.color, size: 30),
                if (controller.isExpanded.value) const SizedBox(width: 10),
                if (controller.isExpanded.value)
                  Text(label,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18)),
              ],
            ),
          ),
        ));
  }
}
