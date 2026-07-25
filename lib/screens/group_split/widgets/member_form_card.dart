import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class MemberFormCard extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController valueController;
  final bool isCreator;
  final String splitType;
  final double calculatedShare;
  final VoidCallback onRemove;
  final VoidCallback onValueChanged;

  const MemberFormCard({
    required this.index,
    required this.nameController,
    required this.phoneController,
    required this.valueController,
    required this.isCreator,
    required this.splitType,
    required this.calculatedShare,
    required this.onRemove,
    required this.onValueChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String labelName = isCreator ? "You (Creator)" : "Member #${index + 1}";

    // Simple avatar helper with name initials or icon
    Widget buildAvatar() {
      final name = nameController.text.trim();
      final String initials = name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.isNotEmpty
              ? name.substring(0, 1).toUpperCase()
              : "";

      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isCreator ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCreator ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Center(
          child: initials.isNotEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    color: isCreator ? AppColors.primary : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: isCreator ? AppColors.primary : Colors.grey.shade500,
                  size: 20,
                ),
        ),
      );
    }

    InputDecoration formFieldDecoration({
      required String hintText,
      required Widget prefixIcon,
    }) {
      return InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  labelName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCreator ? AppColors.primary : Colors.grey.shade800,
                  ),
                ),
              ),
              if (!isCreator)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: nameController,
                  enabled: !isCreator,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: formFieldDecoration(
                    hintText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade500, size: 16),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  enabled: !isCreator,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: formFieldDecoration(
                    hintText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500, size: 16),
                  ),
                ),
              ),
            ],
          ),
          if (splitType != 'equal') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: splitType == 'percentage' ? 'Percentage %' : 'Amount Share ₹',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FD),
                      prefixIcon: Icon(
                        splitType == 'percentage' ? Icons.percent_rounded : Icons.currency_rupee_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => onValueChanged(),
                  ),
                ),
                if (splitType == 'percentage') ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Calculated: ₹${calculatedShare.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.arrow_right_alt_rounded, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Share: ',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${calculatedShare.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
