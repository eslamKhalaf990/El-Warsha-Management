import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/accounting/accounting_dialogs.dart';
import 'package:warsha_app/models/transaction_model.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';

bool _isIn(BankTransaction t) => t.transactionType == deposit;

String _signed(BankTransaction t) => '${_isIn(t) ? '+' : '−'} ${Fmt.money(t.amount)}';

String? _reference(BankTransaction t) =>
    t.referenceId == null ? null : '${(t.referenceType ?? 'Ref').trim()} #${t.referenceId}';

/// The Transactions sheet of the Excel export; withdrawals are negative so
/// the Amount column sums to the net movement.
final transactionExportColumns = <ExcelColumn<BankTransaction>>[
  ExcelColumn('Date', (t) => t.createdAt),
  ExcelColumn('Account', (t) => t.bankAccount.name),
  ExcelColumn('Type', (t) => t.transactionType),
  ExcelColumn('Category', (t) => t.category.categoryName),
  ExcelColumn('Description', (t) => t.description),
  ExcelColumn('Reference', (t) => _reference(t)),
  ExcelColumn('Amount', (t) => _isIn(t) ? t.amount : -t.amount, money: true),
];

/// A transaction as a list row (phones and tablets).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final BankTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return EntityTile(
      leading: IconBadge(_isIn(t) ? Iconsax.money_recive_copy : Iconsax.money_send_copy, tone: _isIn(t) ? Tone.success : Tone.error),
      title: t.description.trim().isEmpty ? t.category.categoryName : t.description,
      subtitle: '${t.bankAccount.name} · ${Fmt.dateTime(t.createdAt)}',
      meta: [
        if (t.category != Category.none) StatusPill(label: t.category.categoryName),
        if (_reference(t) case final ref?) StatusPill(label: ref, icon: Iconsax.receipt_2_copy, tone: Tone.brand),
      ],
      trailing: AppText.price(_signed(t), color: _isIn(t) ? AppStatusColors.successText : AppStatusColors.errorText),
    );
  }
}

/// One page of transactions as a table (desktop).
class TransactionTable extends StatelessWidget {
  const TransactionTable({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Account')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Reference')),
        DataColumn(label: Text('Amount'), numeric: true),
      ],
      rows: [
        for (final t in vm.pagedTransactions)
          DataRow(cells: [
            DataCell(Text(Fmt.dateTime(t.createdAt))),
            DataCell(Text(t.bankAccount.name)),
            DataCell(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(t.description.trim().isEmpty ? '—' : t.description, overflow: TextOverflow.ellipsis),
            )),
            DataCell(Text(t.category.categoryName)),
            DataCell(Text(_reference(t) ?? '—')),
            DataCell(Text(
              _signed(t),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _isIn(t) ? AppStatusColors.successText : AppStatusColors.errorText,
              ),
            )),
          ]),
      ],
      footer: TablePager(page: vm.page, pageSize: AccountingVM.pageSize, total: vm.transactions.length, onPage: vm.setPage),
    );
  }
}
