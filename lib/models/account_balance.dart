import 'json_read.dart';

class BankAccount {
  final int id;
  final String name;
  final String accountType;
  final double currentBalance;
  final DateTime createdAt;

  /// The owner's private safe, shown only after the owner password.
  final bool ownerSafe;

  BankAccount({
    required this.id,
    required this.name,
    required this.accountType,
    required this.currentBalance,
    required this.createdAt,
    this.ownerSafe = false,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']),
      accountType: readString(json['accountType']),
      currentBalance: readDouble(json['currentBalance']),
      createdAt: readDate(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      ownerSafe: json['ownerSafe'] == true,
    );
  }

  // Equal by id, so pickers keep their selection after a reload.
  @override
  bool operator ==(Object other) => other is BankAccount && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
