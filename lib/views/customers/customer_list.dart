import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/views/customers/update_customer.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  /// Rows drawn at once; search narrows the rest down.
  static const _maxRows = 50;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();

    if (vm.loadFailed) {
      return Expanded(child: LoadErrorView(message: vm.errorMessage!, onRetry: vm.fetch));
    }
    if (!vm.hasLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: SpinKitChasingDots(color: Theme.of(context).colorScheme.secondary, size: 30),
        ),
      );
    }
    final all = vm.customers;
    if (all.isEmpty) {
      final q = vm.query.trim();
      return Expanded(child: Center(child: Text(q.isEmpty ? "No customers yet." : 'No customer matches "$q".')));
    }
    final shown = all.take(_maxRows).toList();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dividerThickness: 0.05,
                columnSpacing: 40,
                headingRowHeight: 70,
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceTint.withAlpha(10)),
                columns: const [
                  DataColumn(label: DefaultText(txt: '#', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Full Name', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Governorate', bold: true)),
                  DataColumn(label: DefaultText(txt: 'City', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Primary Phone', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Secondary Phone', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Address', bold: true)),
                  DataColumn(label: DefaultText(txt: 'Actions', bold: true)),
                ],
                rows: [
                  for (final customer in shown)
                    DataRow(cells: [
                      DataCell(DefaultText(txt: '#${customer.customerId}')),
                      DataCell(DefaultText(txt: customer.fullName, bold: true)),
                      DataCell(DefaultText(txt: customer.governorate)),
                      DataCell(DefaultText(txt: customer.city, bold: true)),
                      DataCell(DefaultText(txt: customer.phone)),
                      DataCell(DefaultText(txt: customer.secondaryPhone)),
                      DataCell(DefaultText(txt: customer.address)),
                      DataCell(_Actions(customer: customer)),
                    ]),
                ],
              ),
            ),
            if (all.length > shown.length)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Showing ${shown.length} of ${all.length}. Search to find the others.",
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.customer});

  final CustomerModel customer;

  Future<void> _delete(BuildContext context) async {
    final vm = context.read<CustomerVM>();
    final confirmed = await confirmAction(
      context,
      title: "Delete Customer",
      message: "Delete ${customer.fullName}? Customers with orders can't be deleted.",
      confirmLabel: "Delete",
    );
    if (!confirmed || !context.mounted) return;
    final ok = await vm.delete(customer);
    if (!context.mounted) return;
    reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: "${customer.fullName} deleted.");
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UpdateCustomer(customerModel: customer)),
          ),
          icon: Icon(Iconsax.edit, color: scheme.secondary),
          label: DefaultText(txt: "Update", color: scheme.secondary),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () => _delete(context),
          icon: Icon(Iconsax.trash, color: Colors.red.shade300),
          label: DefaultText(txt: "Delete", color: Colors.red.shade300),
        ),
      ],
    );
  }
}
