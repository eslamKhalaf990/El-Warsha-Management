import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/transaction_add_model.dart';
import 'package:warsha_app/models/transaction_cateogry.dart';
import 'package:warsha_app/models/transaction_model.dart';

/// Bank accounts and transactions (backend: BankTransactionController under
/// `/api/bank`). Every failure surfaces as an ApiException from [ApiClient].
class AccountingService {
  AccountingService(this._api);

  final ApiClient _api;

  /// Sent as a header so the password never appears in a URL or a server log.
  static const ownerPasswordHeader = 'X-Owner-Password';

  /// Regular accounts; the owner's safe too when [ownerPassword] is right.
  /// A wrong password fails with FORBIDDEN.
  Future<List<BankAccount>> accounts({String? ownerPassword}) async {
    final body = await _api.get('api/bank/accounts',
        headers: ownerPassword == null ? null : {ownerPasswordHeader: ownerPassword});
    return readList(body).map(BankAccount.fromJson).toList();
  }

  /// Every transaction, newest first.
  Future<List<BankTransaction>> transactions() async =>
      readList(await _api.get('api/bank/transactions')).map(BankTransaction.fromJson).toList();

  Future<List<TransactionCategory>> categories() async =>
      readList(await _api.get('api/bank/transactionCategories')).map(TransactionCategory.fromJson).toList();

  Future<void> addTransaction(TransactionModel transaction) async {
    await _api.post('api/bank/transaction', body: transaction.toJson());
  }

  /// Deletes every transaction and zeroes balances. Needs the owner password
  /// once one is set.
  Future<void> resetAll({String? ownerPassword}) async {
    await _api.delete('api/bank/resetTransactions',
        headers: ownerPassword == null ? null : {ownerPasswordHeader: ownerPassword});
  }
}
