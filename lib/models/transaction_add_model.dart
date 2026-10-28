class TransactionModel {
  final int bankAccountId;
  final int? categoryId;
  final String transactionType;
  final double amount;
  final String description;

  TransactionModel({
    required this.bankAccountId,
    this.categoryId,
    required this.transactionType,
    required this.amount,
    required this.description,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      bankAccountId: json['bankAccountId'] as int,
      categoryId: json['categoryId'] as int?,
      transactionType: json['transactionType'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankAccountId': bankAccountId,
      'categoryId': categoryId,
      'transactionType': transactionType,
      'amount': amount,
      'description': description.trim().isEmpty ? null : description.trim(),
    };
  }
}
