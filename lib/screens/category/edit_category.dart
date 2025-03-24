import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/categoryController.dart';
import 'package:spendly/res/routes/utils/colors.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';

class EditCategoryScreen extends StatelessWidget {
  final String categoryId;

  EditCategoryScreen({required this.categoryId});

  final CategoryController controller = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Center(
              child: Text(
            'Edit Category',
            style: TextStyle(color: Colors.white),
          ))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            SizedBox(height: 20),
            DropdownButton<IconData>(
              value: controller.selectedIcon.value,
              onChanged: (newIcon) {
                if (newIcon != null) {
                  controller.selectedIcon.value = newIcon;
                }
              },
              items: controller.availableIcons
                  .map((icon) => DropdownMenuItem<IconData>(
                        value: icon,
                        child: Icon(icon),
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),
            ColorPicker(
              pickerColor: controller.selectedColor.value,
              onColorChanged: (color) {
                controller.selectedColor.value = color;
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  controller.editCategory(categoryId);
                  Get.back(); // Navigate back after editing
                },
                child: Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
