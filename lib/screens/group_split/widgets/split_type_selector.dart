import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class SplitTypeSelector extends StatelessWidget {
  final String currentSplitType;
  final ValueChanged<String> onSplitTypeChanged;

  const SplitTypeSelector({
    required this.currentSplitType,
    required this.onSplitTypeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Split type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleSmall?.color ?? AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildTypeBtn(context, 'equal', 'Equally', Icons.pie_chart_rounded),
              _buildTypeBtn(context, 'unequal', 'Custom', Icons.dashboard_customize_rounded),
              _buildTypeBtn(context, 'percentage', 'Percentage', Icons.percent_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBtn(BuildContext context, String type, String label, IconData icon) {
    final isSelected = currentSplitType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onSplitTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
