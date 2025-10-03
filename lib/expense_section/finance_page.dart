  import 'package:flutter/material.dart';
  import 'package:get_storage/get_storage.dart';
  import 'package:int_tst/expense_section/expense_add_page.dart';
  import 'package:int_tst/expense_section/income.dart';
  import 'package:intl/intl.dart';
  import 'model/model.dart';

  class ExpenseIncomePage extends StatefulWidget {
    ExpenseIncomePage({this.initialTab});
    final int? initialTab;
    @override
    _ExpenseIncomePageState createState() => _ExpenseIncomePageState();
  }

  class _ExpenseIncomePageState extends State<ExpenseIncomePage> {
    final _box = GetStorage();
    final _reasonController = TextEditingController();
    final _amountController = TextEditingController();

    @override
    void initState() {
      super.initState();
    }

    @override
    void dispose() {
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DefaultTabController(
          length: 2,
          initialIndex: widget.initialTab??0, // Income tab as default
          child: Column(
            children: [
              Container(
                padding:const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expense Tracker",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        // Remove controller: _tabController
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        tabs: [
                          Tab(text: "Expenses"),
                          Tab(text: "Income"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  // Remove controller: _tabController
                  children: [
                    ExpenseTracker(),
                    IncomeTracker(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
