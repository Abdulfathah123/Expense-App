import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import '../expense_section/model/model.dart';
import '../login_section/firebase_signin.dart';

class Category extends StatefulWidget {
  Category({required this.category});
  final String category;
  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  double totalSpent = 0;
  bool isLoading = false;
  final _box = GetStorage();
  List<Expense> data = [];
  Future<List<Expense>> getBillsExpenses() async {
    var exp = await FirebaseService().getUserRecords(_box.read('uid'));
    return exp
        .where((e) => e.category == widget.category.toLowerCase())
        .toList();
  }

  Future<void> fetchBudget() async {
    totalSpent =
    await FirebaseService().loadBudgetCategories(category: widget.category);
    setState(() {});
  }

  Future<void> fetchdata() async {
    setState(() {
      isLoading = true;
    });
    data = await getBillsExpenses();
    setState(() {
      isLoading = false;
    });
  }

  double calculateBillsExpense() {
    return data.fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchdata();
    fetchBudget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.category} Expenses',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                    child: isLoading == true
                        ? Center(
                      child: CircularProgressIndicator(),
                    )
                        : data.isEmpty
                        ? Center(child: Text('No Expense Recorded'))
                        : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final expense = data[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            elevation: 6,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              title: Text(
                                '${expense.category}-${expense.reason}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '₹${expense.amount.toStringAsFixed(2)}'),
                              trailing: Text(DateFormat('dd-MM-yyyy')
                                  .format(expense.dateTime)),
                            ),
                          );
                        })),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total:₹${calculateBillsExpense().toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: calculateBillsExpense() > totalSpent
                            ? Colors.red
                            : Colors.black),
                  ),
                )
              ],
            )));
  }
}
