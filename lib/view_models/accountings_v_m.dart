import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/transaction_add_model.dart';
import 'package:warsha_app/models/transaction_cateogry.dart';
import 'package:warsha_app/models/transaction_model.dart';
import 'package:warsha_app/services/accounting_service.dart';

/// Accounting screen (balances, transactions, deposits/withdrawals, reset)
/// and the bank-account pickers on the order screens.
class AccountingVM extends ChangeNotifier with AsyncViewModel {
  AccountingVM(this._service);

  final AccountingService _service;

  static const descriptionMaxLength = 255;

  List<BankAccount>? _accounts;
  List<BankTransaction>? _transactions;
  List<TransactionCategory>? _categories;

  /// Kept for this session only, so refreshes keep showing the safe.
  String? _ownerPassword;

  /// Null until loaded.
  List<BankAccount>? get accountsBalance => _accounts;
  List<BankTransaction>? get allTransactions => _transactions;
  List<TransactionCategory>? get allTransactionCategories => _categories;

  bool get isSafeUnlocked => _ownerPassword != null;

  /// Loads balances, transactions and categories together.
  Future<bool> fetch() => load(() async {
        final results = await Future.wait([
          _service.accounts(ownerPassword: _ownerPassword),
          _service.transactions(),
          _service.categories(),
        ]);
        _accounts = results[0] as List<BankAccount>;
        _transactions = results[1] as List<BankTransaction>;
        _categories = results[2] as List<TransactionCategory>;
      });

  /// Older name used by the order screens after a booking changes balances.
  Future<bool> initAccounting() => fetch();

  /// Shows the owner's safe when [password] is right; the first password ever
  /// entered becomes the safe's password.
  Future<bool> unlockSafe(String password) async {
    if (password.trim().isEmpty) {
      return fail(ApiException.validation({'password': 'Enter the owner password.'}));
    }
    return run(() async {
      _accounts = await _service.accounts(ownerPassword: password);
      _ownerPassword = password;
    });
  }

  void lockSafe() {
    if (_ownerPassword == null) return;
    _ownerPassword = null;
    fetch();
  }

  // ── Validation ──────────────────────────────────────────

  /// Checks a deposit/withdrawal typed on the screen. [amountText] is the raw
  /// amount box.
  Map<String, String> validateTransaction({
    required BankAccount account,
    required String transactionType,
    required String amountText,
    required String description,
  }) {
    final errors = Validators.collect({
      'amount': () => Validators.firstOf([
            () => Validators.nonNegativeNumber(amountText, 'Amount', required: true),
            () => _amount(amountText)! <= 0 ? 'Amount must be more than 0.' : null,
            () => RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(amountText.trim())
                ? null
                : 'Amount can have at most 2 decimal places.',
          ]),
      'description': () => Validators.maxLength(description, descriptionMaxLength, 'Description'),
    });
    final amount = _amount(amountText);
    if (!errors.containsKey('amount') && transactionType == 'Withdrawal' && amount! > account.currentBalance) {
      errors['amount'] = '${account.name} only has ${_money(account.currentBalance)} EGP.';
    }
    return errors;
  }

  static double? _amount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  static String _money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // ── Actions ─────────────────────────────────────────────

  Future<bool> addTransaction({
    required BankAccount account,
    required String transactionType,
    required String amountText,
    required String description,
    int? categoryId,
  }) async {
    final errors = validateTransaction(
        account: account, transactionType: transactionType, amountText: amountText, description: description);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    final ok = await run(() => _service.addTransaction(TransactionModel(
          bankAccountId: account.id,
          categoryId: categoryId,
          transactionType: transactionType,
          amount: _amount(amountText)!,
          description: description,
        )));
    if (ok) await fetch();
    return ok;
  }

  /// Deletes every transaction and zeroes balances.
  Future<bool> resetAll({String? ownerPassword}) async {
    final password = (ownerPassword == null || ownerPassword.isEmpty) ? _ownerPassword : ownerPassword;
    final ok = await run(() => _service.resetAll(ownerPassword: password));
    if (ok) await fetch();
    return ok;
  }
}
