import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/async_list_body.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';
import 'package:warsha_app/views/vendors/crud_vendors.dart';
import 'package:warsha_app/views/vendors/vendor_widget.dart';

class Vendors extends StatelessWidget {
  const Vendors({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorVM = context.watch<VendorVM>();

    return Column(
      children: [
        const CRUDVendor(),
        Expanded(
          child: AsyncListBody(
            vm: vendorVM,
            items: vendorVM.vendors,
            query: vendorVM.query,
            onRefresh: vendorVM.fetch,
            emptyText: "No vendors yet.",
            itemBuilder: (_, vendor) => VendorWidget(vendor: vendor),
          ),
        ),
      ],
    );
  }
}
