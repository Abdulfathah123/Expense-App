import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:int_tst/login_section/firebase_signin.dart';
import 'package:int_tst/expense_section/model/model.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _overallBudgetController = TextEditingController();
  final List<Map<String, dynamic>> _categories = [];
  double totalSpent = 0;
  double budget = 30000;
  double monthlyTotalSpent = 0;
  List<Expense> expenses = [];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _overallBudgetController.text = budget.toString();
    _listenToCategories();
    _loadBudgetCategories();
    _loadExpensesForCurrentMonth();
  }

  void _listenToCategories() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(GetStorage().read('uid'))
        .snapshots()
        .listen((docSnapshot) {
      setState(() {
        if (docSnapshot.exists && docSnapshot.data()!['categoryList'] != null) {
          categories = List<String>.from(docSnapshot.data()!['categoryList']);
        } else {
          categories = List.from(FirebaseService.defaultCategories);
        }

        for (var defaultCat in FirebaseService.defaultCategories) {
          if (!categories.contains(defaultCat)) {
            categories.add(defaultCat);
          }
        }
      });
    });
  }

  Future<void> _loadBudgetCategories() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(GetStorage().read('uid'))
          .get();

      setState(() {
        _categories.clear();
        totalSpent = 0;
        if (doc.exists && doc['budgetCategories'] != null) {
          for (var cat in doc['budgetCategories']) {
            double amount = double.tryParse(cat['amount'].toString()) ?? 0;
            totalSpent += amount;
            _categories.add({
              'name': cat['name'],
              'amount': cat['amount'].toString(),
              'controller': TextEditingController(text: cat['amount'].toString()),
            });
          }
        }
      });
    } catch (e) {
      print("Error loading budget categories from Firebase: $e");
    }
  }

  Future<void> _loadExpensesForCurrentMonth() async {
    try {
      expenses = await FirebaseService().getUserRecords(GetStorage().read('uid'));
      DateTime now = DateTime.now();
      int currentMonth = now.month;
      int currentYear = now.year;

      List<Expense> currentMonthExpenses = expenses.where((expense) {
        DateTime expenseDate = expense.dateTime;
        return expenseDate.month == currentMonth && expenseDate.year == currentYear;
      }).toList();

      double totalForMonth = 0;
      for (var expense in currentMonthExpenses) {
        totalForMonth += expense.amount;
      }

      setState(() {
        monthlyTotalSpent = totalForMonth;
      });
    } catch (e) {
      print("Error loading expenses for current month: $e");
    }
  }

  void _saveBudget() async {
    try {
      final budgetData = _categories.map((cat) {
        return {
          'name': cat['name'],
          'amount': cat['controller'].text.isEmpty ? '0' : cat['controller'].text,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(GetStorage().read('uid')).set({
        'budgetCategories': budgetData,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget saved successfully!")),
      );
    } catch (e) {
      print("Error saving budget: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save budget. Please try again.")),
      );
    }
  }

  void _removeCategory(int index) {
    setState(() {
      double amountToRemove = double.tryParse(_categories[index]['controller'].text) ?? 0;
      totalSpent -= amountToRemove;
      _categories[index]['controller'].dispose();
      _categories.removeAt(index);
    });
  }

  Future<void> _deleteCategoryFromFirebase(String category) async {
    try {
      // Delete all expenses associated with this category
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(GetStorage().read('uid'))
          .collection('expense')
          .where('category', isEqualTo: category)
          .get();

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove the category from the categoryList
      await FirebaseFirestore.instance.collection('users').doc(GetStorage().read('uid')).update({
        'categoryList': FieldValue.arrayRemove([category]),
      });

      // Remove the category from categoryBudgets
      await FirebaseFirestore.instance.collection('users').doc(GetStorage().read('uid')).update({
        'categoryBudgets.$category': FieldValue.delete(),
      });

      // Remove the category from budgetCategories
      setState(() {
        _categories.removeWhere((cat) => cat['name'] == category);
      });

      // Update Firestore with the new budgetCategories list
      final budgetData = _categories.map((cat) {
        return {
          'name': cat['name'],
          'amount': cat['controller'].text.isEmpty ? '0' : cat['controller'].text,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(GetStorage().read('uid')).set({
        'budgetCategories': budgetData,
      }, SetOptions(merge: true));

      print("Category deleted: $category");
    } catch (e) {
      print("Error deleting category from Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete category. Please try again.")),
      );
    }
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: categories.map((category) {
                    bool isDefaultCategory = FirebaseService.defaultCategories.contains(category);
                    return ListTile(
                      title: Text(category, style: const TextStyle(fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isDefaultCategory)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () async {
                                await _deleteCategoryFromFirebase(category);
                                Navigator.pop(context); // Close the modal after deletion
                              },
                            ),
                          const Icon(Icons.add, color: Colors.teal),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _categories.add({
                            'name': category,
                            'amount': '',
                            'controller': TextEditingController(text: ''),
                          });
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: _showAddCategoryDialog,
                child: Text(
                  "+ Add New Category",
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveCategoryToFirebase(String newCategory) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(GetStorage().read('uid')).set({
        'categoryList': FieldValue.arrayUnion([newCategory]),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving category to Firebase: $e");
    }
  }

  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Category"),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: "Enter category name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newCategory = categoryController.text.trim().toLowerCase();
                if (newCategory.isNotEmpty && !categories.contains(newCategory)) {
                  await _saveCategoryToFirebase(newCategory);
                }
                Navigator.pop(context);
              },
              child: Text("Add", style: TextStyle(color: Colors.teal.shade700)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _overallBudgetController.dispose();
    for (var category in _categories) {
      category['controller'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: const Text(
                  'Budget Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 150,
                        height: 150,
                        alignment: Alignment.center,
                        child: _buildRingChart(),
                      ),
                      const SizedBox(height: 20),
                      _buildBudgetInput(),
                      const SizedBox(height: 20),
                      const Text(
                        "Category Wise Budget",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ..._categories.asMap().entries.map((entry) {
                        int index = entry.key;
                        var category = entry.value;
                        return _buildCategoryTile(category, index);
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: _showCategorySelectionDialog,
                          child: Text(
                            "+ Add Category",
                            style: TextStyle(color: Colors.teal.shade700, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveBudget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Set Budget",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInput() {
    return Row(
      children: [
        const Text(
          "Overall Budget",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _overallBudgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '₹30,000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
              prefixIcon: const Icon(Icons.currency_rupee, color: Colors.teal),
            ),
            onChanged: (value) {
              setState(() {
                budget = double.tryParse(value) ?? 30000;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic> category, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(category['name'], style: const TextStyle(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: category['controller'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '₹ Amount',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.currency_rupee, size: 16, color: Colors.teal),
                ),
                onChanged: (value) {
                  setState(() {
                    double oldAmount = double.tryParse(category['amount']) ?? 0;
                    double newAmount = double.tryParse(value) ?? 0;
                    totalSpent = totalSpent - oldAmount + newAmount;
                    category['amount'] = value;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeCategory(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingChart() {
    double percentage = (monthlyTotalSpent / budget).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: percentage,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${monthlyTotalSpent.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
}