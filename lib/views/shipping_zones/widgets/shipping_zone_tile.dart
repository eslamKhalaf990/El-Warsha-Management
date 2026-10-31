import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/shipping_zones/shipping_zone_form_dialog.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// A governorate with its delivery price and an on/off switch.
class ShippingZoneTile extends StatelessWidget {
  const ShippingZoneTile({super.key, required this.zone});

  final ShippingZone zone;

  Future<void> _toggle(BuildContext context, bool active) async {
    final vm = context.read<ShippingZoneVM>();
    final ok = await vm.setActive(zone, active);
    if (!context.mounted) return;
    reportResult(
      context,
      ok: ok,
      errorMessage: vm.errorMessage,
      success: active ? 'Delivering to ${zone.cityName} again.' : '${zone.cityName} is off for now.',
    );
  }

  Future<void> _delete(BuildContext context) async {
    final vm = context.read<ShippingZoneVM>();
    final confirmed = await confirmAction(
      context,
      title: 'Delete shipping zone?',
      message: 'Customers in ${zone.cityName} can no longer be delivered to. '
          'To pause it instead, switch it off.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await vm.delete(zone);
    if (context.mounted) reportResult(context, ok: ok, errorMessage: vm.errorMessage, success: '${zone.cityName} deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<ShippingZoneVM, bool>((vm) => vm.isSaving);
    return EntityTile(
      dimmed: !zone.isActive,
      leading: IconBadge(Iconsax.location_copy, tone: zone.isActive ? Tone.brand : Tone.neutral),
      title: zone.cityName,
      meta: [
        StatusPill(label: zone.priceLabel, icon: Iconsax.truck_fast_copy, tone: Tone.brand),
        if (!zone.isActive) const StatusPill(label: 'Off', tone: Tone.neutral),
      ],
      trailing: Tooltip(
        message: zone.isActive ? 'Stop delivering here' : 'Deliver here',
        child: Switch(value: zone.isActive, onChanged: saving ? null : (v) => _toggle(context, v)),
      ),
      actions: [
        RowAction(label: 'Edit', icon: Iconsax.edit_2_copy, onPressed: () => openShippingZoneForm(context, zone: zone)),
        RowAction(label: 'Delete', icon: Iconsax.trash_copy, destructive: true, onPressed: () => _delete(context)),
      ],
      onTap: () => openShippingZoneForm(context, zone: zone),
    );
  }
}
