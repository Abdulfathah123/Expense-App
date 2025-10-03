// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:int_tst/Home_page.dart';
// import 'package:int_tst/expense_section/category.dart';
// import 'package:int_tst/expense_section/model/income_model.dart';
// import 'package:int_tst/login_section/firebase_signin.dart';
// import 'package:intl/intl.dart';
// import 'model/model.dart';
//
// class IncomeTracker extends StatefulWidget {
//   @override
//   _IncomeTrackerState createState() => _IncomeTrackerState();
// }
//
// class _IncomeTrackerState extends State<IncomeTracker> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isLoading = false;
//   late List<Income> incomes;
//   String dropDownVal = 'gpay';
//   final _box = GetStorage();
//   final _reasonController = TextEditingController();
//   final _amountController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     getIncome();
//   }
//
//   Future<void> getIncome() async {
//     setState(() {
//       isLoading = true;
//     });
//     incomes= await FirebaseService().getUserRecords(_box.read('uid'));
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   void saveIncome() async {
//     final reason = _reasonController.text;
//     final amount = double.tryParse(_amountController.text) ?? 0;
//     if (amount <= 0) return;
//     final docRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(_box.read('uid'))
//         .collection('income')
//         .doc();
//
//     // FirebaseService().saveUserRecord(_box.read('uid'),
//     await docRef.set({
//       'id': docRef.id,
//       'amount': amount,
//       'reason': reason,
//       'dateTime': DateTime.now(),
//       'paymentMethod': dropDownVal
//     });
//     _reasonController.clear();
//     _amountController.clear();
//     setState(() {});
//     getIncome();
//   }
//
//
//   Future<void> deleteUserIncome(String documentId) async {
//     print("Deleting expense with ID: $documentId");
//     try {
//       await _firestore
//           .collection('users')
//           .doc(_box.read('uid'))
//           .collection('income')
//           .doc(documentId)
//           .delete();
//
//       print("Expense deleted!");
//       getIncome();
//     } catch (e) {
//       print("Error deleting income: $e");
//     }
//   }
//
//   void fetchincome() async {
//     setState(() {
//       isLoading = true;
//     });
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//   return Scaffold(
//   body: Padding(
//   padding: const EdgeInsets.all(16.0),
//   child: Column(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//   // Dropdown for Income Category
//   Padding(
//   padding: const EdgeInsets.only(bottom: 16.0),
//   child: DropdownButtonFormField(
//   value: dropDownVal,
//   decoration: InputDecoration(
//   labelText: 'Payment Method',
//   border: OutlineInputBorder(
//   borderRadius: BorderRadius.circular(16.0),
//   ),
//   filled: true,
//   fillColor: Colors.white,
//   ),
//   items: [
//   DropdownMenuItem(value: 'gpay', child: Text('GPay')),
//   DropdownMenuItem(value: 'cash', child: Text('Cash')),
//   DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
//   ],
//   onChanged: (value) {
//   setState(() {
//   dropDownVal = value!;
//   });
//   },
//   ),
//   ),
//
//   // Amount Input Field
//   Padding(
//   padding: const EdgeInsets.only(bottom: 16.0),
//   child: TextField(
//   controller: _amountController,
//   keyboardType: TextInputType.number,
//   decoration: InputDecoration(
//   labelText: 'Amount',
//   border: OutlineInputBorder(
//   borderRadius: BorderRadius.circular(12.0),
//   ),
//   filled: true,
//   fillColor: Colors.white,
//   ),
//   ),
//   ),
//
//   // Description Input Field
//   Padding(
//   padding: const EdgeInsets.only(bottom: 16.0),
//   child: TextField(
//   controller: _reasonController,
//   decoration: InputDecoration(
//   labelText: 'Description',
//   border: OutlineInputBorder(
//   borderRadius: BorderRadius.circular(16.0),
//   ),
//   filled: true,
//   fillColor: Colors.white,
//   ),
//   ),
//   ),
//
//   // Save Income Button
//   Center(
//   child: ElevatedButton(
//   onPressed: saveIncome,
//   style: ElevatedButton.styleFrom(
//   backgroundColor: Colors.teal.shade700,
//   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//   shape: RoundedRectangleBorder(
//   borderRadius: BorderRadius.circular(12),
//   ),
//   ),
//   child: Text('Save Income',
//   style: TextStyle(fontSize: 18, color: Colors.white)),
//   ),
//   ),
//
//   // Income List
//   isLoading
//   ? const Center(child: CircularProgressIndicator())
//       : Expanded(
//   child: ListView.builder(
//   itemCount: incomes.length, // FIX: Ensure non-null list
//   itemBuilder: (context, index) {
//   final income = incomes.reversed.toList()[index];
//   return Card(
//   shape: RoundedRectangleBorder(
//   borderRadius: BorderRadius.circular(16),
//   ),
//   margin: EdgeInsets.symmetric(vertical: 8.0),
//   elevation: 6.0,
//   child: ListTile(
//   contentPadding: EdgeInsets.all(12),
//   title: Text(
//     '${income.category} - ${income.reason}',
//   style: TextStyle(fontWeight: FontWeight.bold),
//   ),
//   subtitle:
//   Text('₹${income.amount.toStringAsFixed(2)}'),
//   trailing: Row(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//   Text(
//   DateFormat('dd-MM-yyyy')
//       .format(income.dateTime),
//   ),
//   IconButton(
//   icon: Icon(Icons.delete, color: Colors.red),
//   onPressed: () {
//   // deleteIncome(income.id);
//   },
//   ),
//   ],
//   ),
//   ),
//   );
//   },
//   ),
//   ),
//   ],
//   ),
//   ),
//   );
// }
// }
