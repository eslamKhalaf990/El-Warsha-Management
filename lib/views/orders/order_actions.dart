import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/account_balance.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

/// Every status gets one tone and icon, wherever it shows.
extension OrderStatusLook on OrderStatus? {
  Tone get tone => switch (this) {
        OrderStatus.pending => Tone.warning,
        OrderStatus.processing => Tone.info,
        OrderStatus.shipped => Tone.brand,
        OrderStatus.completed => Tone.success,
        OrderStatus.cancelled => Tone.neutral,
        null => Tone.neutral,
      };

  IconData get icon => switch (this) {
        OrderStatus.pending => Iconsax.clock_copy,
        OrderStatus.processing => Iconsax.box_time_copy,
        OrderStatus.shipped => Iconsax.truck_fast_copy,
        OrderStatus.completed => Iconsax.tick_circle_copy,
        OrderStatus.cancelled => Iconsax.close_circle_copy,
        null => Iconsax.info_circle_copy,
      };

  String get text => this?.label ?? 'Unknown';
}

/// Stock and balances change with every order change.
void refreshAfterOrderChange(BuildContext context) {
  context.read<AccountingVM>().fetch();
  context.read<ProductVM>().fetch();
}

/// Shows [error] in a snackbar, unless it is a validation failure whose
/// every field the form already shows next to its input ([isShownField]).
void showOrderError(BuildContext context, ApiException? error, {bool Function(String field)? isShownField}) {
  if (error == null) return;
  if (error.isValidation && error.details.isNotEmpty && isShownField != null) {
    final unshown = error.details.where((d) => !isShownField(d.field)).toList();
    if (unshown.isNotEmpty) showError(context, unshown.first.message);
    return;
  }
  showError(context, error.message);
}

/// Moves [order] to [status], asking first: completing needs the account
/// that receives the amount due, cancelling is confirmed.
Future<void> changeOrderStatus(BuildContext context, OrderModel order, OrderStatus status) async {
  final id = order.orderId;
  if (id == null || status == order.status) return;
  int? bankAccountId;
  if (status == OrderStatus.completed) {
    final account = await chooseBankAccount(
      context,
      title: 'Complete order #$id',
      message: 'The amount due, ${Fmt.money(order.amountDue)}, is booked into the account you choose.',
      confirmLabel: 'Complete order',
    );
    if (account == null) return;
    bankAccountId = account.id;
  } else if (status == OrderStatus.cancelled) {
    final ok = await confirmAction(
      context,
      title: 'Cancel order #$id?',
      message: 'This can’t be undone. Items go back to stock and any down payment is refunded '
          'from the account that received it.',
      confirmLabel: 'Cancel order',
      icon: Iconsax.close_circle_copy,
    );
    if (!ok) return;
  }
  if (!context.mounted) return;
  final vm = context.read<OrderVM>();
  final ok = await vm.updateOrderStatus(orderId: id, status: status, bankAccountId: bankAccountId);
  if (!context.mounted) return;
  if (ok) {
    showSuccess(context, status == OrderStatus.cancelled ? 'Order #$id cancelled.' : 'Order #$id is now ${status.label}.');
    refreshAfterOrderChange(context);
  } else {
    showOrderError(context, vm.lastError);
  }
}

/// Deletes [order] after confirming. Only pending or cancelled orders can go.
Future<bool> deleteOrder(BuildContext context, OrderModel order) async {
  final ok = await confirmAction(
    context,
    title: 'Delete order #${order.orderId}?',
    message: 'The order disappears from every list and report.',
    confirmLabel: 'Delete',
  );
  if (!ok || !context.mounted) return false;
  final vm = context.read<OrderVM>();
  final deleted = await vm.deleteOrder(order.orderId!);
  if (!context.mounted) return deleted;
  reportResult(context, ok: deleted, errorMessage: vm.errorMessage, success: 'Order #${order.orderId} deleted.');
  if (deleted) refreshAfterOrderChange(context);
  return deleted;
}

/// Asks which bank account money goes to (or came from). Null when dismissed.
Future<BankAccount?> chooseBankAccount(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  final accounts = context.read<AccountingVM>().accountsBalance ?? const <BankAccount>[];
  return showFormDialog<BankAccount>(
    context,
    draft: () => FormDraft(values: {'account': accounts.length == 1 ? accounts.first : null}),
    dialog: _AccountDialog(title: title, message: message, confirmLabel: confirmLabel, accounts: accounts),
  );
}

class _AccountDialog extends StatelessWidget {
  const _AccountDialog({required this.title, required this.message, required this.confirmLabel, required this.accounts});

  final String title;
  final String message;
  final String confirmLabel;
  final List<BankAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final d = context.watch<FormDraft>();
    final selected = d.value<BankAccount>('account');
    return AppDialog(
      title: title,
      icon: Iconsax.bank_copy,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.body(message),
          const SizedBox(height: AppSpacing.s16),
          if (accounts.isEmpty)
            const InlineBanner(message: 'No bank accounts loaded. Open Accounting and try again.', tone: Tone.error)
          else
            for (final a in accounts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: AppCard(
                  onTap: () => d.set('account', a),
                  borderColor: selected == a ? AppColors.burgundy : null,
                  variant: selected == a ? AppCardVariant.blush : AppCardVariant.surface,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  child: Row(
                    children: [
                      Icon(selected == a ? Iconsax.tick_circle_copy : Iconsax.bank_copy,
                          color: selected == a ? AppColors.burgundy : AppColors.muted, size: 20),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(child: AppText.label(a.name)),
                      AppText.caption(Fmt.money(a.currentBalance)),
                    ],
                  ),
                ),
              ),
        ],
      ),
      actions: [
        AppButton.text(label: 'Back', onPressed: () => Navigator.pop(context)),
        AppButton.primary(
          label: confirmLabel,
          onPressed: selected == null ? null : () => Navigator.pop(context, selected),
        ),
      ],
    );
  }
}

/// The status as a pill; when the backend allows a next status it opens a
/// menu of exactly those moves.
class OrderStatusControl extends StatelessWidget {
  const OrderStatusControl({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final current = order.status;
    final next = order.allowedNextStatuses.where((s) => s != current).toList();
    final pill = StatusPill(label: current.text, tone: current.tone, icon: current.icon);
    if (current == null || current.isFinal || next.isEmpty) {
      return KeyedSubtree(key: const Key('orderStatusBadge'), child: pill);
    }
    return PopupMenuButton<OrderStatus>(
      tooltip: 'Change status',
      onSelected: (s) => changeOrderStatus(context, order, s),
      itemBuilder: (_) => [
        for (final s in next)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(s.icon, size: 18, color: (s as OrderStatus?).tone.foreground),
                const SizedBox(width: AppSpacing.s12),
                Text(s == OrderStatus.cancelled ? 'Cancel order' : 'Mark as ${s.label}'),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [pill, const SizedBox(width: 2), Icon(Iconsax.arrow_down_1_copy, size: 14, color: current.tone.foreground)],
      ),
    );
  }
}
