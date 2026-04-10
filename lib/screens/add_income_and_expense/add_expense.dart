import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../utils/colors.dart';

class AddExpense extends StatelessWidget {
  AddExpense({super.key});

  final controller = Get.find<ExpenseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInputForm(context),
            _buildListHeader(context),
            _buildRecentList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Obx(() => MyTextField(
                  controller: controller.amountController,
                  hintText: 'amount'.tr,
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: Colors.redAccent),
                  errorMsg: controller.errorMsg.value,
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Please enter an amount';
                    if (double.tryParse(val) == null)
                      return 'Please enter a valid number';
                    return null;
                  },
                )),
            const SizedBox(height: 16),
            Obx(() => MyTextField(
                  controller: controller.descriptionController,
                  hintText: 'description'.tr,
                  obscureText: false,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.description_outlined,
                      color: Colors.redAccent),
                  errorMsg: controller.errorMsg.value,
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Please enter a description';
                    return null;
                  },
                )),
            const SizedBox(height: 16),
            _buildCategorySelector(context),
            const SizedBox(height: 20),
            Obx(() => controller.isLoading.value
                ? const CupertinoActivityIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.formKey.currentState!.validate()) {
                          controller.addExpense();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'save_expense'.tr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Obx(() {
      final selectedCategoryData = controller.expenseCategories.firstWhere(
        (cat) => cat['name'] == controller.selectedCategory.value,
        orElse: () => <String, dynamic>{},
      );

      return GestureDetector(
        onTap: () => _showCategoryPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (selectedCategoryData['color'] as Color?) ??
                    Colors.grey.shade400,
                radius: 14,
                child: Icon(
                  (selectedCategoryData['icon'] as IconData?) ??
                      Icons.category_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                controller.selectedCategory.value.isEmpty
                    ? 'select_category'.tr
                    : controller.selectedCategory.value,
                style: TextStyle(
                  color: controller.selectedCategory.value.isEmpty
                      ? Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.5)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'recent_transactions'.tr,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          TextButton(
            onPressed: () => Get.toNamed(RoutesName.viewAllExpenses),
            child: Text('view_all'.tr,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    return Obx(() {
      final expenses = controller.expensesList;
      if (expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text("no_recent_expenses".tr,
                  style: TextStyle(color: Theme.of(context).disabledColor)),
            ],
          ),
        );
      }

      final last10Expenses = (expenses.toList()
            ..sort((a, b) => b['date'].compareTo(a['date'])))
          .take(10)
          .toList();

      return AnimationLimiter(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: last10Expenses.length,
          itemBuilder: (context, index) {
            final expense = last10Expenses[index];
            final categoryData = controller.expenseCategories.firstWhere(
              (element) => element['name'] == expense['category'],
              orElse: () => {'icon': Icons.category, 'color': Colors.grey},
            );

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (categoryData['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(categoryData['icon'] as IconData,
                            color: categoryData['color'] as Color, size: 20),
                      ),
                      title: Text(
                        expense['description'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM, hh:mm a').format(expense['date']),
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      trailing: Text(
                        "- ₹${NumberFormat('#,###').format(expense['amount'])}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _showCategoryPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("select_category".tr,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                itemCount: controller.expenseCategories.length,
                itemBuilder: (context, index) {
                  final category = controller.expenseCategories[index];
                  return Obx(() {
                    final isSelected =
                        controller.selectedCategory.value == category['name'];
                    return GestureDetector(
                      onTap: () {
                        controller.selectedCategory.value = category['name'];
                        Get.back();
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (category['color'] as Color)
                                  : (category['color'] as Color)
                                      .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(category['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : category['color'] as Color,
                                size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.redAccent
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
