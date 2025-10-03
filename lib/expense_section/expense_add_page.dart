import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/Home_page.dart';
import 'package:int_tst/expense_section/expense_details.dart';
import 'package:int_tst/login_section/firebase_signin.dart';
import 'package:intl/intl.dart';
import 'model/model.dart';

class ExpenseTracker extends StatefulWidget {
  @override
  _ExpenseTrackerState createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  bool isCategoriesLoading = true;
  late List<Expense> exp;
  String dropDownVal = 'others';
  final _box = GetStorage();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _budgetController = TextEditingController();
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _listenToCategories();
    getExpense();
  }

  void _listenToCategories() {
    _firestore
        .collection('users')
        .doc(_box.read('uid'))
        .snapshots()
        .listen((docSnapshot) {
      setState(() {
        Set<String> uniqueCategories = {};

        uniqueCategories.addAll(FirebaseService.defaultCategories);

        if (docSnapshot.exists && docSnapshot.data()!['categoryList'] != null) {
          List<String> userCategories = List<String>.from(docSnapshot.data()!['categoryList']);
          uniqueCategories.addAll(userCategories);
        }

        categories = uniqueCategories.toList();

        if (!categories.contains(dropDownVal)) {
          dropDownVal = categories.isNotEmpty ? categories.first : 'others';
        }

        isCategoriesLoading = false;

        print("Categories updated: $categories");
        print("dropDownVal set to: $dropDownVal");
      });
    }, onError: (error) {
      print("Error listening to categories: $error");
      setState(() {
        isCategoriesLoading = false;
      });
    });
  }

  Future<void> getExpense() async {
    setState(() {
      isLoading = true;
    });
    exp = await FirebaseService().getUserRecords(_box.read('uid'));
    exp.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {
      isLoading = false;
    });
  }

  void saveExpense() async {
    final reason = _reasonController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;
    final docRef = _firestore
        .collection('users')
        .doc(_box.read('uid'))
        .collection('expense')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'amount': amount,
      'reason': reason,
      'dateTime': DateTime.now(),
      'category': dropDownVal,
    });
    _reasonController.clear();
    _amountController.clear();
    setState(() {});
    getExpense();
  }

  Future<void> deleteUserRecord(String documentId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_box.read('uid'))
          .collection('expense')
          .doc(documentId)
          .delete();
      print("Expense deleted!");
      getExpense();
    } catch (e) {
      print("Error deleting expense: $e");
    }
  }

  Future<void> _saveCategoryToFirebase(String newCategory, double budget) async {
    try {
      await _firestore.collection('users').doc(_box.read('uid')).set({
        'categoryList': FieldValue.arrayUnion([newCategory]),
      }, SetOptions(merge: true));

      if (budget > 0) {
        await _firestore.collection('users').doc(_box.read('uid')).set({
          'categoryBudgets': {newCategory: budget},
        }, SetOptions(merge: true));
        print("Category saved: $newCategory with budget: $budget");
      } else {
        print("Category saved: $newCategory with no budget");
      }
    } catch (e) {
      print("Error saving category to Firebase: $e");
    }
  }

  Future<void> _deleteCategoryFromFirebase(String category) async {
    try {
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(_box.read('uid'))
          .collection('expense')
          .where('category', isEqualTo: category)
          .get();

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('users').doc(_box.read('uid')).update({
        'categoryList': FieldValue.arrayRemove([category]),
      });

      await _firestore.collection('users').doc(_box.read('uid')).update({
        'categoryBudgets.$category': FieldValue.delete(),
      });

      print("Category deleted: $category");

      if (dropDownVal == category) {
        setState(() {
          dropDownVal = categories.isNotEmpty ? categories.first : 'others';
          print("dropDownVal reset to: $dropDownVal after deletion");
        });
      }
    } catch (e) {
      print("Error deleting category from Firebase: $e");
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget Limit (₹, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _categoryController.clear();
              _budgetController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newCategory = _categoryController.text.trim().toLowerCase();
              final budget = double.tryParse(_budgetController.text) ?? 0.0;
              if (newCategory.isNotEmpty && !categories.contains(newCategory)) {
                await _saveCategoryToFirebase(newCategory, budget);
                setState(() {
                  dropDownVal = newCategory;
                  print("dropDownVal set to new category: $dropDownVal");
                });
              }
              _categoryController.clear();
              _budgetController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    _reasonController.text = expense.reason;
    _amountController.text = expense.amount.toString();
    dropDownVal = expense.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isCategoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: dropDownVal,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  ...categories.map((category) {
                    bool isDefaultCategory =
                    FirebaseService.defaultCategories.contains(category);
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category.capitalize()),
                          if (!isDefaultCategory)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () async {
                                await _deleteCategoryFromFirebase(category);
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  const DropdownMenuItem(
                    value: 'add_category',
                    child: Text('Add Category +'),
                  ),
                ],
                onChanged: (value) {
                  if (value == 'add_category') {
                    _showAddCategoryDialog();
                  } else {
                    setState(() {
                      dropDownVal = value!;
                      print("dropDownVal changed to: $dropDownVal (Edit Dialog)");
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: null, // Ensure no suffix icon
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: null, // Ensure no suffix icon
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = _reasonController.text;
              final amount = double.tryParse(_amountController.text) ?? 0;
              if (amount <= 0 || reason.isEmpty) return;

              await _firestore
                  .collection('users')
                  .doc(_box.read('uid'))
                  .collection('expense')
                  .doc(expense.id)
                  .update({
                'amount': amount,
                'reason': reason,
                'category': dropDownVal,
                'dateTime': expense.dateTime,
              });

              _reasonController.clear();
              _amountController.clear();
              Navigator.of(context).pop();
              getExpense();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: isCategoriesLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: dropDownVal,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                ...categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.capitalize()),
                  );
                }),
                const DropdownMenuItem(
                  value: 'add_category',
                  child: Text('Add Category +'),
                ),
              ],
              onChanged: (value) {
                if (value == 'add_category') {
                  _showAddCategoryDialog();
                } else {
                  setState(() {
                    dropDownVal = value!;
                    print("dropDownVal changed to: $dropDownVal (Main UI)");
                  });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: null, // Remove the clear icon
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: null, // Remove the clear icon
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exp.length,
              itemBuilder: (context, index) {
                final expense = exp[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 6.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      '${expense.category} - ${expense.reason}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('₹${expense.amount.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('dd-MM-yyyy').format(expense.dateTime)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteUserRecord(expense.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditExpenseDialog(expense);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}