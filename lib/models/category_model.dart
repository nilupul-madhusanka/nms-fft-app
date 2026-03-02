import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String type; // 'income' or 'expense'
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon = '💰',
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '💰',
      type: map['type'] ?? 'expense',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
