import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/categoryController.dart';
import 'package:spendly/res/routes/utils/colors.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';
import 'package:spendly/screens/category/edit_category.dart';

class ManageCategoriesScreen extends StatelessWidget {
  final CategoryController controller = Get.put(CategoryController());

  ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Manage Categories',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            MyTextField(
              controller: controller.nameController,
              hintText: 'Enter a category name',
              obscureText: false,
              keyboardType: TextInputType.text,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),

            // 🔹 Icon Picker Container
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Obx(() => Icon(
                      controller.selectedIcon.value, // Default icon
                      size: 30,
                    )),
                title: Text('Pick an Icon'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  _showIconPicker(context);
                },
              ),
            ),

            SizedBox(height: 10),

            // 🔹 Color Picker Container
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Obx(() => CircleAvatar(
                      backgroundColor: controller.selectedColor.value,
                      radius: 15,
                    )),
                title: Text('Pick a Color'),
                trailing: Icon(Icons.color_lens),
                onTap: () {
                  _showColorPicker(context);
                },
              ),
            ),
            const SizedBox(height: 20),

            Obx(() => controller.isLoading.value
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: TextButton(
                      onPressed: () {
                        controller.addCategory();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60),
                        ),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                        child: Text(
                          'Add Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )),
            // ElevatedButton(
            //   onPressed: controller.addCategory,
            //   child: Text('Add Category'),
            // ),
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    return ListTile(
                      leading: Icon(
                        IconData(
                          category['icon'] as int, // Convert back to IconData
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(int.parse(
                            // ignore: prefer_interpolation_to_compose_strings
                            "0x" + category['color'].replaceAll("#", ""))),
                      ),
                      title: Text(category['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize
                            .min, // Take up only as much space as needed
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Set values to be edited
                              controller.nameController.text =
                                  category['name'] as String;
                              controller.selectedIcon.value = IconData(
                                category['icon'] as int,
                                fontFamily: 'MaterialIcons',
                              );
                              controller.selectedColor.value = Color(int.parse(
                                  // ignore: prefer_interpolation_to_compose_strings
                                  "0x" +
                                      category['color'].replaceAll("#", "")));

                              // Navigate to the Edit screen
                              Get.to(() => EditCategoryScreen(
                                  categoryId: category['id']));
                            },
                          ),
                          SizedBox(
                              width:
                                  8), // Add a little space between the buttons
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                controller.deleteCategory(category['id']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  // 📌 Show Icon Picker Dialog
  void _showIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pick an Icon"),
          content: SizedBox(
              width: double.maxFinite,
              height: 200,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                ),
                itemCount:
                    controller.availableIcons.length, // List of available icons
                itemBuilder: (context, index) {
                  return IconButton(
                    icon: Icon(controller.availableIcons[index]),
                    onPressed: () {
                      controller.selectedIcon.value =
                          controller.availableIcons[index];
                    },
                  );
                },
              )),
        );
      },
    );
  }

  // 📌 Show Color Picker Dialog
  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pick a Color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: controller.selectedColor.value,
              onColorChanged: (color) {
                controller.selectedColor.value = color;
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Select"),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
