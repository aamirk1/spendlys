import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/group_split_model.dart';
import 'package:spendly/utils/colors.dart';

class MemberContributionTile extends StatelessWidget {
  final Member member;
  final VoidCallback onTogglePaid;
  final VoidCallback onNotify;

  const MemberContributionTile({
    required this.member,
    required this.onTogglePaid,
    required this.onNotify,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isPaid = member.isPaid.value;
      final name = member.name;
      final String initials = name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.isNotEmpty
              ? name.substring(0, 1).toUpperCase()
              : "";

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaid ? Colors.grey.shade100 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Custom Checkbox
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isPaid,
                activeColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (_) => onTogglePaid(),
              ),
            ),
            const SizedBox(width: 4),

            // Initials Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPaid ? Colors.grey.shade50 : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPaid ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: isPaid ? Colors.grey.shade500 : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: isPaid ? Colors.grey.shade400 : AppColors.primary,
                        size: 16,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                      color: isPaid ? Colors.grey.shade400 : Colors.grey.shade800,
                    ),
                  ),
                  if (member.phone != null && member.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      member.phone!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Share amount and Status Tag
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${member.shareAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: isPaid ? TextDecoration.lineThrough : null,
                    color: isPaid ? Colors.grey.shade400 : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            // Reminder Bell (only for unpaid members)
            if (!isPaid) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onNotify,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
