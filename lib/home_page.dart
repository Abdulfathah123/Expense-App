import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/category/unknown.dart';
import 'package:int_tst/chart_section/monthly.dart';
import 'package:int_tst/expense_section/finance_page.dart';
import 'package:int_tst/login_section/firebase_signin.dart';
import 'package:intl/intl.dart';
import 'category/category.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _box = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Base categories and their display names (no 'New Expenses')
  final List<String> baseCardNames = [
    'Unknown',
    'Groceries',
    'Entertainment',
    'Shopping',
    'Food',
    'Others',
    'Transport',
    'Bills',
  ];
  List<String> cardNames = [];
  List<Widget> pages = [];
  double incomeTotal = 0;
  double expenseTotal = 0;

  @override
  void initState() {
    super.initState();
    cardNames = List.from(baseCardNames);
    fetchIncomeTotal();
    fetchExpenseTotal();
    _listenToCategoriesFromFirebase(); // Listen to Firestore changes
  }

  Future<void> fetchIncomeTotal() async {
    incomeTotal = await FirebaseService().incomeAmtTotal();
    setState(() {});
  }

  Future<void> fetchExpenseTotal() async {
    expenseTotal = await FirebaseService().expenseAmtTotal();
    setState(() {});
  }

  void _listenToCategoriesFromFirebase() {
    _firestore.collection('users').doc(_box.read('uid')).snapshots().listen(
        (docSnapshot) {
      setState(() {
        // Start with base categories
        cardNames = List.from(baseCardNames);
        pages = [
          Unknown(),
          Category(category: 'grocery'),
          Category(category: 'entertainment'),
          Category(category: 'shopping'),
          Category(category: 'food'),
          Category(category: 'others'),
          Category(category: 'transport'),
          Category(category: 'bills'),
        ];

        // Add user-defined categories from Firestore
        if (docSnapshot.exists && docSnapshot.data()!['categoryList'] != null) {
          List<String> fetchedCategories =
              List<String>.from(docSnapshot.data()!['categoryList']);
          for (var category in fetchedCategories) {
            String capitalizedCategory = _capitalize(category);
            if (!baseCardNames.contains(capitalizedCategory) &&
                !cardNames.contains(capitalizedCategory)) {
              cardNames.add(capitalizedCategory);
              pages.add(Category(category: category.toLowerCase()));
            }
          }
        }
      });
    }, onError: (error) {
      print("Error listening to categories: $error");
    });
  }

  String _capitalize(String text) {
    return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
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
                const Center(
                  child: Text(
                    'FinTrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${(incomeTotal - expenseTotal).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ExpenseIncomePage(initialTab: 1)),
                              );
                            },
                            child: Column(
                              children: [
                                const Text(
                                  'Income',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  incomeTotal.toStringAsFixed(2),
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExpenseIncomePage()),
                              );
                            },
                            child: Column(
                              children: [
                                const Text(
                                  'Expense',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expenseTotal.toStringAsFixed(2),
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
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
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16),
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: cardNames.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => pages[index],
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: index.isEven
                                      ? [
                                          Colors.teal.shade400,
                                          Colors.teal.shade700
                                        ]
                                      : [
                                          Colors.blue.shade400,
                                          Colors.blue.shade700
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cardNames[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailPage extends StatelessWidget {
  final String category;

  const CategoryDetailPage({required this.category});

  Stream<List<Map<String, dynamic>>> _fetchExpenses(String category) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(GetStorage().read('uid'))
        .collection('expense')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  double _calculateTotal(List<Map<String, dynamic>> expenses) {
    return expenses.fold(
        0.0, (sum, expense) => sum + (expense['amount'] as num).toDouble());
  }

  String _capitalize(String text) {
    return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(category)),
        backgroundColor: theme.primaryColor,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchExpenses(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No expenses found'));
          }
          final expenses = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          expense['reason'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('₹${expense['amount']}'),
                        trailing: Text(
                          DateFormat('dd-MM-yyyy').format(
                            (expense['dateTime'] as Timestamp).toDate(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total: ₹${_calculateTotal(expenses).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge!.color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
