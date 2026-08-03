import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/modules/auth/widgets/my_text_field.dart';
import 'package:spendly/app/modules/home/widgets/pressable_scale.dart';
import 'package:spendly/app/utils/colors.dart';
import 'package:spendly/app/common_widgets/custom_button.dart';

class AddIncome extends StatelessWidget {
  AddIncome({super.key});

  final controller = Get.find<IncomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Enter Amount",
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.center,
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: controller.amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                                decoration: InputDecoration(
                                  hintText: "₹ 0.00",
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Category",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildCategorySelector(context),
                          const SizedBox(height: 16),
                          _buildPaymentModeSelector(context),
                          const SizedBox(height: 16),
                          Text(
                            "Description",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Obx(() => MyTextField(
                                controller: controller.descriptionController,
                                hintText: 'description'.tr,
                                obscureText: false,
                                keyboardType: TextInputType.text,
                                prefixIcon: const Icon(Icons.description_outlined,
                                    color: AppColors.primary),
                                errorMsg: controller.errorMsg.value,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              )),
                          const SizedBox(height: 20),
                          Obx(() => CustomButton(
                                text: 'save_income'.tr,
                                backgroundColor: AppColors.primary,
                                borderRadius: 16,
                                height: 52,
                                isLoading: controller.isLoading.value,
                                onPressed: () async {
                                  if (controller.formKey.currentState!
                                      .validate()) {
                                    await controller.addIncome();
                                  }
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                child: TextButton(
                  onPressed: () => Get.toNamed(RoutesName.viewAllIncome),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'view_all'.tr,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Obx(() {
      final selectedCategoryData = controller.incomeCategories.firstWhere(
        (cat) => cat['name'] == controller.selectedCategory.value,
        orElse: () => <String, dynamic>{},
      );

      return GestureDetector(
        onTap: () => _showCategoryPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (selectedCategoryData['color'] as Color?) ??
                    Colors.grey.shade400,
                radius: 12,
                child: Icon(
                  (selectedCategoryData['icon'] as IconData?) ??
                      Icons.category_outlined,
                  color: Colors.white,
                  size: 14,
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
                          ?.withValues(alpha: 0.5)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPaymentModeSelector(BuildContext context) {
    final modes = controller.paymentModes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Mode",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            itemBuilder: (context, index) {
              final mode = modes[index];
              return Obx(() {
                final isSelected = controller.selectedPaymentMode.value == mode;
                final modeColor = isSelected ? AppColors.primary : Colors.grey.shade100;
                final textColor = isSelected ? Colors.white : Colors.grey.shade700;

                IconData modeIcon = Icons.payment;
                if (mode == 'Cash') modeIcon = Icons.money;
                else if (mode == 'Bank Transfer') modeIcon = Icons.account_balance;
                else if (mode == 'Credit Card') modeIcon = Icons.credit_card;
                else if (mode == 'UPI') modeIcon = Icons.qr_code;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PressableScale(
                    onTap: () {
                      controller.selectedPaymentMode.value = mode;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: modeColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(modeIcon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            mode,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("select_category".tr,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: controller.incomeCategories.length,
                itemBuilder: (context, index) {
                  final category = controller.incomeCategories[index];
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (category['color'] as Color)
                                  : (category['color'] as Color)
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(category['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : category['color'] as Color,
                                size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
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
