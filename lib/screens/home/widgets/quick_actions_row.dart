import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'pressable_scale.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionButton(
            icon: Icons.file_download_outlined,
            label: "All Income",
            color: Colors.green,
            bgColor: Colors.green.shade50,
            onTap: () => Get.toNamed(
              RoutesName.viewAllIncome,
            ),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: CupertinoIcons.arrow_right_arrow_left,
            label: "All Expense",
            color: Colors.redAccent,
            bgColor: Colors.red.shade50,
            onTap: () => Get.toNamed(
              RoutesName.viewAllExpenses,
            ),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: Icons.receipt_long_outlined,
            label: "Create Invoice",
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
            onTap: () => Get.toNamed(RoutesName.createInvoice),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: CupertinoIcons.person_3,
            label: "Split Bills",
            color: Colors.deepPurple,
            bgColor: Colors.deepPurple.shade50,
            onTap: () => Get.toNamed(RoutesName.groupSplitList),
          ),
        ],
      ),
    );
  }

  Widget _quickActionDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade100,
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}
