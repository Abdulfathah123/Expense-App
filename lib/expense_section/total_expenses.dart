// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:fl_chart/fl_chart.dart';
//
// import '../login_section/firebase_signin.dart';
// import '../expense_section/model/model.dart';
// import '../expense_section/model/income_model.dart';
//
// class WeeklyExpense extends StatefulWidget {
//   final int month;
//
//   const WeeklyExpense({Key? key, required this.month}) : super(key: key);
//
//   @override
//   _WeeklyExpenseState createState() => _WeeklyExpenseState();
// }
//
// class _WeeklyExpenseState extends State<WeeklyExpense> {
//   Future<Map<int, Map<String, double>>> fetchWeeklyData(int month) async {
//     final _box = GetStorage();
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user == null) return {};
//
//       DateTime now = DateTime.now();
//       DateTime startOfMonth = DateTime(now.year, month, 1);
//       DateTime endOfMonth = DateTime(now.year, month + 1, 0);
//
//       List<Expense> expenseData = await FirebaseService().getUserRecords(_box.read('uid'));
//       List<Income> incomeData = await FirebaseService().getUserIncome(_box.read('uid'));
//
//       Map<int, Map<String, double>> weeklyData = {};
//
//       // Combine Expense Data
//       for (Expense entry in expenseData) {
//         DateTime entryDate = entry.dateTime;
//         double entryAmount = entry.amount ?? 0.0; // Fixed null check
//
//         if (entryDate.isAfter(startOfMonth) && entryDate.isBefore(endOfMonth)) {
//           int weekOfMonth = ((entryDate.day - 1) ~/ 7) + 1;
//           weeklyData.putIfAbsent(weekOfMonth, () => {'income': 0.0, 'expense': 0.0});
//           weeklyData[weekOfMonth]!['expense'] =
//               (weeklyData[weekOfMonth]!['expense'] ?? 0.0) + entryAmount;
//         }
//       }
//
//       // Combine Income Data
//       for (Income entry in incomeData) {
//         DateTime entryDate = entry.dateTime;
//         double entryAmount = entry.amount ?? 0.0; // Fixed null check
//
//         if (entryDate.isAfter(startOfMonth) && entryDate.isBefore(endOfMonth)) {
//           int weekOfMonth = ((entryDate.day - 1) ~/ 7) + 1;
//           weeklyData.putIfAbsent(weekOfMonth, () => {'income': 0.0, 'expense': 0.0});
//           weeklyData[weekOfMonth]!['income'] =
//               (weeklyData[weekOfMonth]!['income'] ?? 0.0) + entryAmount;
//         }
//       }
//
//       return weeklyData;
//     } catch (e) {
//       print("Error fetching weekly data: $e");
//       return {};
//     }
//   }
//
//   Widget buildMixedBarGraph(Map<int, Map<String, double>> weeklyData) {
//     return BarChart(
//       BarChartData(
//         barGroups: weeklyData.entries.map((entry) {
//           return BarChartGroupData(
//             x: entry.key,
//             barRods: [
//               BarChartRodData(
//                 toY: entry.value['income'] ?? 0.0,
//                 color: Colors.greenAccent,
//                 width: 12,
//               ),
//               BarChartRodData(
//                 toY: entry.value['expense'] ?? 0.0,
//                 color: Colors.redAccent,
//                 width: 12,
//               ),
//             ],
//           );
//         }).toList(),
//         titlesData: FlTitlesData(
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(showTitles: true, interval: 500),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (value, meta) {
//                 return Text('W${value.toInt()}');
//               },
//             ),
//           ),
//         ),
//         borderData: FlBorderData(show: false),
//         gridData: FlGridData(show: true),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Weekly Data', style: TextStyle(color: Colors.black)),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: FutureBuilder<Map<int, Map<String, double>>>(
//         future: fetchWeeklyData(widget.month),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(
//               child: Text(
//                 "No weekly data recorded",
//                 style: TextStyle(fontSize: 18, color: Colors.blueGrey),
//               ),
//             );
//           }
//
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SizedBox(
//               height: MediaQuery.of(context).size.height * 0.4,
//               child: buildMixedBarGraph(snapshot.data!),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
