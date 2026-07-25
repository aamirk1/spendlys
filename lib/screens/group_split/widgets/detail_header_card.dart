import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/colors.dart';

class DetailHeaderCard extends StatelessWidget {
  final String title;
  final String formattedDate;
  final String splitType;

  const DetailHeaderCard({
    required this.title,
    required this.formattedDate,
    required this.splitType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Setup chip visual depending on split type
    Color chipColor;
    Color textColor;
    String typeLabel;
    IconData typeIcon;

    if (splitType == 'equal') {
      chipColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      typeLabel = 'Equally';
      typeIcon = Icons.pie_chart_rounded;
    } else if (splitType == 'percentage') {
      chipColor = Colors.purple.shade50;
      textColor = Colors.purple.shade700;
      typeLabel = 'Percentage';
      typeIcon = Icons.percent_rounded;
    } else {
      chipColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      typeLabel = 'Custom';
      typeIcon = Icons.dashboard_customize_rounded;
    }

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.textTheme.titleMedium?.color ?? AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 12, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
