import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/orders/invoice_page.dart';
import 'package:warsha_app/views/orders/order_actions.dart';
import 'package:warsha_app/views/orders/order_form_page.dart';
import 'package:warsha_app/views/orders/widgets/order_totals_view.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_options.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/models/order_totals.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

/// Opens [order]'s details: a side panel on desktop, a bottom sheet on phones.
void showOrderDetails(BuildContext context, OrderModel order) {
  if (context.isExpanded) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Material(
          color: AppColors.ivory,
          child: SizedBox(
            width: 520,
            height: double.infinity,
            child: _OrderDetails(orderId: order.orderId!, onEdit: (o) => openOrderForm(context, order: o)),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivory,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _OrderDetails(orderId: order.orderId!, onEdit: (o) => openOrderForm(context, order: o)),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.orderId, required this.onEdit});

  final int orderId;

  /// Opens the edit form from the page below, after this panel closes.
  final ValueChanged<OrderModel> onEdit;

  @override
  Widget build(BuildContext context) {
    // Follow the list, so a status change made here shows right away.
    final order = context.select<OrderVM, OrderModel?>(
      (vm) => vm.allOrders.where((o) => o.orderId == orderId).firstOrNull,
    );
    if (order == null) return const EmptyView(title: 'This order is gone', icon: Iconsax.receipt_2_copy);
    final c = order.customer;
    final status = order.status;
    final canEdit = status?.isEditable ?? false;
    final canDelete = status == OrderStatus.pending || status == OrderStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s16, AppSpacing.s8, AppSpacing.s8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.title('Order #${order.orderId}'),
                    AppText.caption(Fmt.dateTime(order.orderDate)),
                  ],
                ),
              ),
              OrderStatusControl(order: order),
              IconButton(tooltip: 'Close', icon: const Icon(Iconsax.close_circle_copy), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s8, AppSpacing.s24, AppSpacing.s24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Customer'),
                    if (c == null)
                      const AppText.bodySmall('No customer on this order.', color: AppColors.muted)
                    else ...[
                      Row(children: [
                        InitialsAvatar(Fmt.initials(c.fullName)),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [AppText.label(c.fullName), AppText.caption('#${c.customerId}')],
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.s12),
                      InfoRow(icon: Iconsax.call_copy, label: 'Mobile', value: c.phone),
                      if (c.secondaryPhone.trim().isNotEmpty)
                        InfoRow(icon: Iconsax.call_add_copy, label: 'Second phone', value: c.secondaryPhone),
                      InfoRow(
                        icon: Iconsax.location_copy,
                        label: 'Deliver to',
                        value: [c.address, c.city, c.governorate].where((s) => s.trim().isNotEmpty).join(', '),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader('Items', subtitle: Fmt.count(order.orderItems.length, 'line')),
                    for (final item in order.orderItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: const BoxDecoration(color: AppColors.blush, borderRadius: AppRadius.smallBorderRadius),
                              child: AppText.label('${item.quantity}×', color: AppColors.burgundy),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(child: AppText.body(item.displayName, maxLines: 2)),
                            AppText.label(Fmt.money(item.unitPrice * item.quantity)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader('Payment'),
                    InfoRow(label: 'Method', value: optionLabel(paymentMethods, order.paymentMethod)),
                    InfoRow(label: 'Came from', value: optionLabel(orderSources, order.orderSource)),
                    const SizedBox(height: AppSpacing.s8),
                    OrderTotalsView(OrderTotals.ofOrder(order)),
                  ],
                ),
              ),
              if ((order.notes ?? '').trim().isNotEmpty && order.notes!.trim() != '-') ...[
                const SizedBox(height: AppSpacing.s16),
                AppCard(
                  variant: AppCardVariant.blush,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Iconsax.note_1_copy, size: 18, color: AppColors.burgundy),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(child: AppText.body(order.notes!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.line))),
          child: SafeArea(
            top: false,
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              alignment: WrapAlignment.end,
              children: [
                if (canDelete)
                  AppButton.text(
                    label: 'Delete',
                    icon: Iconsax.trash_copy,
                    onPressed: () async {
                      if (await deleteOrder(context, order) && context.mounted) Navigator.pop(context);
                    },
                  ),
                AppButton.secondary(label: 'Invoice', icon: Iconsax.printer_copy, onPressed: () => openInvoice(context, order)),
                if (canEdit)
                  AppButton.primary(
                    label: 'Edit order',
                    icon: Iconsax.edit_2_copy,
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit(order);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
