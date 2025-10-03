import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String category;
  final String reason;
  final double amount;
  final DateTime dateTime;

  Expense({
    required this.reason,
    required this.category,
    required this.amount,
    required this.dateTime,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'amount': amount,
        'category': category,
        'id': id,
        'dateTime': dateTime,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        reason: json['reason'],
        id: json['id'] ?? '',
        amount: json['amount'],
        category: json['category'] ?? '',
        dateTime: (json['dateTime'] as Timestamp).toDate(),
      );
}
