import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/customers/customer_form_page.dart';
import 'package:warsha_app/views/customers/widgets/customer_views.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

/// Customers: search, filter by governorate, a paged table on desktop and
/// cards elsewhere.
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();
    final customers = vm.customers;
    final counts = vm.governorateCounts;

    return ModulePage(
      title: 'Customers',
      subtitle: vm.hasLoaded
          ? '${Fmt.count(vm.allCustomers.length, 'customer')} in ${Fmt.count(counts.length, 'governorate')}'
          : 'Everyone who ordered from the store or the shop',
      primaryAction: PageAction(label: 'Add customer', icon: Iconsax.user_add_copy, onPressed: () => openCustomerForm(context)),
      actions: [
        ExportExcelButton<CustomerModel>(
          rows: () => context.read<CustomerVM>().customers,
          columns: customerExportColumns,
          fileName: 'customers',
          sheetName: 'Customers',
          noun: 'customer',
        ),
        IconButton(tooltip: 'Refresh', icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch),
      ],
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(hint: 'Search by name, mobile or #number', initialValue: vm.query, onChanged: vm.setQuery),
          if (counts.length > 1) ...[
            const SizedBox(height: AppSpacing.s12),
            ChipFilterBar<String>(
              allCount: vm.allCustomers.length,
              options: [for (final g in counts) ChipOption(g.governorate, g.governorate, count: g.count)],
              selected: vm.governorate,
              onSelected: vm.setGovernorate,
            ),
          ],
        ],
      ),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: customers.isEmpty,
        empty: vm.query.trim().isNotEmpty || vm.governorate != null
            ? EmptyView.noMatch(vm.query.trim().isEmpty ? vm.governorate! : vm.query)
            : EmptyView(
                icon: Iconsax.profile_2user_copy,
                title: 'No customers yet',
                message: 'Customers from the online store show up here automatically.',
                actionLabel: 'Add customer',
                onAction: () => openCustomerForm(context),
              ),
        builder: (context) => context.isExpanded
            ? const Padding(padding: EdgeInsets.only(bottom: AppSpacing.s24), child: CustomerTable())
            : TileList(items: customers, onRefresh: vm.fetch, itemBuilder: (_, c) => CustomerTile(customer: c)),
      ),
    );
  }
}
