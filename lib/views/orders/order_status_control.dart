import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

import 'order_ui.dart';

/// The order's status as a pill. Offers only the moves the backend allows
/// ([OrderModel.allowedNextStatuses]); final orders show a plain badge.
class OrderStatusDropdown extends StatelessWidget {
  final OrderModel order;

  const OrderStatusDropdown({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final current = order.status;
    final options = [
      if (current != null) current,
      ...order.allowedNextStatuses.where((s) => s != current),
    ];
    final readOnly = current == null || current.isFinal || options.length < 2;

    return Container(
      decoration: BoxDecoration(
        color: orderStatusColor(current),
        borderRadius: Constants.BORDER_RADIUS_20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: readOnly ? Alignment.center : null,
      child: readOnly
          ? Text(
              current?.label ?? 'Unknown',
              key: const Key('orderStatusBadge'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<OrderStatus>(
                value: current,
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(
                  Iconsax.arrow_down_2_copy,
                  size: 20,
                  color: Colors.white,
                ),
                dropdownColor: Colors.white,
                selectedItemBuilder: (_) => options
                    .map((s) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(s.label),
                        ))
                    .toList(),
                items: options
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.label,
                            style: TextStyle(color: orderStatusColor(s), fontSize: 14),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => _changeStatus(context, value),
              ),
            ),
    );
  }

  Future<void> _changeStatus(BuildContext context, OrderStatus? newStatus) async {
    final orderId = order.orderId;
    if (newStatus == null || orderId == null || newStatus == order.status) return;

    int? bankAccountId;
    if (newStatus == OrderStatus.completed) {
      final bankAccount = await showTransferDialog(context, order.amountDue ?? 0);
      if (bankAccount == null) return; // dialog dismissed
      bankAccountId = bankAccount.id;
    } else if (newStatus == OrderStatus.cancelled) {
      if (!await showCancelDialog(context)) return;
    }
    if (!context.mounted) return;

    final orderVM = context.read<OrderVM>();
    final ok = await orderVM.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
      bankAccountId: bankAccountId, // Only set when completing
    );
    if (!context.mounted) return;

    if (ok) {
      showOrderMessage(
        context,
        newStatus == OrderStatus.cancelled
            ? 'Order #$orderId cancelled'
            : 'Order #$orderId is now ${newStatus.label}',
      );
      refreshAfterOrderChange(context);
    } else {
      showOrderError(context, orderVM.lastError);
    }
  }
}

Future<BankAccount?> showTransferDialog(
    BuildContext context, double amountDue) async {
  BankAccount? selectedAccount;

  final bool? result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      height: 1.5,
                    ),
                children: [
                  const TextSpan(
                      text: 'Once the order is completed, the amount due ',
                      style: TextStyle(fontSize: 16)),
                  TextSpan(
                    text: '${amountDue.toStringAsFixed(2)} EGP',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const TextSpan(
                      text: ' will be transferred.\n\n',
                      style: TextStyle(fontSize: 16)),
                  const TextSpan(
                      text: 'Select the account to transfer your money to:'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Consumer<AccountingVM>(
              builder: (context, accounting, child) => accounting
                          .accountsBalance ==
                      null
                  ? Container()
                  : DropdownButtonFormField<BankAccount>(
                      initialValue: selectedAccount,
                      hint: const Text('Choose account'),
                      items: accounting.accountsBalance!
                          .map((account) => DropdownMenuItem<BankAccount>(
                                value: account,
                                child: Text(account.name),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedAccount = value),
                      borderRadius: Constants.BORDER_RADIUS_20,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        labelStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                            borderRadius: Constants.BORDER_RADIUS_15),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Icon(
                            Iconsax.bank_copy,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              backgroundColor:
                  WidgetStateProperty.all<Color>(Colors.grey.shade500),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedAccount == null
                ? null
                : () => Navigator.pop(context, true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              backgroundColor:
                  WidgetStateProperty.all<Color>(Colors.green.shade400),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );

  if (result == true && selectedAccount != null) {
    return selectedAccount;
  }
  return null;
}

Future<bool> showCancelDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        // 1. Add a warning icon to the title for immediate visual feedback
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
            const SizedBox(width: 10),
            const Text('Confirm Cancellation'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            // Use the default body style from the theme
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5, // Line spacing
                ),
            children: const [
              TextSpan(
                text: 'Are you sure you want to cancel this order?\n\n',
              ),
              // 2. Make the most important consequence bold and clear
              TextSpan(
                text: 'This action cannot be undone.\n\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'The order status will be permanently set to "Cancelled", '
                    'all items will be returned to stock and any down payment '
                    'will be refunded from the account that received it.',
              ),
            ],
          ),
        ),
        actions: [
          // 3. The "safe" action (Cancel) should be a simple TextButton
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'), // "Back" is clearer than "Cancel" here
          ),
          // 4. The "destructive" action (Confirm) should be red
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              backgroundColor:
                  WidgetStateProperty.all<Color>(Colors.red.shade700),
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    ),
  );

  if (result == true) {
    return true;
  }

  return false;
}
