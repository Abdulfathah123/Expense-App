import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/expense_section/botton_nav.dart';
import 'package:int_tst/expense_section/model/income_model.dart';
import 'package:int_tst/main_section/expense_sms.dart';
import 'package:int_tst/main_section/income_sms.dart';
import '../expense_section/model/model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _box = GetStorage();

  static const List<String> defaultCategories = [
    'others',
    'bills',
    'entertainment',
    'transport',
    'grocery',
    'shopping',
    'food',
    'unknown',
  ];

  Future<void> saveSmsExpense(
      String uid, List<Map<String, dynamic>> expenses) async {
    try {
      print("Saving ${expenses.length} SMS expenses for user $uid...");
      for (var expense in expenses) {
        print("Saving expense: $expense");
        double amount;
        try {
          amount = double.parse(expense['amount']);
        } catch (e) {
          print("Error parsing amount for expense $expense: $e");
          amount = 0.0;
        }
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('sms')
            .doc('expense')
            .collection('entries')
            .add({
          'amount': amount,
          'message': expense['message'],
          'id': expense['id'],
          'date': expense['date'],
          'category': expense['category'],
          'createdAt': DateTime.now(),
        });
      }
      print("SMS expenses saved successfully!");
    } catch (e) {
      print("Error saving SMS expenses: $e");
    }
  }

  Future<void> saveSmsIncome(
      String uid, List<Map<String, dynamic>> incomes) async {
    try {
      print("Saving ${incomes.length} SMS incomes for user $uid...");
      for (var income in incomes) {
        print("Saving income: $income");
        double amount;
        try {
          amount = double.parse(income['amount']);
        } catch (e) {
          print("Error parsing amount for income $income: $e");
          amount = 0.0;
        }
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('sms')
            .doc('income')
            .collection('entries')
            .add({
          'amount': amount,
          'message': income['message'],
          'id': income['id'],
          'date': income['date'],
          'category': income['category'],
          'createdAt': DateTime.now(),
        });
      }
      print("SMS incomes saved successfully!");
    } catch (e) {
      print("Error saving SMS incomes: $e");
    }
  }

  Future<void> fetchAndSaveSmsData(String uid) async {
    try {
      print("Starting fetchAndSaveSmsData for user $uid...");
      final expenseController = ExpenseSms();
      final incomeController = IncomeSms();

      await expenseController.fetchSms();
      await incomeController.fetchSms();

      if (expenseController.expenseList.isNotEmpty) {
        print("Expenses to save: ${expenseController.expenseList.length}");
        await saveSmsExpense(uid, expenseController.expenseList);
      } else {
        print("No expenses to save.");
      }

      if (incomeController.creditList.isNotEmpty) {
        print("Incomes to save: ${incomeController.creditList.length}");
        await saveSmsIncome(uid, incomeController.creditList);
      } else {
        print("No incomes to save.");
      }
    } catch (e) {
      print("Error fetching and saving SMS data: $e");
    }
  }

  Future<void> signUpAndSaveUser({
    required String email,
    required String phone,
    required String address,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await saveUserData(user, name, phone, address);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('SignIn Successful')));
        await _box.write('uid', user.uid);
        print("User signed up with UID: ${user.uid}");
        if (user.uid.isNotEmpty) {
          await fetchAndSaveSmsData(user.uid);
        } else {
          print("Error: UID is empty during signup.");
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BottomNavScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error during signup: $e");
    }
  }

  Future<void> saveUserRecord(
      String uid, Map<String, dynamic> recordData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('expense')
          .add(recordData);
      print("User expense added!");
    } catch (e) {
      print("Error saving user record: $e");
    }
  }

  Future<void> saveUserIncome(
      String uid, Map<String, dynamic> recordData) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('income')
          .add(recordData);
      print("User income added!");
    } catch (e) {
      print("Error saving user income: $e");
    }
  }

  Future<double> incomeAmtTotal() async {
    String userId = _box.read('uid');
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    double total = 0;
    try {
      final income = await _firestore
          .collection('users')
          .doc(userId)
          .collection('income')
          .get();
      for (var doc in income.docs) {
        var data = doc.data();
        DateTime incomeDate = (data['dateTime'] as Timestamp).toDate();
        if (incomeDate.month == currentMonth &&
            incomeDate.year == currentYear) {
          total += (data['amount'] as num).toDouble();
        }
      }
    } catch (e) {
      print("Error calculating income total: $e");
    }
    return total;
  }

  Future<double> expenseAmtTotal() async {
    String userId = _box.read('uid');
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    double total = 0;
    try {
      final expense = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expense')
          .get();
      for (var doc in expense.docs) {
        var data = doc.data();
        DateTime expenseDate = (data['dateTime'] as Timestamp).toDate();
        if (expenseDate.month == currentMonth &&
            expenseDate.year == currentYear) {
          total += (data['amount'] as num).toDouble();
        }
      }
    } catch (e) {
      print("Error calculating expense total: $e");
    }
    return total;
  }

  Future<void> deleteUserIncome(String userId, String incomeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('income')
          .doc(incomeId)
          .delete();
      print("Income deleted successfully!");
    } catch (e) {
      print("Error deleting income: $e");
    }
  }

  Future<void> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        print("User Data: ${userDoc.data()}");
      } else {
        print("User not found");
      }
    } catch (e) {
      print("Error getting user data: $e");
    }
  }

  Future<List<Expense>> getUserRecords(String uid) async {
    List data = [];
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expense')
          .get();
      for (var doc in querySnapshot.docs) {
        data.add(doc.data());
      }
      print("User records: $data");
    } catch (e) {
      print("Error getting user records: $e");
    }
    return data.map((v) => Expense.fromJson(v)).toList();
  }

  Future<List<Income>> getUserIncome(String uid) async {
    List data = [];
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('income')
          .get();
      for (var doc in querySnapshot.docs) {
        data.add(doc.data());
      }
      print("User income: $data");
    } catch (e) {
      print("Error getting user income: $e");
    }
    return data.map((v) => Income.fromJson(v)).toList();
  }

  Future<double> loadBudgetCategories({required String category}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(GetStorage().read('uid'))
          .get();
      double totalSpent = 0;

      if (doc.exists && doc['budgetCategories'] != null) {
        for (var cat in doc['budgetCategories']) {
          if (cat['name'] == category.toLowerCase()) {
            double amount = double.tryParse(cat['amount'].toString()) ?? 0;
            totalSpent += amount;
            print("Total spent for $category: $totalSpent");
          }
        }
      }
      return totalSpent;
    } catch (e) {
      print("Error loading budget categories from Firebase: $e");
      return 0;
    }
  }

  Future<void> deleteUserRecord(String userId, String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expense')
          .doc(docId)
          .delete();
      print("Expense deleted successfully!");
    } catch (e) {
      print("Error deleting expense: $e");
    }
  }

  Future<void> saveUserData(
    User user,
    String name,
    String phone,
    String address,
  ) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'phone': phone,
        'address': address,
        'createdAt': DateTime.now(),
        'categoryList': defaultCategories,
      });
      print("User data saved successfully!");
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  Future<void> ensureCategoryList(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        List<String>? existingCategories =
            List<String>.from(userDoc.get('categoryList') ?? []);
        if (existingCategories.isEmpty) {
          await _firestore.collection('users').doc(uid).update({
            'categoryList': FieldValue.arrayUnion(defaultCategories),
          });
          print("Default categories added to user $uid");
        } else {
          List<String> updatedCategories = List.from(existingCategories);
          for (var defaultCat in defaultCategories) {
            if (!updatedCategories.contains(defaultCat)) {
              updatedCategories.add(defaultCat);
            }
          }
          if (updatedCategories.length != existingCategories.length) {
            await _firestore.collection('users').doc(uid).update({
              'categoryList': updatedCategories,
            });
            print("Updated categories for user $uid");
          }
        }
      }
    } catch (e) {
      print("Error ensuring category list: $e");
    }
  }

  Future<void> signIn(
      String email, String password, BuildContext context) async {
    try {
      final userData = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userData.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Icon(
          Icons.done,
          color: Colors.white,
        )));
        await _box.write('uid', userData.user!.uid);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BottomNavScreen()),
          (route) => false,
        );
        print("User signed in with UID: ${userData.user!.uid}");
        // await ensureCategoryList(userData.user!.uid);
        if (userData.user!.uid.isNotEmpty) {
          await fetchAndSaveSmsData(userData.user!.uid);
        } else {
          print("Error: UID is empty during signin.");
        }
      }
    } catch (e, s) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Icon(
        Icons.error,
        color: Colors.white,
      )));
      print("Error during signin: $e");
      Error.throwWithStackTrace(e, s);
    }
  }
}
