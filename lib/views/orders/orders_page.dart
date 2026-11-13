import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/views/orders/order_actions.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/orders/order_export.dart';
import 'package:warsha_app/views/orders/order_form_page.dart';
import 'package:warsha_app/views/orders/widgets/order_views.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// Orders: status chips, search, date range and governorate filters; a
/// paged table on desktop and cards elsewhere.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderVM>();
    final orders = vm.orders;
    final range = vm.startDate == null ? tr('Last {0} days', [OrderVM.defaultDays]) : '${Fmt.shortDate(vm.startDate)} – ${Fmt.date(vm.endDate)}';

    return ModulePage(
      title: tr('Orders'),
      subtitle: vm.hasLoaded ? '${Fmt.count(vm.allOrders.length, 'order')} · $range' : range,
      primaryAction: PageAction(label: tr('New order'), icon: Iconsax.add_copy, onPressed: () => openOrderForm(context)),
      actions: [
        ExportExcelButton<OrderModel>(
          rows: () => context.read<OrderVM>().orders,
          columns: orderExportColumns,
          fileName: 'orders',
          sheetName: tr('Orders'),
          noun: 'order',
        ),
        IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetchOrders),
      ],
      toolbar: const _Filters(),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetchOrders,
        isEmpty: orders.isEmpty,
        empty: vm.hasFilters
            ? EmptyView(
                icon: Iconsax.search_normal_1_copy,
                title: tr('No orders match'),
                message: tr('Try another word, status or date range.'),
                actionLabel: tr('Clear filters'),
                onAction: vm.clearAllFilters,
              )
            : EmptyView(
                icon: Iconsax.receipt_2_copy,
                title: tr('No orders in this period'),
                message: tr('Orders from the store and the ones you add here show up in this list.'),
                actionLabel: tr('New order'),
                onAction: () => openOrderForm(context),
              ),
        builder: (context) => context.isExpanded
            ? const Padding(padding: EdgeInsets.only(bottom: AppSpacing.s24), child: OrderTable())
            : TileList(items: orders, onRefresh: vm.fetchOrders, itemBuilder: (_, o) => OrderCard(order: o)),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  Future<void> _pickRange(BuildContext context) async {
    final vm = context.read<OrderVM>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: vm.startDate == null ? null : DateTimeRange(start: vm.startDate!, end: vm.endDate ?? now),
      helpText: tr('Show orders placed between'),
    );
    if (range != null) vm.setDateRange(range);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderVM>();
    final counts = vm.statusCounts;
    final governorates = vm.governorates;

    final search = AppSearchField(
      hint: tr('Search by #order, customer or mobile'),
      initialValue: vm.filterValue('search'),
      onChanged: (q) => vm.applyFilter('search', q),
    );
    final dates = vm.startDate == null
        ? AppButton.secondary(label: tr('Date range'), icon: Iconsax.calendar_1_copy, onPressed: () => _pickRange(context))
        : InputChip(
            avatar: const Icon(Iconsax.calendar_1_copy, size: 16),
            label: Text('${Fmt.shortDate(vm.startDate)} – ${Fmt.shortDate(vm.endDate)}'),
            onPressed: () => _pickRange(context),
            onDeleted: () => vm.setDateRange(null),
          );
    final governorate = AppDropdown<String?>(
      label: tr('Governorate'),
      icon: Iconsax.map_1_copy,
      hintText: tr('All governorates'),
      items: [null, ...governorates],
      value: vm.governorateFilter,
      itemLabel: (g) => g ?? tr('All governorates'),
      onChanged: vm.setGovernorateFilter,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 860
              ? Row(children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.s12),
                  SizedBox(width: 220, child: governorate),
                  const SizedBox(width: AppSpacing.s12),
                  dates,
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  search,
                  const SizedBox(height: AppSpacing.s12),
                  Row(children: [Expanded(child: governorate), const SizedBox(width: AppSpacing.s8), dates]),
                ]),
        ),
        const SizedBox(height: AppSpacing.s12),
        ChipFilterBar<OrderStatus>(
          allCount: vm.allOrders.length,
          options: [
            for (final s in OrderStatus.values)
              if ((counts[s] ?? 0) > 0 || vm.statusFilter == s) ChipOption(s, s.text, count: counts[s] ?? 0),
          ],
          selected: vm.statusFilter,
          onSelected: vm.setStatusFilter,
        ),
        if (vm.isLoading && vm.hasLoaded) ...[
          const SizedBox(height: AppSpacing.s8),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}
