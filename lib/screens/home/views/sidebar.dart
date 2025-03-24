import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              sidebarButton(Icons.category, "Category"),
              sidebarButton(Icons.settings, "Settings"),
              sidebarButton(Icons.logout, "Logout"),
            ],
          ),
        ));
  }

  Widget sidebarButton(IconData icon, String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              if (controller.isExpanded.value) SizedBox(width: 10),
              if (controller.isExpanded.value)
                Text(label,
                    style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ));
  }
}
