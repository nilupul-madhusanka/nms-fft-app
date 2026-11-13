import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final TransactionType type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.type,
    required this.category,
    required this.amount,
    this.note = '',
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final date = (map['date'] as Timestamp).toDate();
    final amount = (map['amount'] as num?)?.toDouble() ?? 0;
    return TransactionModel(
      id: documentId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] ?? '',
      amount: amount.isFinite ? amount : 0,
      note: map['note'] ?? '',
      date: date,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? date,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    TransactionType? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
