import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/services/accounting_service.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';

void main() {
  final requests = <http.Request>[];
  var wrongPassword = false;

  http.Response json(Object? body, [int status = 200]) => http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json; charset=utf-8'});

  AccountingVM vm() => AccountingVM(AccountingService(ApiClient(
        baseUrl: 'http://api.test/',
        client: MockClient((req) async {
          requests.add(req);
          final path = req.url.path;
          if (path.endsWith('/accounts')) {
            final pw = req.headers['X-Owner-Password'];
            if (pw != null && wrongPassword) {
              return json({'code': 'FORBIDDEN', 'message': 'Wrong owner password.'}, 403);
            }
            return json([
              {'id': 1, 'name': 'Vodafone Cash', 'accountType': 'Wallet', 'currentBalance': 500, 'createdAt': '2026-01-01T00:00:00'},
              if (pw != null) {'id': 9, 'name': 'Safe', 'accountType': 'Safe', 'currentBalance': 9000},
            ]);
          }
          if (path.endsWith('/transactions')) {
            // An old row without category or description must not break the list
            return json([
              {'id': 3, 'bankAccount': {'id': 1, 'name': 'Vodafone Cash'}, 'transactionType': 'Deposit', 'amount': 20},
            ]);
          }
          if (path.endsWith('/transactionCategories')) {
            return json([{'categoryID': 1, 'categoryName': 'Sales', 'categoryType': 'Income'}]);
          }
          if (path.endsWith('/transaction')) return json({'id': 4});
          if (path.endsWith('/resetTransactions')) return http.Response('', 204);
          return json({}, 404);
        }),
      )));

  setUp(() {
    requests.clear();
    wrongPassword = false;
  });

  test('fetch loads balances, transactions and categories; tolerant of old rows', () async {
    final model = vm();
    expect(await model.fetch(), isTrue);

    expect(model.accountsBalance!.single.name, 'Vodafone Cash');
    expect(model.allTransactions!.single.category.categoryName, '—');
    expect(model.allTransactions!.single.description, '');
    expect(model.allTransactionCategories!.single.categoryName, 'Sales');
  });

  test('the owner password travels in a header, never in the URL, and is kept for refreshes', () async {
    final model = vm();
    expect(await model.unlockSafe('open-sesame'), isTrue);

    final accountsCall = requests.lastWhere((r) => r.url.path.endsWith('/accounts'));
    expect(accountsCall.url.query, isEmpty);
    expect(accountsCall.headers['X-Owner-Password'], 'open-sesame');
    expect(model.accountsBalance, hasLength(2));

    await model.fetch();
    expect(model.accountsBalance, hasLength(2));
  });

  test('a wrong owner password is reported and the safe stays hidden', () async {
    final model = vm();
    await model.fetch();
    wrongPassword = true;

    expect(await model.unlockSafe('nope'), isFalse);
    expect(model.errorMessage, 'Wrong owner password.');
    expect(model.isSafeUnlocked, isFalse);
    expect(model.accountsBalance, hasLength(1));
  });

  test('withdrawals above the balance and bad amounts are caught locally', () async {
    final model = vm();
    await model.fetch();
    final cash = model.accountsBalance!.single;
    requests.clear();

    expect(await model.addTransaction(account: cash, transactionType: 'Withdrawal', amountText: '600', description: ''),
        isFalse);
    expect(model.fieldError('amount'), 'Vodafone Cash only has 500 EGP.');

    expect(await model.addTransaction(account: cash, transactionType: 'Deposit', amountText: '0', description: ''),
        isFalse);
    expect(model.fieldError('amount'), 'Amount must be more than 0.');

    expect(await model.addTransaction(account: cash, transactionType: 'Deposit', amountText: '1.234', description: ''),
        isFalse);
    expect(model.fieldError('amount'), 'Amount can have at most 2 decimal places.');
    expect(requests, isEmpty);
  });

  test('a valid deposit is sent with a typed amount and refreshes balances', () async {
    final model = vm();
    await model.fetch();

    expect(
        await model.addTransaction(
            account: model.accountsBalance!.single, transactionType: 'Deposit', amountText: '150,5', description: ' ', categoryId: 1),
        isTrue);

    final sent = jsonDecode(requests.firstWhere((r) => r.url.path.endsWith('/transaction')).body);
    expect(sent, {'bankAccountId': 1, 'categoryId': 1, 'transactionType': 'Deposit', 'amount': 150.5, 'description': null});
    expect(requests.last.url.path, isNot(endsWith('/transaction')));
  });

  test('reset sends the owner password header', () async {
    final model = vm();
    expect(await model.resetAll(ownerPassword: 'open-sesame'), isTrue);
    final reset = requests.firstWhere((r) => r.url.path.endsWith('/resetTransactions'));
    expect(reset.method, 'DELETE');
    expect(reset.headers['X-Owner-Password'], 'open-sesame');
  });
}
