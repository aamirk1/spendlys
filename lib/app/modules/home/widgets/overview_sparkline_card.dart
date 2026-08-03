import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/modules/home/widgets/pressable_scale.dart';
import 'package:spendly/app/modules/home/widgets/sparkline_painter.dart';

class OverviewSparklineCard extends StatelessWidget {
  final String title;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final double Function() amountObx;
  final List<double> Function() trendDataObx;

  const OverviewSparklineCard({
    super.key,
    required this.title,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.amountObx,
    required this.trendDataObx,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        if (title.contains("Income")) {
          Get.toNamed(RoutesName.viewAllIncome);
        } else if (title.contains("Expense")) {
          Get.toNamed(RoutesName.viewAllExpenses);
        } else if (title.contains("Invoice")) {
          Get.toNamed(RoutesName.invoiceList);
        } else {
          Get.toNamed(RoutesName.addLendBorrowView, arguments: {'index': 0});
        }
      },
      child: Container(
        width: 135,
        height: 125,
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Obx(() {
          final amount = amountObx();
          final trend = trendDataObx();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 30,
                child: CustomPaint(
                  painter: SparklinePainter(data: trend, color: color),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
