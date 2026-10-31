import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/customers/customer_form_page.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

List<RowAction> _actions(BuildContext context, CustomerModel c) => [
      RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openCustomerForm(context, customer: c)),
      RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context, c)),
    ];

Future<void> _delete(BuildContext context, CustomerModel c) async {
  final vm = context.read<CustomerVM>();
  final confirmed = await confirmAction(
    context,
    title: 'Delete customer?',
    message: '${c.fullName} will be removed. Customers with orders can’t be deleted.',
    confirmLabel: 'Delete',
  );
  if (!confirmed || !context.mounted) return;
  final ok = await vm.delete(c);
  if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '${c.fullName} deleted.');
}

String _place(CustomerModel c) =>
    [c.city, c.governorate].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

/// The Customers sheet of the Excel export.
final customerExportColumns = <ExcelColumn<CustomerModel>>[
  ExcelColumn('#', (c) => c.customerId),
  ExcelColumn('Customer', (c) => c.fullName),
  ExcelColumn('Mobile', (c) => c.phone),
  ExcelColumn('Second phone', (c) => c.secondaryPhone),
  ExcelColumn('Email', (c) => c.email),
  ExcelColumn('Governorate', (c) => c.governorate),
  ExcelColumn('City', (c) => c.city),
  ExcelColumn('Address', (c) => c.address),
];

/// A customer as a list row (phones and tablets).
class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return EntityTile(
      leading: InitialsAvatar(Fmt.initials(c.fullName), size: 44),
      title: c.fullName,
      subtitle: c.address.trim().isEmpty ? null : c.address,
      meta: [
        StatusPill(label: c.phone, icon: Iconsax.call_copy, tone: Tone.brand),
        if (_place(c).isNotEmpty) StatusPill(label: _place(c), icon: Iconsax.location_copy),
      ],
      actions: _actions(context, c),
      onTap: () => openCustomerForm(context, customer: c),
    );
  }
}

/// One page of customers as a table (desktop).
class CustomerTable extends StatelessWidget {
  const CustomerTable({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();
    DataCell text(String s) => DataCell(Text(s.trim().isEmpty ? '—' : s, overflow: TextOverflow.ellipsis));
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('#'), numeric: true),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Mobile')),
        DataColumn(label: Text('Second phone')),
        DataColumn(label: Text('Governorate')),
        DataColumn(label: Text('Address')),
        DataColumn(label: Text('')),
      ],
      rows: [
        for (final c in vm.pagedCustomers)
          DataRow(
            onSelectChanged: (_) => openCustomerForm(context, customer: c),
            cells: [
              DataCell(Text('${c.customerId}')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InitialsAvatar(Fmt.initials(c.fullName), size: 32),
                  const SizedBox(width: AppSpacing.s12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (c.email.trim().isNotEmpty) AppText.caption(c.email, maxLines: 1),
                      ],
                    ),
                  ),
                ],
              )),
              text(c.phone),
              text(c.secondaryPhone),
              text(_place(c)),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(c.address.trim().isEmpty ? '—' : c.address, overflow: TextOverflow.ellipsis),
              )),
              DataCell(RowActions(_actions(context, c))),
            ],
          ),
      ],
      footer: TablePager(
        page: vm.page,
        pageSize: CustomerVM.pageSize,
        total: vm.customers.length,
        onPage: vm.setPage,
      ),
    );
  }
}
