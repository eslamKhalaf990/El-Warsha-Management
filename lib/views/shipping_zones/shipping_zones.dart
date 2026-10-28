import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/async_list_body.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';
import 'package:warsha_app/views/shipping_zones/crud_shipping_zones.dart';
import 'package:warsha_app/views/shipping_zones/shipping_zone_widget.dart';

class ShippingZones extends StatelessWidget {
  const ShippingZones({super.key});

  @override
  Widget build(BuildContext context) {
    final zoneVM = context.watch<ShippingZoneVM>();

    return Column(
      children: [
        const CRUDShippingZone(),
        Expanded(
          child: AsyncListBody(
            vm: zoneVM,
            items: zoneVM.zones,
            query: zoneVM.query,
            onRefresh: zoneVM.fetch,
            emptyText: "No shipping zones yet.",
            itemBuilder: (_, zone) => ShippingZoneWidget(zone: zone),
          ),
        ),
      ],
    );
  }
}
