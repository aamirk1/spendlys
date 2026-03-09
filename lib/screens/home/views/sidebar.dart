import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SidebarController extends GetxController {
  var isExpanded = false.obs;
  void toggleSidebar() => isExpanded.value = !isExpanded.value;
}

class AnimatedSidebar extends StatelessWidget {
  final SidebarController controller = Get.put(SidebarController());

   AnimatedSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: controller.isExpanded.value ? 250 : 70,
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: controller.toggleSidebar,
              ),
              SizedBox(height: 20),
              sidebarButton(Icons.category, "Category", onTap: () {}),
              sidebarButton(Icons.message, "Messages", onTap: () => Get.toNamed(RoutesName.chatListView)),
              sidebarButton(Icons.settings, "Settings", onTap: () {}),
              sidebarButton(Icons.logout, "Logout", onTap: () {}),
            ],
          ),
        ));
  }

  Widget sidebarButton(IconData icon, String label, {required VoidCallback onTap}) {
    return Obx(() => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                if (controller.isExpanded.value) const SizedBox(width: 10),
                if (controller.isExpanded.value)
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ));
  }
}
