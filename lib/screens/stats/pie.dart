import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendly/controllers/incomeController.dart';

class MyPieChart extends StatefulWidget {
  const MyPieChart({super.key});

  @override
  _MyPieChartState createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  final IncomeController controller = Get.find<IncomeController>();
  var selectedFilter = 'Monthly'.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChartIncomeTotals(selectedFilter.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categoryTotals.isEmpty) {
        return const Center(child: Text("No income to display"));
      }

      // Filter categories with non-zero income totals
      var nonZeroIncomeCategories = controller.categoryTotals.entries
          .where((entry) => entry.value > 0)
          .toList();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row for Legends and Pie Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              filterButton('Weekly'),
              filterButton('Monthly'),
              filterButton('Yearly'),
            ],
          ),
          Row(
            children: [
              // Legends (Left Side) - Only categories with income
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: nonZeroIncomeCategories.map((categoryEntry) {
                      String category = categoryEntry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              controller.incomeCategories.firstWhere(
                                (element) => element['name'] == category,
                                orElse: () => {'icon': Icons.question_mark},
                              )['icon'],
                              color: controller.incomeCategories.firstWhere(
                                (element) => element['name'] == category,
                                orElse: () => {'color': Colors.grey},
                              )['color'],
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(category,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Pie Chart (Right Side) - Only categories with income
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1, // Ensures Pie Chart doesn't stretch
                  child: PieChart(mainPieData(nonZeroIncomeCategories)),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget filterButton(String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: ElevatedButton(
            onPressed: () {
              selectedFilter.value = label;
              controller
                  .fetchChartIncomeTotals(label); // Fetch data on filter change
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

  PieChartData mainPieData(
      List<MapEntry<String, double>> nonZeroIncomeCategories) {
    return PieChartData(
      sections: showingPieSections(nonZeroIncomeCategories),
      sectionsSpace: 2,
      centerSpaceRadius: 28,
      borderData: FlBorderData(show: false),
    );
  }

  List<PieChartSectionData> showingPieSections(
      List<MapEntry<String, double>> nonZeroIncomeCategories) {
    double total =
        nonZeroIncomeCategories.fold(0, (sum, entry) => sum + entry.value);

    return List.generate(nonZeroIncomeCategories.length, (i) {
      String category = nonZeroIncomeCategories[i].key;
      double value = nonZeroIncomeCategories[i].value;

      Color color = _getCategoryColor(category);
      return PieChartSectionData(
        color: color,
        value: value,
        title: "${((value / total) * 100).toStringAsFixed(1)}%",
        radius: 45,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Color _getCategoryColor(String category) {
    final categoryData = controller.incomeCategories.firstWhere(
      (element) => element['name'] == category,
      orElse: () => {'color': Colors.grey},
    );
    return categoryData['color'];
  }
}
