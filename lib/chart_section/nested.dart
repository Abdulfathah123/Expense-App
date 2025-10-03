// import 'package:flutter/material.dart';
//
// class NestedTabBar extends StatefulWidget {
//   final int month;
//
//   const NestedTabBar({Key? key, required this.month}) : super(key: key);
//
//   @override
//   _NestedTabBarState createState() => _NestedTabBarState();
// }
//
// class _NestedTabBarState extends State<NestedTabBar>
//     with SingleTickerProviderStateMixin {
//   late TabController _nestedTabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _nestedTabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _nestedTabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: TabBar(
//             controller: _nestedTabController,
//             indicator: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.black,
//             tabs: [
//               Tab(text: "Expenses"),
//               Tab(text: "Income"),
//             ],
//           ),
//         ),
//         Expanded(
//           child: TabBarView(
//             controller: _nestedTabController,
//             children: [
//               _buildExpensesContent(widget.month),
//               _buildIncomeContent(widget.month),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildExpensesContent(int month) {
//     return Center(child: Text("Expenses for month: $month"));
//     // Here, you can integrate the fetchExpenses logic
//   }
//
//   Widget _buildIncomeContent(int month) {
//     return Center(child: Text("Income for month: $month"));
//     // Similarly, fetch and display income data here
//   }
// }
