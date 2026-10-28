import 'json_read.dart';

class BankAccount {
  final int id;
  final String name;
  final String accountType;
  final double currentBalance;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    required this.name,
    required this.accountType,
    required this.currentBalance,
    required this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']),
      accountType: readString(json['accountType']),
      currentBalance: readDouble(json['currentBalance']),
      createdAt: readDate(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
