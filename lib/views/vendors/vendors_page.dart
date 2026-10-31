import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/vendors/vendor_form_page.dart';
import 'package:warsha_app/views/vendors/widgets/vendor_views.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';

/// Suppliers: a table on desktop, cards elsewhere.
class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VendorVM>();
    final vendors = vm.vendors;

    return ModulePage(
      title: 'Vendors',
      subtitle: vm.hasLoaded ? Fmt.count(vm.allVendors.length, 'active vendor') : 'Who you buy materials from',
      primaryAction: PageAction(label: 'Add vendor', icon: Iconsax.add_copy, onPressed: () => openVendorForm(context)),
      actions: [
        ExportExcelButton<Vendor>(
          rows: () => context.read<VendorVM>().vendors,
          columns: vendorExportColumns,
          fileName: 'vendors',
          sheetName: 'Vendors',
          noun: 'vendor',
        ),
        IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch),
      ],
      toolbar: AppSearchField(
        hint: 'Search by name, contact, phone or tax number',
        initialValue: vm.query,
        onChanged: vm.search,
      ),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: vendors.isEmpty,
        empty: vm.query.trim().isNotEmpty
            ? EmptyView.noMatch(vm.query)
            : EmptyView(
                icon: Iconsax.shop_copy,
                title: 'No vendors yet',
                message: 'Keep your suppliers’ contacts and tax numbers in one place.',
                actionLabel: 'Add vendor',
                onAction: () => openVendorForm(context),
              ),
        builder: (context) => context.isExpanded
            ? Padding(padding: const EdgeInsets.only(bottom: AppSpacing.s24), child: VendorTable(vendors: vendors))
            : TileList(items: vendors, onRefresh: vm.fetch, itemBuilder: (_, v) => VendorTile(vendor: v)),
      ),
    );
  }
}
