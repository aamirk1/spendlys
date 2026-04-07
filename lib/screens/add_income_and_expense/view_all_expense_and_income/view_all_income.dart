import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../utils/colors.dart';

class ViewAllIncome extends StatelessWidget {
  ViewAllIncome({super.key});

  final IncomeController incomeController = Get.find<IncomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("All Incomes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Obx(() {
        final incomes = (incomeController.incomeList.toList()..sort((a, b) => b['date'].compareTo(a['date'])));

        if (incomes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No transactions yet", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
              ],
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index];
              final categoryData = incomeController.incomeCategories.firstWhere(
                (c) => c['name'] == income['category'],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (categoryData['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(categoryData['icon'] as IconData, color: categoryData['color'] as Color, size: 24),
                        ),
                        title: Text(
                          income['description'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(income['date']),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${NumberFormat('#,###.##').format(income['amount'])}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionButton(Icons.edit_rounded, Colors.blue, () => _editIncome(context, income)),
                                const SizedBox(width: 8),
                                _buildActionButton(Icons.delete_rounded, Colors.red, () => _confirmDelete(context, income)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _editIncome(BuildContext context, Map<String, dynamic> income) {
    TextEditingController amountController = TextEditingController(text: income['amount'].toString());
    TextEditingController descriptionController = TextEditingController(text: income['description']);
    String selectedCategory = income['category'];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Edit Income", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: incomeController.incomeCategories.map((category) {
                  return DropdownMenuItem(value: category['name'] as String, child: Text(category['name'] as String));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    incomeController.updateIncome(income['id'], {
                      'amount': double.parse(amountController.text.trim()),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'date': income['date'],
                    });
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> income) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text("Delete Income?"),
        content: const Text("This action cannot be undone."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancel"), onPressed: () => Get.back()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              incomeController.deleteIncome(income['id']);
              Get.back();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
