import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/Home_page.dart';
import 'package:int_tst/expense_section/expense_details.dart';
import 'package:int_tst/expense_section/model/income_model.dart';
import 'package:int_tst/login_section/firebase_signin.dart';
import 'package:intl/intl.dart';
import 'model/model.dart';

class IncomeTracker extends StatefulWidget {
  @override
  _IncomeTrackerState createState() => _IncomeTrackerState();
}

class _IncomeTrackerState extends State<IncomeTracker> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  late List<Income> incomes;
  String dropDownVal = 'gpay';
  final _box = GetStorage();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getIncome();
  }

  Future<void> getIncome() async {
    setState(() {
      isLoading = true;
    });
    incomes = await FirebaseService().getUserIncome(_box.read('uid'));
    // Sort locally by dateTime in descending order (latest first)
    incomes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {
      isLoading = false;
    });
  }

  void saveIncome() async {
    final reason = _reasonController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;
    final docRef = _firestore
        .collection('users')
        .doc(_box.read('uid'))
        .collection('income')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'amount': amount,
      'reason': reason,
      'dateTime': DateTime.now(),
      'paymentMethod': dropDownVal,
    });
    _reasonController.clear();
    _amountController.clear();
    setState(() {});
    getIncome();
  }

  Future<void> deleteUserIncome(String documentId) async {
    print("Deleting income with ID: $documentId");
    try {
      await _firestore
          .collection('users')
          .doc(_box.read('uid'))
          .collection('income')
          .doc(documentId)
          .delete();
      print("Income deleted!");
      getIncome();
    } catch (e) {
      print("Error deleting income: $e");
    }
  }

  // Edit income dialog
  void _showEditIncomeDialog(Income income) {
    _reasonController.text = income.reason;
    _amountController.text = income.amount.toString();
    dropDownVal = income.paymentMethod;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Income'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: dropDownVal,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(value: 'gpay', child: Text('GPay')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  setState(() {
                    dropDownVal = value!;
                  });
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
                  .collection('income')
                  .doc(income.id)
                  .update({
                'amount': amount,
                'reason': reason,
                'paymentMethod': dropDownVal,
                'dateTime': income.dateTime, // Preserve original date
              });

              _reasonController.clear();
              _amountController.clear();
              Navigator.of(context).pop();
              getIncome();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for Payment Method
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: DropdownButtonFormField<String>(
                value: dropDownVal,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(value: 'gpay', child: Text('GPay')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  setState(() {
                    dropDownVal = value!;
                  });
                },
              ),
            ),

            // Amount Input Field
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
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
                ),
              ),
            ),

            // Description Input Field
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Save Income Button
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Income',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),

            // Income List
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: incomes.length,
                itemBuilder: (context, index) {
                  final income = incomes[index]; // Already sorted, no need for reversed
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 6.0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        '${income.paymentMethod} - ${income.reason}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('₹${income.amount.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(DateFormat('dd-MM-yyyy').format(income.dateTime)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteUserIncome(income.id);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditIncomeDialog(income);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
      ),
    );
  }
}