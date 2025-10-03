import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String  id;
  final String paymentMethod;
  final String reason;
  final double amount;
  final DateTime dateTime;

  Income({
    required this.reason,
    required this.id,
    required this.paymentMethod,
    required this.amount,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'id': id,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'dateTime': dateTime,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        reason: json['reason'],
        id: json['id']?? '',
        amount: json['amount'],
        paymentMethod: json['paymentMethod'] ?? '',
    dateTime: (json['dateTime'] as Timestamp).toDate(),
      );
}
