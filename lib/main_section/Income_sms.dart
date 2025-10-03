import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomeSms extends GetxController {
  var smsList = <SmsMessage>[].obs;
  var creditList = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  final SmsQuery query = SmsQuery();
  final Set<String> uniqueIds = <String>{};

  @override
  void onInit() {
    super.onInit();
    fetchSms();
    _listenToCreditsFromFirebase();
  }

  Future<void> fetchSms() async {
    isLoading.value = true;
    var status = await Permission.sms.request();
    if (status.isGranted) {
      List<SmsMessage> messages = await query.getAllSms;
      smsList.assignAll(messages);
      extractCreditDetails();
    } else {
      Get.snackbar(
        "Permission Denied",
        "Please grant SMS permission to fetch messages",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  void extractCreditDetails() {
    List<Map<String, dynamic>> extractedCredits = [];
    uniqueIds.clear();

    for (var message in smsList) {
      String? body = message.body;
      String messageId = message.id.toString();

      if (uniqueIds.contains(messageId)) continue;

      if (body != null &&
          body.contains("credited") &&
          body.contains("A/c") &&
          !body.contains("Loan") &&
          !body.contains("Credit card") &&
          !body.contains("Install")) {
        RegExp regExp = RegExp(r'Rs\.?\s*(\d+(\.\d{1,2})?)');
        var match = regExp.firstMatch(body);
        if (match != null) {
          uniqueIds.add(messageId);
          Map<String, dynamic> creditData = {
            "id": messageId,
            "amount": double.tryParse(match.group(1) ?? "0") ?? 0,
            "reason": body, // SMS body stored as reason
            "dateTime": _extractDateTime(message),
            "paymentMethod": "Unknown",
            "description": "", // Description starts as empty
          };

          extractedCredits.add(creditData);
          saveCreditToFirestore(creditData);
        }
      }
    }
    creditList.assignAll(extractedCredits);
  }

  void _listenToCreditsFromFirebase() {
    final String? userId = GetStorage().read('uid');
    if (userId == null) {
      print("User not logged in");
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> credits = snapshot.docs.map((doc) {
        var data = doc.data();
        if (data['dateTime'] is Timestamp) {
          data['dateTime'] = DateFormat('dd-MM-yyyy').format(data['dateTime'].toDate());
        }
        return data;
      }).toList();
      creditList.assignAll(credits);
    }, onError: (error) {
      print("Error listening to credits: $error");
    });
  }

  Future<void> saveCreditToFirestore(Map<String, dynamic> credit) async {
    final _box = GetStorage();
    try {
      final String? userId = _box.read('uid');
      if (userId == null) {
        print("User not logged in");
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('income')
          .doc(credit["id"]);

      await docRef.set({
        'id': credit["id"],
        'amount': credit["amount"],
        'reason': credit["reason"],
        'dateTime': DateTime.parse(credit["dateTime"]),
        'paymentMethod': credit["paymentMethod"],
        'description': credit["description"] ?? "", // Ensure description is empty or user-edited
      }, SetOptions(merge: true));

      print("Income saved to Firestore inside income collection");
    } catch (e) {
      print("Error saving credit to Firestore: $e");
    }
  }

  String _extractDateTime(SmsMessage message) {
    if (message.date != null) {
      return message.date!.toIso8601String();
    }
    RegExp dateRegExp = RegExp(r'\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2}');
    var dateMatch = dateRegExp.firstMatch(message.body ?? '');
    if (dateMatch != null) {
      try {
        return DateFormat('dd-MM-yyyy HH:mm:ss')
            .parse(dateMatch.group(0)!)
            .toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    return DateTime.now().toIso8601String();
  }
}

class IncomeScreen extends StatelessWidget {
  final IncomeSms smsController = Get.put(IncomeSms());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (smsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (smsController.creditList.isEmpty) {
          return const Center(child: Text("No Credits Found"));
        } else {
          return ListView.builder(
            itemCount: smsController.creditList.length,
            itemBuilder: (context, index) {
              var credit = smsController.creditList[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 6.0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    '${credit["paymentMethod"]} -',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${credit["amount"].toStringAsFixed(2)}'),
                      if (credit["description"] != null && credit["description"].isNotEmpty)
                        Text(
                          credit["description"],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(credit["dateTime"]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditIncomeDialog(context, credit);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return DateFormat('dd-MM-yyyy').format(DateTime.now());
    }
  }

  void _showEditIncomeDialog(BuildContext context, Map<String, dynamic> income) {
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Income Description"),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: "Description",
            border: OutlineInputBorder(),
            hintText: "Enter description",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String newDescription = descriptionController.text.trim();
              income["description"] = newDescription.isEmpty ? "" : newDescription;
              smsController.saveCreditToFirestore(income).then((_) {
                int index = smsController.creditList.indexWhere((item) => item["id"] == income["id"]);
                if (index != -1) {
                  smsController.creditList[index] = Map<String, dynamic>.from(income);
                  smsController.creditList.refresh();
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
}