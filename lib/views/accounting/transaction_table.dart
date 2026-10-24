import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/transaction_provider.dart';
import 'package:warsha_app/utils/date.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/utils/price_helper.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';

class TransactionsTable extends StatelessWidget {
  const TransactionsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final accountingVM = context.watch<AccountingVM>();
    final provider = context.watch<TransactionsProvider>();

    final transactions = accountingVM.allTransactions ?? [];

    // Sync AccountingVM transactions to TransactionsProvider when changed
    if (provider.allTransactions.isEmpty && transactions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setTransactions(transactions);
      });
    } else if (transactions.length != provider.allTransactions.length) {
      // Detect new/removed transactions and refresh the provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setTransactions(transactions);
      });
    }

    if (provider.sortedTransactions.isEmpty && provider.allTransactions.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: DefaultText(
            txt: 'No transactions found matching your filters',
            bold: true,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: provider.sortColumnIndex,
              sortAscending: provider.sortAscending,
              dividerThickness: 1,
              horizontalMargin: 12,
              columnSpacing: 24,
              headingRowHeight: 45,
              dataRowMaxHeight: 55,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: [
                // Date
                DataColumn(
                  label: Row(
                    children: [
                      const DefaultText(txt: 'Date', bold: true),
                      IconButton(
                        icon: const Icon(Iconsax.sort_copy, size: 20),
                        onPressed: () async {
                          final DateTimeRange? newDateRange =
                              await showDateRangePicker(
                            context: context,
                            initialDateRange: (provider.startDate != null &&
                                    provider.endDate != null)
                                ? DateTimeRange(
                                    start: provider.startDate!,
                                    end: provider.endDate!)
                                : null,
                            firstDate: DateTime(2024),
                            initialEntryMode: DatePickerEntryMode.inputOnly,
                            lastDate: DateTime.now(),
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(
                                        primary: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                                  ),
                                  dialogTheme: DialogThemeData(
                                      backgroundColor: Colors.grey[850]),
                                ),
                                child: child!,
                              );
                            },
                          );
                          provider.setDateRange(newDateRange);
                        },
                      )
                    ],
                  ),
                  onSort: (i, asc) => provider.sort<String>(
                    (t) => t.createdAt.toString(),
                    i,
                    asc,
                  ),
                ),

                // Account
                DataColumn(
                  label: SizedBox(
                    height: 22,
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Account',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                      ),
                      controller: provider.accountController,
                      onChanged: (val) => provider.applyFilter('account', val),
                    ),
                  ),
                  onSort: (i, asc) =>
                      provider.sort<String>((t) => t.bankAccount.name, i, asc),
                ),

                // Category
                DataColumn(
                  label: SizedBox(
                    height: 22,
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Category',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                      ),
                      controller: provider.categoryController,
                      onChanged: (val) => provider.applyFilter('category', val),
                    ),
                  ),
                  onSort: (i, asc) => provider.sort<String>(
                      (t) => t.category.categoryName, i, asc),
                ),

                // Type
                DataColumn(
                  label: SizedBox(
                    height: 22,
                    width: 80,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Type',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                      ),
                      controller: provider.typeController,
                      onChanged: (val) => provider.applyFilter('type', val),
                    ),
                  ),
                  onSort: (i, asc) =>
                      provider.sort<String>((t) => t.transactionType, i, asc),
                ),

                // Amount
                DataColumn(
                  label: SizedBox(
                    height: 22,
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                      ),
                      controller: provider.amountController,
                      onChanged: (val) => provider.applyFilter('amount', val),
                    ),
                  ),
                  onSort: (i, asc) =>
                      provider.sort<num>((t) => t.amount, i, asc),
                ),

                // Description
                DataColumn(
                  label: SizedBox(
                    height: 22,
                    width: 150,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                      ),
                      controller: provider.descriptionController,
                      onChanged: (val) =>
                          provider.applyFilter('description', val),
                    ),
                  ),
                ),
              ],
              rows: provider.sortedTransactions.map<DataRow>((t) {
                final color = t.transactionType == "Deposit"
                    ? Colors.green
                    : Colors.redAccent;
                return DataRow(cells: [
                  DataCell(Text(
                    DateHelper.formatDate2(t.createdAt.toString()),
                    style: const TextStyle(color: Colors.black54),
                  )),
                  DataCell(Text(t.bankAccount.name)),
                  DataCell(Text(t.category.categoryName)),
                  DataCell(Row(
                    children: [
                      Icon(
                        t.transactionType == "Deposit"
                            ? Iconsax.arrow_up_2_copy
                            : Iconsax.arrow_down_1_copy,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(t.transactionType, style: TextStyle(color: color)),
                    ],
                  )),
                  DataCell(
                    Text(
                      "${PriceHelper.formatNumber(t.amount)} EGP",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(SizedBox(
                    width: 280,
                    child: Text(
                      t.description ?? "",
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
