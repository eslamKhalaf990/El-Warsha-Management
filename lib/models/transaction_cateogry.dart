import 'dart:convert';

import 'json_read.dart';

class TransactionCategory {
  final int categoryID;
  final String categoryName;
  final String categoryType;

  TransactionCategory({
    required this.categoryID,
    required this.categoryName,
    required this.categoryType,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      categoryID: readInt(json['categoryID'] ?? json['id']) ?? 0,
      categoryName: readString(json['categoryName']),
      categoryType: readString(json['categoryType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryID': categoryID,
      'categoryName': categoryName,
      'categoryType': categoryType,
    };
  }

  static List<TransactionCategory> listFromJson(String jsonStr) {
    return readList(json.decode(jsonStr)).map(TransactionCategory.fromJson).toList();
  }
}
