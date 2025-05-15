import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:spendly/utils/colors.dart';

class OverallPaymentStatus extends StatelessWidget {
  const OverallPaymentStatus(
      {super.key,
      required this.paidAmount,
      required this.totalAmount,
      required this.dueDate});
  final double paidAmount;
  final double totalAmount;
  final DateTime dueDate;
  @override
  Widget build(BuildContext context) {
    return buildOverallPaymentStatus(
        paidAmount: paidAmount, totalAmount: totalAmount, dueDate: dueDate);
  }

  Widget buildOverallPaymentStatus(
      {required double paidAmount,
      required double totalAmount,
      required DateTime dueDate}) {
    if (paidAmount >= totalAmount) {
      return const Text(
        "Status: Paid",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.green),
      );
    } else if (dueDate != null) {
      final now = DateTime.now();
      if (now.isAfter(dueDate)) {
        return const Text(
          "Status: Overdue",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error),
        );
      } else {
        final difference = dueDate.difference(now).inDays;
        if (difference <= 7) {
          return const Text(
            "Status: Due Soon",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.orange),
          );
        } else if (paidAmount > 0) {
          return const Text(
            "Status: Partially Paid",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.orange),
          );
        } else {
          return const Text(
            "Status: Not Paid",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error),
          );
        }
      }
    } else {
      return paidAmount > 0
          ? const Text(
              "Status: Partially Paid",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange),
            )
          : const Text(
              "Status: Not Paid",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error),
            );
    }
  }
}
