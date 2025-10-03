import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/expense_section/expense_details.dart';
import 'package:int_tst/expense_section/model/income_model.dart';
import 'package:int_tst/expense_section/savings.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import '../expense_section/model/model.dart';
import '../expense_section/total_expenses.dart';
import '../login_section/firebase_signin.dart';

class Monthly extends StatefulWidget {
  const Monthly({Key? key}) : super(key: key);

  @override
  State<Monthly> createState() => _MonthlyState();
}

class _MonthlyState extends State<Monthly> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int selectedMonth = DateTime.now().month;

  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(2024, month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expenses', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white60,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseDetailPage()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DefaultTabController(
          length: 5,
          initialIndex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: getMonthName(DateTime.now().month - 4)),
                  Tab(text: getMonthName(DateTime.now().month - 3)),
                  Tab(text: getMonthName(DateTime.now().month - 2)),
                  const Tab(text: 'Previous month'),
                  const Tab(text: 'This month'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    NestedTabBar(month: DateTime.now().month - 4),
                    NestedTabBar(month: DateTime.now().month - 3),
                    NestedTabBar(month: DateTime.now().month - 2),
                    NestedTabBar(month: DateTime.now().month - 1),
                    NestedTabBar(month: DateTime.now().month),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NestedTabBar extends StatefulWidget {
  final int month;

  const NestedTabBar({Key? key, required this.month}) : super(key: key);

  @override
  _NestedTabBarState createState() => _NestedTabBarState();
}

class _NestedTabBarState extends State<NestedTabBar> with SingleTickerProviderStateMixin {
  late TabController _nestedTabController;

  @override
  void initState() {
    super.initState();
    _nestedTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nestedTabController.dispose();
    super.dispose();
  }

  // Fetch Expenses
  Future<List<Expense>> fetchExpenses(int month) async {
    final _box = GetStorage();
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in!");
        return [];
      }
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, month, 1);
      DateTime endOfMonth = DateTime(now.year, month + 1, 0, 23, 59, 59);
      var exp = await FirebaseService().getUserRecords(_box.read('uid'));

      List<Expense> filteredExpenses = exp.where((expense) {
        DateTime expenseDate = expense.dateTime;
        return expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
      return filteredExpenses;
    } catch (e) {
      print("Error fetching expenses: $e");
      return [];
    }
  }

  // Fetch Income
  Future<List<Income>> fetchIncome(int month) async {
    final _box = GetStorage();
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in!");
        return [];
      }
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, month, 1);
      DateTime endOfMonth = DateTime(now.year, month + 1, 0, 23, 59, 59);
      var incomeList = await FirebaseService().getUserIncome(_box.read('uid'));

      List<Income> filteredIncome = incomeList.where((income) {
        DateTime incomeDate = income.dateTime;
        return incomeDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            incomeDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
      return filteredIncome;
    } catch (e) {
      print("Error fetching income: $e");
      return [];
    }
  }

  // Helper method to compute weekly income and expense totals
  Future<List<WeeklyData>> _computeWeeklyData(int month) async {
    List<Expense> expenses = await fetchExpenses(month);
    List<Income> incomes = await fetchIncome(month);

    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, month, 1);
    DateTime endOfMonth = DateTime(now.year, month + 1, 0, 23, 59, 59);

    List<double> weeklyIncomeTotals = List.filled(4, 0.0);
    List<double> weeklyExpenseTotals = List.filled(4, 0.0);

    int daysInMonth = endOfMonth.day;
    int daysPerWeek = (daysInMonth / 4).ceil();

    for (var expense in expenses) {
      DateTime expenseDate = expense.dateTime;
      if (expenseDate.isBefore(startOfMonth) || expenseDate.isAfter(endOfMonth)) continue;

      int dayOfMonth = expenseDate.day;
      int weekIndex = ((dayOfMonth - 1) / daysPerWeek).floor();
      if (weekIndex >= 4) weekIndex = 3;
      weeklyExpenseTotals[weekIndex] += expense.amount;
    }

    for (var income in incomes) {
      DateTime incomeDate = income.dateTime;
      if (incomeDate.isBefore(startOfMonth) || incomeDate.isAfter(endOfMonth)) continue;

      int dayOfMonth = incomeDate.day;
      int weekIndex = ((dayOfMonth - 1) / daysPerWeek).floor();
      if (weekIndex >= 4) weekIndex = 3;
      weeklyIncomeTotals[weekIndex] += income.amount;
    }

    List<WeeklyData> weeklyData = [];
    for (int i = 0; i < 4; i++) {
      weeklyData.add(WeeklyData(
        'Week ${i + 1}',
        weeklyIncomeTotals[i].toInt(),
        weeklyExpenseTotals[i].toInt(),
      ));
    }

    return weeklyData;
  }

  // Build Expenses Content
  Widget _buildExpensesContent(int month) {
    return FutureBuilder<List<Expense>>(
      future: fetchExpenses(month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No expenses recorded",
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          );
        }

        List<Expense> expenses = snapshot.data!;
        Map<String, double> dataMap = {};

        for (var expense in expenses) {
          String category = expense.category;
          double amount = expense.amount.toDouble();
          dataMap.update(category, (value) => value + amount, ifAbsent: () => amount);
        }

        return Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Compute weekly data without navigation
                  List<WeeklyData> weeklyData = await _computeWeeklyData(month);
                  // Optionally, you can print or use the data here
                  print("Weekly Data for Expenses: $weeklyData");
                },
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    dataMap: dataMap,
                    animationDuration: const Duration(milliseconds: 800),
                    chartType: ChartType.ring,
                    ringStrokeWidth: 30,
                    chartRadius: 150,
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValuesInPercentage: true,
                      showChartValuesOutside: true,
                      decimalPlaces: 1,
                      chartValueBackgroundColor: Colors.white,
                    ),
                    legendOptions: const LegendOptions(
                      legendPosition: LegendPosition.right,
                      showLegends: true,
                      legendShape: BoxShape.circle,
                      legendTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text(expense.category),
                      subtitle: Text("Date: ${DateFormat.yMMMd().format(expense.dateTime)}"),
                      trailing: Text(
                        "₹${expense.amount}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Build Income Content
  Widget _buildIncomeContent(int month) {
    return FutureBuilder<List<Income>>(
      future: fetchIncome(month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No income recorded",
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          );
        }

        List<Income> incomes = snapshot.data!;
        Map<String, double> dataMap = {};

        for (var income in incomes) {
          String paymentMethod = income.paymentMethod;
          double amount = income.amount.toDouble();
          dataMap.update(paymentMethod, (value) => value + amount, ifAbsent: () => amount);
        }

        return Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Compute weekly data without navigation
                  List<WeeklyData> weeklyData = await _computeWeeklyData(month);
                  // Optionally, you can print or use the data here
                  print("Weekly Data for Income: $weeklyData");
                },
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    dataMap: dataMap,
                    animationDuration: const Duration(milliseconds: 800),
                    chartType: ChartType.ring,
                    ringStrokeWidth: 30,
                    chartRadius: 150,
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValuesInPercentage: true,
                      showChartValuesOutside: true,
                      decimalPlaces: 1,
                      chartValueBackgroundColor: Colors.white,
                    ),
                    legendOptions: const LegendOptions(
                      legendPosition: LegendPosition.right,
                      showLegends: true,
                      legendShape: BoxShape.circle,
                      legendTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: incomes.length,
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text("${income.paymentMethod} - ${income.reason}"),
                      subtitle: Text("Date: ${DateFormat.yMMMd().format(income.dateTime)}"),
                      trailing: Text(
                        "₹${income.amount}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            controller: _nestedTabController,
            indicator: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: "Expenses"),
              Tab(text: "Income"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _nestedTabController,
            children: [
              _buildExpensesContent(widget.month),
              _buildIncomeContent(widget.month),
            ],
          ),
        ),
      ],
    );
  }
}

// Define WeeklyData class if not already defined elsewhere
class WeeklyData {
  final String week;
  final int income;
  final int expense;

  WeeklyData(this.week, this.income, this.expense);

  @override
  String toString() {
    return 'WeeklyData{week: $week, income: $income, expense: $expense}';
  }
}