import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'dart:math';

class MyChart extends StatefulWidget {
  const MyChart({super.key});

  @override
  _MyChartState createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  final ExpenseController controller = Get.find<ExpenseController>();
  var selectedFilter = 'Monthly'.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChartExpenseTotals(selectedFilter.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            filterButton('Weekly'),
            filterButton('Monthly'),
            filterButton('Yearly'),
          ],
        ),
        const SizedBox(height: 5),

        // 🔹 Updated Legend at the Top Right
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _getNonZeroExpenseCategories().map((category) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color? ?? Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 🔹 Bar Chart
        Expanded(
          child: Obx(() {
            if (controller.categoryTotals.isEmpty) {
              return const Center(child: Text("No expenses to display"));
            }
            return BarChart(mainBarData());
          }),
        ),
      ],
    );
  }

  Widget filterButton(String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: ElevatedButton(
            onPressed: () {
              selectedFilter.value = label;
              controller.fetchChartExpenseTotals(label);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedFilter.value == label
                  ? Colors.blue.shade700
                  : Colors.grey.shade300,
              foregroundColor:
                  selectedFilter.value == label ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: selectedFilter.value == label ? 4 : 0,
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  BarChartGroupData makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          transform: const GradientRotation(pi / 4),
        ),
        width: 10,
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: y + 0.10,
          color: Colors.grey.shade300,
        ),
      )
    ]);
  }

  List<BarChartGroupData> showingGroups() {
    List categories =
        _getNonZeroExpenseCategories().map((e) => e['name']).toList();
    List<double> values = categories
        .map((category) => controller.categoryTotals[category] ?? 0)
        .toList();

    return List.generate(categories.length, (i) {
      Color color = _getCategoryColor(categories[i]);
      return makeGroupData(i, values[i], color);
    });
  }

  List<Map<String, dynamic>> _getNonZeroExpenseCategories() {
    return controller.expenseCategories.where((category) {
      String categoryName = category['name'];
      double total = controller.categoryTotals[categoryName] ?? 0;
      return total > 0;
    }).toList();
  }

  BarChartData mainBarData() {
    return BarChartData(
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: getCategoryTitle,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: leftTitles,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: showingGroups(),
    );
  }

  Widget getCategoryTitle(double value, TitleMeta meta) {
    List categories =
        _getNonZeroExpenseCategories().map((e) => e['name']).toList();
    if (value.toInt() >= categories.length) return Container();

    String category = categories[value.toInt()];
    Color color = _getCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Icon(
        _getCategoryIconData(category),
        color: color,
        size: 20,
      ),
    );
  }

  IconData _getCategoryIconData(String category) {
    final categoryData = controller.expenseCategories.firstWhere(
      (element) => element['name'] == category,
      orElse: () => {'icon': CupertinoIcons.question_circle_fill},
    );

    return categoryData['icon'] as IconData? ??
        CupertinoIcons.question_circle_fill;
  }

  Widget leftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      space: 0,
      meta: meta,
      child: Text(
        _formatValue(value),
        style: const TextStyle(
            color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _formatValue(double value) {
    if (value == 0) {
      return '0';
    } else if (value % 2000 == 0) {
      return '${(value ~/ 1000)}K';
    } else {
      return '';
    }
  }

  Color _getCategoryColor(String category) {
    final categoryData = controller.expenseCategories.firstWhere(
      (element) => element['name'] == category,
      orElse: () => {'color': Colors.grey},
    );
    return categoryData['color'] as Color? ?? Colors.grey;
  }
}
