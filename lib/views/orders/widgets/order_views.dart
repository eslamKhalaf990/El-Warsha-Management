import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/orders/invoice_page.dart';
import 'package:warsha_app/views/orders/order_actions.dart';
import 'package:warsha_app/views/orders/order_details.dart';
import 'package:warsha_app/views/orders/order_form_page.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_options.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

List<RowAction> orderRowActions(BuildContext context, OrderModel o) {
  final canEdit = o.status?.isEditable ?? false;
  final canDelete = o.status == OrderStatus.pending || o.status == OrderStatus.cancelled;
  return [
    RowAction(label: 'Details', icon: Iconsax.eye_copy, onPressed: () => showOrderDetails(context, o)),
    RowAction(label: 'Invoice', icon: Iconsax.printer_copy, onPressed: () => openInvoice(context, o)),
    if (canEdit) RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openOrderForm(context, order: o)),
    if (canDelete) RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => deleteOrder(context, o)),
  ];
}

/// An order as a card (phones and tablets).
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final items = o.orderItems.fold<int>(0, (n, i) => n + i.quantity);
    return AppCard(
      onTap: () => showOrderDetails(context, o),
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s4, AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText.label('#${o.orderId}'),
              const SizedBox(width: AppSpacing.s8),
              Expanded(child: AppText.caption(Fmt.dateTime(o.orderDate))),
              OrderStatusControl(order: o),
              RowActions(orderRowActions(context, o), forceMenu: true),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleSmall(o.customer?.fullName ?? 'No customer', maxLines: 1),
                      AppText.caption(
                        [o.customer?.phone, o.customer?.governorate].where((s) => (s ?? '').trim().isNotEmpty).join(' · '),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText.price(Fmt.money(o.grandTotal ?? 0)),
                    AppText.caption('${Fmt.count(items, 'piece')} · due ${Fmt.money(o.amountDue)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One page of orders as a sortable table (desktop).
class OrderTable extends StatelessWidget {
  const OrderTable({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderVM>();

    return AppDataTable(
      sortColumnIndex: vm.sortColumnIndex,
      sortAscending: vm.sortAscending,
      columns: [
        DataColumn(label: const Text('Order'), onSort: (i, a) => vm.sort<num>((o) => o.orderId ?? 0, i, a)),
        DataColumn(
          label: const Text('Date'),
          onSort: (i, a) => vm.sort<DateTime>((o) => o.orderDate ?? DateTime(2000), i, a),
        ),
        DataColumn(label: const Text('Customer'), onSort: (i, a) => vm.sort<String>((o) => o.customer?.fullName ?? '', i, a)),
        DataColumn(
          label: const Text('Governorate'),
          onSort: (i, a) => vm.sort<String>((o) => o.customer?.governorate ?? '', i, a),
        ),
        const DataColumn(label: Text('Source')),
        DataColumn(label: const Text('Total'), numeric: true, onSort: (i, a) => vm.sort<num>((o) => o.grandTotal ?? 0, i, a)),
        DataColumn(label: const Text('Due'), numeric: true, onSort: (i, a) => vm.sort<num>((o) => o.amountDue ?? 0, i, a)),
        DataColumn(label: const Text('Status'), onSort: (i, a) => vm.sort<String>((o) => o.status?.label ?? '', i, a)),
        const DataColumn(label: Text('')),
      ],
      rows: [
        for (final o in vm.pagedOrders)
          DataRow(
            onSelectChanged: (_) => showOrderDetails(context, o),
            cells: [
              DataCell(AppText.label('#${o.orderId}')),
              DataCell(Text(Fmt.dateTime(o.orderDate))),
              DataCell(Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(o.customer?.fullName ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  AppText.caption(o.customer?.phone ?? ''),
                ],
              )),
              DataCell(Text(o.customer?.governorate ?? '—')),
              DataCell(Text(optionLabel(orderSources, o.orderSource))),
              DataCell(Text(Fmt.money(o.grandTotal ?? 0))),
              DataCell(Text(
                Fmt.money(o.amountDue),
                style: TextStyle(color: (o.amountDue ?? 0) > 0 ? AppColors.burgundy : AppColors.muted),
              )),
              DataCell(OrderStatusControl(order: o)),
              DataCell(RowActions(orderRowActions(context, o))),
            ],
          ),
      ],
      footer: TablePager(page: vm.page, pageSize: OrderVM.pageSize, total: vm.orders.length, onPage: vm.setPage),
    );
  }
}
