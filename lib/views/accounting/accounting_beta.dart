import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/transaction_add_model.dart';
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
                ? Center(
              child: SpinKitChasingDots(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            )
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
                          onTap: () {
                            // Create a TextEditingController to get the password from the TextField
                            final passwordController = TextEditingController();

                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text("Enter Your Password"),
                                  content: TextField(
                                    controller: passwordController,
                                    obscureText: true, // Hides the password text
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter password',
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Icon(Iconsax.key_copy),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(); // Close the dialog
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        // backgroundColor: Theme.of(context).colorScheme.tertiary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      onPressed: () {
                                        // Get the password from the controller
                                        final password = passwordController.text;

                                        // Call the provider method with the entered password
                                        if (password.isNotEmpty) {
                                          Navigator.of(context).pop(); // Close the dialog

                                          value.getAccountsBalance(password: password);
                                        }
                                      },
                                      child: const Text("Open"),
                                    ),
                                  ],
                                );
                              },
                            ).whenComplete(() {
                              // Dispose the controller when the dialog is closed to free up resources
                              passwordController.dispose();
                            });
                          },

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
                                  bankAccountId: accountBalance[4].id,
                                  categoryId: 1,
                                  transactionType: "Deposit",
                                  accountName: accountBalance[4].name),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  bankAccountId: accountBalance[4].id,
                                  categoryId: 1,
                                  transactionType: "Withdrawal",
                                  accountName: accountBalance[4].name),
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
                                  bankAccountId: accountBalance[0].id,
                                  categoryId: 1,
                                  transactionType: "Deposit",
                                  accountName: accountBalance[0].name),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  bankAccountId: accountBalance[0].id,
                                  categoryId: 1,
                                  transactionType: "Withdrawal",
                                  accountName: accountBalance[0].name),
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
                                  bankAccountId: accountBalance[1].id,
                                  categoryId: 1,
                                  transactionType: "Deposit",
                                  accountName: accountBalance[1].name),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  bankAccountId: accountBalance[1].id,
                                  categoryId: 1,
                                  transactionType: "Withdrawal",
                                  accountName: accountBalance[1].name),
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
                                  bankAccountId: accountBalance[2].id,
                                  categoryId: 1,
                                  transactionType: "Deposit",
                                  accountName: accountBalance[2].name),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  bankAccountId: accountBalance[2].id,
                                  categoryId: 1,
                                  transactionType: "Withdrawal",
                                  accountName: accountBalance[2].name),
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
                                  bankAccountId: accountBalance[3].id,
                                  categoryId: 1,
                                  transactionType: "Deposit",
                                  accountName: accountBalance[3].name),
                              onWithdraw: () => _showTransactionDialog(
                                  value, Colors.red, context,
                                  bankAccountId: accountBalance[3].id,
                                  categoryId: 1,
                                  transactionType: "Withdrawal",
                                  accountName: accountBalance[3].name),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Are you sure you want to reset all transactions?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        final accountingVM =
                        Provider.of<AccountingVM>(context, listen: false);
                        final state = await accountingVM.deleteAllTransactions();

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        if (state == "transactions_deleted") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Transactions reset successfully"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          accountingVM.initAccounting();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to reset transactions"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDialog(
      AccountingVM accountVM,
      Color color,
      BuildContext context, {
        required int bankAccountId,
        required int categoryId,
        required String transactionType,
        required String accountName,
      }) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  "$transactionType ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  ": $accountName",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  cursorColor: Theme.of(context).colorScheme.tertiary,
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Icon(Iconsax.money_copy, color: Colors.green.shade400),
                    ),
                    suffixIcon: const Padding(
                        padding: EdgeInsets.only(left: 15.0, right: 15, top: 11),
                        child: DefaultText(txt: "EGP")),
                    hintText: "Amount",
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TransactionCategory>(
                  initialValue: accountVM.allTransactionCategories?.first,
                  isExpanded: true,
                  items: accountVM.allTransactionCategories == null
                      ? []
                      : accountVM.allTransactionCategories!.map((cat) {
                    return DropdownMenuItem<TransactionCategory>(
                      value: cat,
                      child: Text(
                        cat.categoryName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  icon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Icon(Iconsax.arrow_down_1_copy),
                  ),
                  onChanged: (value) {
                    categoryId = value!.categoryID;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Icon(Iconsax.transaction_minus_copy,
                          color: Colors.green.shade400),
                    ),
                    hintText: "Select Category",
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  cursorColor: Theme.of(context).colorScheme.tertiary,
                  controller: descriptionController,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Icon(Iconsax.book_copy, color: Colors.green.shade400),
                    ),
                    hintText: "Description",
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                final transaction = TransactionModel(
                  bankAccountId: bankAccountId,
                  categoryId: categoryId,
                  transactionType: transactionType,
                  amount: double.tryParse(amountController.text) ?? 0,
                  description: descriptionController.text.trim(),
                );

                final accountingVM =
                Provider.of<AccountingVM>(context, listen: false);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                      child: SpinKitChasingDots(
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 30,
                      )),
                );

                final status = await accountingVM.addTransaction(transaction);

                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);

                if (status == "transaction_added") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction added successfully")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to add transaction")),
                  );
                }
              },
              child: Text(transactionType),
            ),
          ],
        );
      },
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