import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class DetailStatsCard extends StatelessWidget {
  final double totalAmount;
  final double collected;
  final double remaining;
  final double progress;
  final bool isCompleted;
  final int paidCount;
  final int totalMembers;

  const DetailStatsCard({
    required this.totalAmount,
    required this.collected,
    required this.remaining,
    required this.progress,
    required this.isCompleted,
    required this.paidCount,
    required this.totalMembers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                context: context,
                label: 'Total Bill',
                value: '₹${totalAmount.toStringAsFixed(0)}',
                color: Colors.black87,
                icon: Icons.receipt_rounded,
                iconBgColor: Colors.grey.shade100,
                iconColor: Colors.grey.shade700,
              ),
              _buildStatColumn(
                context: context,
                label: 'Collected',
                value: '₹${collected.toStringAsFixed(0)}',
                color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                icon: Icons.check_circle_rounded,
                iconBgColor: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                iconColor: isCompleted ? Colors.green : Colors.blue,
              ),
              _buildStatColumn(
                context: context,
                label: 'Remaining',
                value: '₹${remaining.toStringAsFixed(0)}',
                color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                icon: Icons.hourglass_empty_rounded,
                iconBgColor: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                iconColor: isCompleted ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              color: isCompleted ? Colors.green : AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Collected',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$paidCount of $totalMembers paid',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
