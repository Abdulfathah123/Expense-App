import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:int_tst/login_section/firebase_signin.dart'; // For FirebaseService
import 'model/income_model.dart';
import 'model/model.dart';

class ExpenseDetailPage extends StatefulWidget {
  @override
  _ExpenseDetailPageState createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  final _box = GetStorage();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Expense> _filteredExpenses = [];
  List<Income> _filteredIncomes = [];
  bool _isLoading = false;

  // Fetch expenses from Firebase
  Future<List<Expense>> getExpenses() async {
    try {
      return await FirebaseService().getUserRecords(_box.read('uid'));
    } catch (e) {
      print("Error fetching expenses from Firebase: $e");
      return [];
    }
  }

  // Fetch incomes from Firebase (assuming Income model and FirebaseService support)
  Future<List<Income>> getIncomes() async {
    try {
      return await FirebaseService().getUserIncome(_box.read('uid')); // Assuming this method exists
    } catch (e) {
      print("Error fetching incomes from Firebase: $e");
      return [];
    }
  }

  // Filter expenses based on selected dates
  void filterExpenses(List<Expense> allExpenses) {
    setState(() {
      _filteredExpenses = allExpenses.where((expense) {
        if (_fromDate != null && expense.dateTime.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null) {
          DateTime endOfToDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
          if (expense.dateTime.isAfter(endOfToDate)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  // Filter incomes based on selected dates
  void filterIncomes(List<Income> allIncomes) {
    setState(() {
      _filteredIncomes = allIncomes.where((income) {
        if (_fromDate != null && income.dateTime.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null) {
          DateTime endOfToDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
          if (income.dateTime.isAfter(endOfToDate)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  // Calculate total amount of filtered expenses
  double calculateExpenseTotal() {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculate total amount of filtered incomes
  double calculateIncomeTotal() {
    return _filteredIncomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Select date using a date picker
  Future<void> selectDate(BuildContext context, bool isFrom) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          _fromDate = pickedDate;
        } else {
          _toDate = pickedDate;
        }
        _isLoading = true; // Show loading while fetching
      });
      final allExpenses = await getExpenses();
      final allIncomes = await getIncomes();
      filterExpenses(allExpenses);
      filterIncomes(allIncomes);
      setState(() {
        _isLoading = false; // Hide loading after filtering
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Load initial expenses and incomes from Firebase
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    final allExpenses = await getExpenses();
    final allIncomes = await getIncomes();
    filterExpenses(allExpenses);
    filterIncomes(allIncomes);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 2,
        initialIndex: 0, // Start on Expenses tab
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.arrow_back,color: Colors.white),
                      onPressed: ()=> Navigator.pop(context),
                      ),
                  const Text(
                    "Expense Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      tabs: const [
                        Tab(text: "Expenses"),
                        Tab(text: "Income"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => selectDate(context, true),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 10),
                              Text(
                                _fromDate == null
                                    ? 'From Date'
                                    : DateFormat('dd-MM-yyyy').format(_fromDate!),
                                style: TextStyle(
                                  color: _fromDate == null ? Colors.grey : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => selectDate(context, false),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.green.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.green),
                              const SizedBox(width: 10),
                              Text(
                                _toDate == null
                                    ? 'To Date'
                                    : DateFormat('dd-MM-yyyy').format(_toDate!),
                                style: TextStyle(
                                  color: _toDate == null ? Colors.grey : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  // Expenses Tab
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              elevation: 6,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  '${expense.category} - ${expense.reason}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('₹${expense.amount.toStringAsFixed(2)}'),
                                trailing: Text(
                                  DateFormat('dd-MM-yyyy').format(expense.dateTime),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Total: ₹${calculateExpenseTotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Income Tab
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredIncomes.length,
                          itemBuilder: (context, index) {
                            final income = _filteredIncomes[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              elevation: 6,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  '${income.paymentMethod} - ${income.reason}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('₹${income.amount.toStringAsFixed(2)}'),
                                trailing: Text(
                                  DateFormat('dd-MM-yyyy').format(income.dateTime),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Total: ₹${calculateIncomeTotal().toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}