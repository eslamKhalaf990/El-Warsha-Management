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

  // Transaction filters and paging
  static const pageSize = 50;
  String _query = '';
  int? _accountId;
  String? _type;
  DateTime? _from;
  DateTime? _to;
  int _page = 0;

  /// Null until loaded.
  List<BankAccount>? get accountsBalance => _accounts;
  List<BankTransaction>? get allTransactions => _transactions;
  List<TransactionCategory>? get allTransactionCategories => _categories;

  bool get isSafeUnlocked => _ownerPassword != null;

  /// Money across the accounts shown (the safe too once unlocked).
  double get totalBalance => (_accounts ?? const <BankAccount>[]).fold(0, (sum, a) => sum + a.currentBalance);

  String get query => _query;
  int? get accountFilter => _accountId;
  String? get typeFilter => _type;
  DateTime? get from => _from;
  DateTime? get to => _to;
  bool get hasFilters => _query.trim().isNotEmpty || _accountId != null || _type != null || _from != null;

  /// Transactions matching the filters, newest first.
  List<BankTransaction> get transactions {
    final q = _query.trim().toLowerCase();
    final end = _to == null ? null : DateTime(_to!.year, _to!.month, _to!.day + 1);
    final list = (_transactions ?? const <BankTransaction>[]).where((t) {
      if (_accountId != null && t.bankAccount.id != _accountId) return false;
      if (_type != null && t.transactionType != _type) return false;
      if (_from != null && t.createdAt.isBefore(DateTime(_from!.year, _from!.month, _from!.day))) return false;
      if (end != null && !t.createdAt.isBefore(end)) return false;
      if (q.isEmpty) return true;
      return t.description.toLowerCase().contains(q) ||
          t.category.categoryName.toLowerCase().contains(q) ||
          t.bankAccount.name.toLowerCase().contains(q) ||
          (t.referenceId != null && '#${t.referenceId}'.contains(q));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Deposits and withdrawals of [transactions].
  ({double moneyIn, double moneyOut}) get flow {
    var moneyIn = 0.0, moneyOut = 0.0;
    for (final t in transactions) {
      t.transactionType == 'Deposit' ? moneyIn += t.amount : moneyOut += t.amount;
    }
    return (moneyIn: moneyIn, moneyOut: moneyOut);
  }

  int get page => _page.clamp(0, pageCount - 1);
  int get pageCount => (transactions.length / pageSize).ceil().clamp(1, 1 << 30);

  List<BankTransaction> get pagedTransactions {
    final all = transactions;
    final start = page * pageSize;
    return all.sublist(start, (start + pageSize).clamp(0, all.length));
  }

  void setPage(int page) {
    _page = page;
    notify();
  }

  void setQuery(String query) {
    _query = query;
    _page = 0;
    notify();
  }

  void setAccountFilter(int? accountId) {
    _accountId = accountId;
    _page = 0;
    notify();
  }

  /// "Deposit", "Withdrawal" or null for both.
  void setTypeFilter(String? type) {
    _type = type;
    _page = 0;
    notify();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;
    _page = 0;
    notify();
  }

  void clearFilters() {
    _query = '';
    _accountId = _type = null;
    _from = _to = null;
    _page = 0;
    notify();
  }

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
