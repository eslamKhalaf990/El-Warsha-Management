import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/shipping_zones/shipping_zone_form_dialog.dart';
import 'package:warsha_app/views/shipping_zones/widgets/shipping_zone_tile.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

/// Governorates the store delivers to and what delivery costs there.
class ShippingZonesPage extends StatelessWidget {
  const ShippingZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShippingZoneVM>();
    final zones = vm.zones;
    final active = vm.activeZones.length;

    return ModulePage(
      title: tr('Shipping zones'),
      subtitle: vm.hasLoaded
          ? tr('{0} of {1} governorates open for delivery', [active, vm.allZones.length])
          : tr('Where you deliver and what it costs'),
      primaryAction: PageAction(label: tr('Add zone'), icon: Iconsax.add_copy, onPressed: () => openShippingZoneForm(context)),
      actions: [IconButton(tooltip: tr('Refresh'), icon: const Icon(Iconsax.refresh_copy), onPressed: vm.fetch)],
      toolbar: AppSearchField(hint: tr('Search governorates'), initialValue: vm.query, onChanged: vm.search),
      body: AsyncView(
        vm: vm,
        onRetry: vm.fetch,
        isEmpty: zones.isEmpty,
        empty: vm.query.trim().isNotEmpty
            ? EmptyView.noMatch(vm.query)
            : EmptyView(
                icon: Iconsax.truck_copy,
                title: tr('No shipping zones yet'),
                message: tr('Add the governorates you deliver to. Customers and orders need one.'),
                actionLabel: tr('Add zone'),
                onAction: () => openShippingZoneForm(context),
              ),
        builder: (context) => context.isCompact
            ? TileList(items: zones, onRefresh: vm.fetch, itemBuilder: (_, z) => ShippingZoneTile(zone: z))
            : GridView.builder(
                padding: listPadding(context),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 480,
                  mainAxisExtent: 92,
                  crossAxisSpacing: AppSpacing.s12,
                  mainAxisSpacing: AppSpacing.s12,
                ),
                itemCount: zones.length,
                itemBuilder: (_, i) => ShippingZoneTile(zone: zones[i]),
              ),
      ),
    );
  }
}
