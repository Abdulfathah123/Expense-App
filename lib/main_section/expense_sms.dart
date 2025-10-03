import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class FirebaseService {
  static const List<String> defaultCategories = [
    'Unknown',
    'Groceries',
    'Entertainment',
    'Shopping',
    'Food',
    'Others',
    'Transport',
    'Bills',
  ];

  Future<List<String>> fetchUserCategories(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!['categoryList'] != null) {
      return List<String>.from(doc.data()!['categoryList']);
    }
    return [];
  }
}

class ExpenseSms extends GetxController {
  var smsList = <SmsMessage>[].obs;
  var expenseList = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var categories = <String>[].obs;
  final SmsQuery query = SmsQuery();
  final Set<String> uniqueIds = <String>{};

  @override
  void onInit() {
    super.onInit();

    // Set initial categories to defaults
    categories.assignAll(FirebaseService.defaultCategories);

    _listenToCategories();
    fetchSms();
  }


  void _listenToCategories() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(GetStorage().read('uid'))
        .snapshots()
        .listen((docSnapshot) {
      // Start with default categories
      Set<String> uniqueCategories = {...FirebaseService.defaultCategories};

      // Add user-defined categories, ensuring no duplicates
      if (docSnapshot.exists && docSnapshot.data()!['categoryList'] != null) {
        List<String> userCategories = List<String>.from(docSnapshot.data()!['categoryList']);
        uniqueCategories.addAll(userCategories);
      }

      // Update the observable list with unique categories
      categories.assignAll(uniqueCategories.toList());
    });
  }

  Future<void> fetchSms() async {
    isLoading.value = true;
    var status = await Permission.sms.request();
    if (status.isGranted) {
      List<SmsMessage> messages = await query.getAllSms;
      smsList.assignAll(messages);
      extractExpenseDetails();
    } else {
      Get.snackbar(
        "Permission Denied",
        "Please grant SMS permission to fetch messages",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  void extractExpenseDetails() {
    List<Map<String, dynamic>> extractedExpenses = [];
    uniqueIds.clear();

    for (var message in smsList) {
      String? body = message.body;
      String messageId = message.id.toString();

      if (uniqueIds.contains(messageId)) continue;

      if (body != null && body.contains("debited via UPI") && !body.contains("requested")) {
        RegExp regExp = RegExp(r'Rs\.?\s*(\d+(\.\d{1,2})?)');
        var match = regExp.firstMatch(body);
        if (match != null) {
          uniqueIds.add(messageId);
          Map<String, dynamic> expenseData = {
            "amount": match.group(1) ?? "0",
            "message": body,
            "id": messageId,
            "date": _extractDate(body),
            "category": "Unknown",
            "description": "",
          };

          extractedExpenses.add(expenseData);
          saveExpenseToFirestore(expenseData);
        }
      }
    }
    expenseList.assignAll(extractedExpenses);
  }

  Future<void> saveExpenseToFirestore(Map<String, dynamic> expense) async {
    final _box = GetStorage();
    try {
      final String? userId = _box.read('uid');
      if (userId == null) {
        print("User not logged in");
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sms')
          .doc('expense')
          .collection('entries')
          .doc(expense["id"])
          .set(expense);

      print("Expense saved to Firestore inside sms/expense/entries");
    } catch (e) {
      print("Error saving expense to Firestore: $e");
    }
  }

  Future<void> addCategoryToFirebase(String category) async {
    final _box = GetStorage();
    final String? uid = _box.read('uid');
    if (uid != null && !categories.contains(category)) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'categoryList': FieldValue.arrayUnion([category])
      });
      categories.add(category);
    }
  }

  String _extractDate(String message) {
    RegExp dateRegExp = RegExp(r'\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}');
    var dateMatch = dateRegExp.firstMatch(message);
    if (dateMatch != null) {
      return dateMatch.group(0)!;
    }
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }
}

class ExpenseScreen extends StatelessWidget {
  final ExpenseSms smsController = Get.put(ExpenseSms());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (smsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (smsController.expenseList.isEmpty) {
          return const Center(child: Text("No Expenses Found"));
        } else {
          return ListView.builder(
            itemCount: smsController.expenseList.length,
            itemBuilder: (context, index) {
              var expense = smsController.expenseList[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 6.0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    '${expense["category"]} -',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${double.parse(expense["amount"]).toStringAsFixed(2)}'),
                      if (expense["description"] != null && expense["description"].isNotEmpty)
                        Text(
                          expense["description"],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatDate(expense["date"])),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditExpenseDialog(context, expense);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.contains(":")) {
        DateTime parsedDate = DateFormat('dd-MM-yyyy HH:mm:ss').parse(dateStr, true);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
      return dateStr;
    } catch (e) {
      return DateFormat('dd-MM-yyyy').format(DateTime.now());
    }
  }

  void _showEditExpenseDialog(BuildContext context, Map<String, dynamic> expense) {
    String? dropDownVal = expense["category"];
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => DropdownButtonFormField<String>(
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
                  ...smsController.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category[0].toUpperCase() + category.substring(1).toLowerCase()),
                    );
                  }),
                  const DropdownMenuItem(
                    value: 'add_category',
                    child: Text('Add Category +'),
                  ),
                ],
                onChanged: (value) {
                  if (value == 'add_category') {
                    _showAddCategoryDialog(context, smsController, (newCategory) {
                      dropDownVal = newCategory;
                    });
                  } else {
                    dropDownVal = value;
                  }
                },
              )),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "Enter description",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              expense["category"] = dropDownVal ?? "Unknown";
              expense["description"] = descriptionController.text.trim();
              smsController.saveExpenseToFirestore(expense).then((_) {
                int index = smsController.expenseList.indexWhere((item) => item["id"] == expense["id"]);
                if (index != -1) {
                  smsController.expenseList[index] = Map<String, dynamic>.from(expense);
                  smsController.expenseList.refresh();
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, ExpenseSms controller, Function(String) onCategoryAdded) {
    TextEditingController newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: newCategoryController,
          decoration: InputDecoration(
            labelText: "Category Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String newCategory = newCategoryController.text.trim().toLowerCase();
              if (newCategory.isNotEmpty && !controller.categories.contains(newCategory)) {
                controller.addCategoryToFirebase(newCategory).then((_) {
                  onCategoryAdded(newCategory);
                  Navigator.pop(context);
                });
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}