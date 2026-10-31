import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/accounting/accounting_dialogs.dart';
import 'package:warsha_app/views/accounting/widgets/account_card.dart';
import 'package:warsha_app/views/accounting/widgets/transaction_views.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/transaction_model.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';

/// Balances per account and every money movement, filterable.
class AccountingPage extends StatelessWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    return ModulePage(
      title: 'Accounting',
      subtitle: vm.accountsBalance == null ? 'Balances and money movements' : 'Total balance ${Fmt.money(vm.totalBalance)}',
      primaryAction: PageAction(label: 'New transaction', icon: Iconsax.add_copy, onPressed: () => openTransactionForm(context)),
      actions: [
        vm.isSafeUnlocked
            ? IconButton(tooltip: 'Lock the safe', icon: const Icon(Iconsax.unlock_copy), onPressed: vm.lockSafe)
            : IconButton(tooltip: 'Open the safe', icon: const Icon(Iconsax.security_safe_copy), onPressed: () => openSafe(context)),
        ExportExcelButton<BankTransaction>(
          rows: () => context.read<AccountingVM>().transactions,
          columns: transactionExportColumns,
          fileName: 'transactions',
          sheetName: 'Transactions',
          noun: 'transaction',
        ),
        IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch),
        PopupMenuButton<int>(
          tooltip: 'More',
          icon: const Icon(Iconsax.more_copy),
          onSelected: (_) => openReset(context),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 0,
              child: Row(children: [
                Icon(Iconsax.danger_copy, size: 18, color: AppStatusColors.errorText),
                SizedBox(width: AppSpacing.s12),
                Text('Reset all transactions', style: TextStyle(color: AppStatusColors.errorText)),
              ]),
            ),
          ],
        ),
      ],
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: false,
        empty: const SizedBox.shrink(),
        builder: (context) => context.isExpanded ? const _WideLayout() : const _NarrowLayout(),
      ),
    );
  }
}

class _Accounts extends StatelessWidget {
  const _Accounts();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final accounts = [...?vm.accountsBalance]..sort((a, b) => (a.ownerSafe ? 1 : 0) - (b.ownerSafe ? 1 : 0));
    return ResponsiveGrid(
      minTileWidth: 240,
      spacing: AppSpacing.s12,
      children: [
        StatCard(
          label: 'Total balance',
          value: Fmt.money(vm.totalBalance),
          icon: Iconsax.wallet_2_copy,
          highlighted: true,
          caption: Fmt.count(accounts.length, 'account'),
        ),
        for (final a in accounts) AccountCard(account: a),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  Future<void> _pickRange(BuildContext context) async {
    final vm = context.read<AccountingVM>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: vm.from == null ? null : DateTimeRange(start: vm.from!, end: vm.to ?? DateTime.now()),
    );
    if (range != null) vm.setDateRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final accounts = vm.accountsBalance ?? const <BankAccount>[];
    final flow = vm.flow;

    final search = AppSearchField(hint: 'Search description, category or #order', initialValue: vm.query, onChanged: vm.setQuery);
    final account = AppDropdown<int?>(
      label: 'Account',
      icon: Iconsax.bank_copy,
      hintText: 'All accounts',
      items: [null, for (final a in accounts) a.id],
      value: vm.accountFilter,
      itemLabel: (id) => id == null ? 'All accounts' : accounts.firstWhere((a) => a.id == id).name,
      onChanged: vm.setAccountFilter,
    );
    final dates = vm.from == null
        ? AppButton.secondary(label: 'Dates', icon: Iconsax.calendar_1_copy, onPressed: () => _pickRange(context))
        : InputChip(
            avatar: const Icon(Iconsax.calendar_1_copy, size: 16),
            label: Text('${Fmt.shortDate(vm.from)} – ${Fmt.shortDate(vm.to)}'),
            onPressed: () => _pickRange(context),
            onDeleted: () => vm.setDateRange(null, null),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: AppText.titleSmall('Transactions')),
            StatusPill(label: 'In ${Fmt.money(flow.moneyIn)}', tone: Tone.success, icon: Iconsax.arrow_down_copy),
            const SizedBox(width: AppSpacing.s8),
            StatusPill(label: 'Out ${Fmt.money(flow.moneyOut)}', tone: Tone.error, icon: Iconsax.arrow_up_3_copy),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 860
              ? Row(children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.s12),
                  SizedBox(width: 220, child: account),
                  const SizedBox(width: AppSpacing.s12),
                  dates,
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  search,
                  const SizedBox(height: AppSpacing.s12),
                  Row(children: [Expanded(child: account), const SizedBox(width: AppSpacing.s8), dates]),
                ]),
        ),
        const SizedBox(height: AppSpacing.s12),
        ChipFilterBar<String>(
          options: const [ChipOption(deposit, 'Money in'), ChipOption(withdrawal, 'Money out')],
          selected: vm.typeFilter,
          onSelected: vm.setTypeFilter,
        ),
      ],
    );
  }
}

Widget _noTransactions(AccountingVM vm) => vm.hasFilters
    ? EmptyView(
        icon: Iconsax.search_normal_1_copy,
        title: 'No transactions match',
        message: 'Try other filters.',
        actionLabel: 'Clear filters',
        onAction: vm.clearFilters,
      )
    : const EmptyView(
        icon: Iconsax.receipt_2_copy,
        title: 'No transactions yet',
        message: 'Orders and the deposits you record show up here.',
      );

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    return RefreshIndicator(
      onRefresh: vm.fetch,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          const _Accounts(),
          const SizedBox(height: AppSpacing.s24),
          const _Filters(),
          const SizedBox(height: AppSpacing.s12),
          vm.transactions.isEmpty ? _noTransactions(vm) : const TransactionTable(),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final transactions = vm.transactions;
    return RefreshIndicator(
      onRefresh: vm.fetch,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Accounts()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
          const SliverToBoxAdapter(child: _Filters()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s12)),
          if (transactions.isEmpty)
            SliverToBoxAdapter(child: _noTransactions(vm))
          else
            SliverList.separated(
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
              itemBuilder: (_, i) => TransactionTile(transaction: transactions[i]),
            ),
          SliverToBoxAdapter(child: SizedBox(height: listPadding(context).bottom)),
        ],
      ),
    );
  }
}
