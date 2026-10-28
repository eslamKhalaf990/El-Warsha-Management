import 'package:flutter/material.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/transaction_cateogry.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/utils/price_helper.dart';
import 'package:warsha_app/views/accounting/transaction_table.dart';

class Accounting extends StatelessWidget {
  const Accounting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingVM>(
      builder: (context, value, child) {
        final accountBalance = value.accountsBalance;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: accountBalance == null
                ? (value.loadFailed
                    ? LoadErrorView(message: value.errorMessage!, onRetry: value.fetch)
                    : Center(
                        child: SpinKitChasingDots(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ))
                : CustomScrollView( // Changed from Column to CustomScrollView
            slivers: [
              // TOP SECTION (Title, Reset, Cards)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(
                      txt: "Accounting",
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(height: 16),
                    // RESET BUTTON
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            _showResetDialog(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.money_remove_copy,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 10),
                                  DefaultText(
                                    txt: "Reset",
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        InkWell(
                          onTap: () => showDialog(context: context, builder: (_) => const _UnlockSafeDialog()),

                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary.withAlpha(20),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.security_safe_copy,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                  const SizedBox(width: 10),
                                  DefaultText(
                                    txt: "Open Your Safe",
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // RESPONSIVE CARDS
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        double width = constraints.maxWidth;

                        if (width > 1100) {
                          crossAxisCount = 4; // Desktop
                        } else if (width > 650) {
                          crossAxisCount = 2; // Tablet
                        } else {
                          crossAxisCount = 1; // Mobile
                        }

                        double spacing = 10;
                        double cardWidth = (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            accountBalance.length == 5 ?
                            _buildCashCard(
                              context,
                              width: cardWidth,
                              title: accountBalance[4].name,
                              value: PriceHelper.formatNumber(
                                  accountBalance[4].currentBalance),
                              icon: Iconsax.security_safe_copy,
                              color: Theme.of(context).colorScheme.tertiary,
                              onDeposit: () => _showTransactionDialog(
                                  value, Colors.green, context,
                                  account: accountBalance[4], transactionType: "Deposit"),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  account: accountBalance[4], transactionType: "Withdrawal"),
                            ) : Container(),

                            _buildCashCard(
                              context,
                              width: cardWidth,
                              title: accountBalance[0].name,
                              value: PriceHelper.formatNumber(
                                  accountBalance[0].currentBalance),
                              icon: Iconsax.wallet_2_copy,
                              color: Colors.red,
                              onDeposit: () => _showTransactionDialog(
                                  value, Colors.green, context,
                                  account: accountBalance[0], transactionType: "Deposit"),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  account: accountBalance[0], transactionType: "Withdrawal"),
                            ),
                            _buildCashCard(
                              context,
                              width: cardWidth,
                              title: accountBalance[1].name,
                              value: PriceHelper.formatNumber(
                                  accountBalance[1].currentBalance),
                              icon: Iconsax.bank_copy,
                              color: Colors.blue,
                              onDeposit: () => _showTransactionDialog(
                                  value, Colors.green, context,
                                  account: accountBalance[1], transactionType: "Deposit"),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  account: accountBalance[1], transactionType: "Withdrawal"),
                            ),
                            _buildCashCard(
                              context,
                              width: cardWidth,
                              title: accountBalance[2].name,
                              value: PriceHelper.formatNumber(
                                  accountBalance[2].currentBalance),
                              icon: Iconsax.buildings_copy,
                              color: Colors.green,
                              onDeposit: () => _showTransactionDialog(
                                  value, Colors.green, context,
                                  account: accountBalance[2], transactionType: "Deposit"),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  account: accountBalance[2], transactionType: "Withdrawal"),
                            ),
                            _buildCashCard(
                              context,
                              width: cardWidth,
                              title: accountBalance[3].name,
                              value: PriceHelper.formatNumber(
                                  accountBalance[3].currentBalance),
                              icon: Iconsax.moneys_copy,
                              color: Colors.yellow.shade800,
                              onDeposit: () => _showTransactionDialog(
                                  value, Colors.green, context,
                                  account: accountBalance[3], transactionType: "Deposit"),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  account: accountBalance[3], transactionType: "Withdrawal"),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: DefaultText(
                        txt: "All Transactions",
                        bold: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // BOTTOM SECTION (Table)
              // Uses SliverFillRemaining to fill space or scroll if needed
              SliverFillRemaining(
                hasScrollBody: false, // Set to true only if TransactionsTable has its own scrolling (e.g. ListView)
                child: value.allTransactions == null
                    ? Center(
                  child: SpinKitChasingDots(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                )
                    : const TransactionsTable(), // Ensure this widget doesn't use Expanded internally
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // ... (Keep _showResetDialog, _showTransactionDialog, and _buildCashCard exactly as they were in the previous corrected version) ...
  // [Paste the helper methods from the previous response here if you haven't already]

  void _showResetDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ResetDialog());
  }

  void _showTransactionDialog(
    AccountingVM accountVM,
    Color color,
    BuildContext context, {
    required BankAccount account,
    required String transactionType,
  }) {
    showDialog(
      context: context,
      builder: (_) => _TransactionDialog(account: account, transactionType: transactionType, color: color),
    );
  }

  Widget _buildCashCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
        required double width,
        VoidCallback? onDeposit,
        VoidCallback? onWithdraw,
      }) {
    return Card(
      elevation: 0,
      color: color.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withAlpha(40)),
      ),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 15),
            DefaultText(
              txt: title,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DefaultText(
                    txt: value,
                    color: color,
                    size: 20,
                    bold: true,
                  ),
                  const SizedBox(width: 5),
                  DefaultText(
                    txt: "EGP",
                    color: color,
                    size: 20,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onDeposit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade500,
                    side: BorderSide(color: Colors.green.shade500),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(Iconsax.add_copy, size: 16, color: Colors.green.shade500),
                  label: Text("Deposit", style: TextStyle(color: Colors.green.shade500)),
                ),
                OutlinedButton.icon(
                  onPressed: onWithdraw,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade500,
                    side: BorderSide(color: Colors.red.shade500),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(Iconsax.minus_copy, size: 16, color: Colors.red.shade500),
                  label: Text("Withdraw", style: TextStyle(color: Colors.red.shade500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the owner password and shows the owner's safe when it is right.
class _UnlockSafeDialog extends StatefulWidget {
  const _UnlockSafeDialog();

  @override
  State<_UnlockSafeDialog> createState() => _UnlockSafeDialogState();
}

class _UnlockSafeDialogState extends State<_UnlockSafeDialog> {
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AccountingVM>().clearError();
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final vm = context.read<AccountingVM>();
    final ok = await vm.unlockSafe(_password.text);
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    // A wrong password comes back as a general error; show it under the field too
    final error = vm.fieldError('password') ?? (vm.error != null && !vm.loadFailed ? vm.errorMessage : null);
    return AlertDialog(
      title: const Text("Enter the owner password"),
      content: TextField(
        controller: _password,
        obscureText: true,
        autofocus: true,
        onChanged: (_) => vm.clearError(),
        onSubmitted: (_) => _open(),
        decoration: InputDecoration(
          labelText: 'Password',
          errorText: error,
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Icon(Iconsax.key_copy),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: vm.isSaving ? null : _open, child: const Text("Open")),
      ],
    );
  }
}

/// Confirms wiping every transaction; asks for the owner password, which the
/// server requires once one is set.
class _ResetDialog extends StatefulWidget {
  const _ResetDialog();

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final vm = context.read<AccountingVM>();
    final ok = await vm.resetAll(ownerPassword: _password.text);
    if (!mounted) return;
    reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: 'All transactions were reset.', pop: ok);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    return AlertDialog(
      title: const Text("Reset all transactions?"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This deletes every transaction and sets all balances to 0. It can't be undone."),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Owner password', prefixIcon: Icon(Iconsax.key_copy)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: vm.isSaving ? null : _reset,
          child: const Text("Reset"),
        ),
      ],
    );
  }
}

/// A deposit to or withdrawal from [account].
class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.account, required this.transactionType, required this.color});

  final BankAccount account;
  final String transactionType;
  final Color color;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<AccountingVM>();
      vm.clearError();
      setState(() => _categoryId = vm.allTransactionCategories?.firstOrNull?.categoryID);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<AccountingVM>();
    final ok = await vm.addTransaction(
      account: widget.account,
      transactionType: widget.transactionType,
      amountText: _amount.text,
      description: _description.text,
      categoryId: _categoryId,
    );
    if (!mounted) return;
    reportResult(
      context,
      ok: ok,
      errorMessage: vm.errorMessage,
      success: '${widget.transactionType} saved.',
      fieldError: vm.fieldError,
      fields: const ['amount', 'description'],
      pop: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingVM>();
    final categories = vm.allTransactionCategories ?? const <TransactionCategory>[];
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text("${widget.transactionType} ", style: TextStyle(fontWeight: FontWeight.bold, color: widget.color)),
            Text(": ${widget.account.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => vm.clearError(),
              decoration: InputDecoration(
                prefixIcon: Icon(Iconsax.money_copy, color: Colors.green.shade400),
                suffixText: "EGP",
                hintText: "Amount",
                errorText: vm.fieldError('amount'),
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              isExpanded: true,
              items: [
                for (final cat in categories)
                  DropdownMenuItem(value: cat.categoryID, child: Text(cat.categoryName, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
              decoration: InputDecoration(
                prefixIcon: Icon(Iconsax.transaction_minus_copy, color: Colors.green.shade400),
                hintText: "Select category",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLength: AccountingVM.descriptionMaxLength,
              onChanged: (_) => vm.clearError(),
              decoration: InputDecoration(
                prefixIcon: Icon(Iconsax.book_copy, color: Colors.green.shade400),
                hintText: "Description",
                counterText: '',
                errorText: vm.fieldError('description'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: vm.isSaving ? null : _save,
          child: vm.isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.transactionType),
        ),
      ],
    );
  }
}
