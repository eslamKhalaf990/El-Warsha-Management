import 'dart:convert';
import 'account_balance.dart';
import 'json_read.dart';

class Category {
  final int id;
  final String categoryName;
  final String categoryType;

  Category({
    required this.id,
    required this.categoryName,
    required this.categoryType,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: readInt(json['categoryID'] ?? json['id']) ?? 0,
      categoryName: readString(json['categoryName'] ?? json['name']),
      categoryType: readString(json['categoryType'] ?? json['type']),
    );
  }

  /// For transactions booked without a category.
  static final none = Category(id: 0, categoryName: '—', categoryType: '');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'categoryType': categoryType,
    };
  }
}


class BankTransaction {
  final int id;
  final BankAccount bankAccount;
  final Category category;
  final String transactionType;
  final double amount;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;

  BankTransaction({
    required this.id,
    required this.bankAccount,
    required this.category,
    required this.transactionType,
    required this.amount,
    required this.description,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: readInt(json['id']) ?? 0,
      bankAccount: BankAccount.fromJson(readMap(json['bankAccount']) ?? const {}),
      category: readMap(json['category']) == null ? Category.none : Category.fromJson(readMap(json['category'])!),
      transactionType: readString(json['transactionType']),
      amount: readDouble(json['amount']),
      description: readString(json['description']),
      referenceType: readStringOrNull(json['referenceType']),
      referenceId: readInt(json['referenceId']),
      createdAt: readDate(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<BankTransaction> listFromJson(String jsonStr) =>
      readList(jsonDecode(jsonStr)).map(BankTransaction.fromJson).toList();
}
