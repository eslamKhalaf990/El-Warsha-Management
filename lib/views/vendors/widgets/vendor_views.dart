import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/vendors/vendor_form_page.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';

List<RowAction> _actions(BuildContext context, Vendor v) => [
      RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openVendorForm(context, vendor: v)),
      RowAction(label: 'Archive', icon: Iconsax.archive_1_copy, destructive: true, onPressed: () => _archive(context, v)),
    ];

Future<void> _archive(BuildContext context, Vendor v) async {
  final vm = context.read<VendorVM>();
  final confirmed = await confirmAction(
    context,
    title: 'Archive vendor?',
    message: '"${v.name}" will be hidden from the list. Past purchases keep their vendor.',
    confirmLabel: 'Archive',
    icon: Iconsax.archive_1_copy,
  );
  if (!confirmed || !context.mounted) return;
  final ok = await vm.archive(v);
  if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '"${v.name}" archived.');
}

String? _blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

/// The Vendors sheet of the Excel export.
final vendorExportColumns = <ExcelColumn<Vendor>>[
  ExcelColumn('Vendor', (v) => v.name),
  ExcelColumn('Contact person', (v) => v.contactPerson),
  ExcelColumn('Phone', (v) => v.phone),
  ExcelColumn('Email', (v) => v.email),
  ExcelColumn('Address', (v) => v.address),
  ExcelColumn('Tax number', (v) => v.taxNumber),
  ExcelColumn('Notes', (v) => v.notes),
  ExcelColumn('Added', (v) => v.createdAt),
];

/// A vendor as a list row (phones and tablets).
class VendorTile extends StatelessWidget {
  const VendorTile({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return EntityTile(
      leading: InitialsAvatar(Fmt.initials(v.name), size: 44),
      title: v.name,
      subtitle: _blank(v.contactPerson),
      meta: [
        if (_blank(v.phone) case final phone?) StatusPill(label: phone, icon: Iconsax.call_copy, tone: Tone.brand),
        if (_blank(v.email) case final email?) StatusPill(label: email, icon: Iconsax.sms_copy),
        if (_blank(v.taxNumber) case final tax?) StatusPill(label: 'Tax $tax', icon: Iconsax.document_text_copy),
      ],
      actions: _actions(context, v),
      onTap: () => openVendorForm(context, vendor: v),
    );
  }
}

/// Vendors as a table (desktop).
class VendorTable extends StatelessWidget {
  const VendorTable({super.key, required this.vendors});

  final List<Vendor> vendors;

  @override
  Widget build(BuildContext context) {
    DataCell text(String? s) => DataCell(Text(_blank(s) ?? '—'));
    return AppDataTable(
      columns: const [
        DataColumn(label: Text('Vendor')),
        DataColumn(label: Text('Contact person')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Tax number')),
        DataColumn(label: Text('Added')),
        DataColumn(label: Text('')),
      ],
      rows: [
        for (final v in vendors)
          DataRow(
            onSelectChanged: (_) => openVendorForm(context, vendor: v),
            cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InitialsAvatar(Fmt.initials(v.name), size: 32),
                  const SizedBox(width: AppSpacing.s12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(v.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              )),
              text(v.contactPerson),
              text(v.phone),
              text(v.email),
              text(v.taxNumber),
              DataCell(Text(Fmt.date(v.createdAt))),
              DataCell(RowActions(_actions(context, v))),
            ],
          ),
      ],
    );
  }
}
