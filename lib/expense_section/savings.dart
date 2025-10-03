import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyChart extends StatelessWidget {
  final List<WeeklyData> data;

  const WeeklyChart({super.key, required this.data});

  // Sample data for the chart
  factory WeeklyChart.withSampleData() {
    return WeeklyChart(
      data: [
        WeeklyData('Week 1', 5000, 3000),
        WeeklyData('Week 2', 5500, 3500),
        WeeklyData('Week 3', 5200, 3200),
        WeeklyData('Week 4', 5800, 3600),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY() + 1000, // Add padding to the top
          titlesData: FlTitlesData(
            show: true, // Enable titles
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Hide top titles
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final weekIndex = value.toInt();
                  if (weekIndex >= 0 && weekIndex < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[weekIndex].week,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Hide right titles
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  // Calculate the maximum Y value for dynamic scaling
  double _calculateMaxY() {
    double maxValue = 0;
    for (var item in data) {
      if (item.income > maxValue) maxValue = item.income.toDouble();
      if (item.expense > maxValue) maxValue = item.expense.toDouble();
    }
    return maxValue;
  }

  // Build bar groups for income and expense
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].income.toDouble(),
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: data[index].expense.toDouble(),
            color: Colors.orange,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}

// Data model for weekly income and expense
class WeeklyData {
  final String week;
  final int income;
  final int expense;

  WeeklyData(this.week, this.income, this.expense);
}

// Example usage in a Flutter app
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Weekly Chart')),
      body: WeeklyChart.withSampleData(),
    ),
  ));
}