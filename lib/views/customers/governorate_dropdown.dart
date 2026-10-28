import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// Governorate picker fed by the shipping zones, so customers can only be given a
/// governorate the store delivers to. Shows each zone's delivery price.
class GovernorateDropdown extends StatelessWidget {
  const GovernorateDropdown({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ShippingZoneVM>().activeZones;
    final current = controller.text.trim();
    final names = zones.map((z) => z.cityName).toList();
    // Keep an older value that has no zone any more, so the form still opens
    final hasCurrent = current.isNotEmpty && names.contains(current);
    final orphan = current.isNotEmpty && !hasCurrent;

    return DropdownButtonFormField<String>(
      key: ValueKey('${zones.length}-$current'),
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Governorate",
        helperText: zones.isEmpty ? "Add shipping zones first" : null,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary.withAlpha(50)),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Iconsax.map_1_copy, color: Theme.of(context).colorScheme.secondary),
        ),
      ),
      icon: const Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(Icons.arrow_drop_down_rounded),
      ),
      items: [
        for (final zone in zones)
          DropdownMenuItem(
            value: zone.cityName,
            child: Text("${zone.cityName}  ·  ${zone.shippingPrice.toStringAsFixed(0)} EGP"),
          ),
        if (orphan)
          DropdownMenuItem(
            value: current,
            child: Text("$current (no shipping zone)", style: const TextStyle(color: Colors.red)),
          ),
      ],
      onChanged: (value) {
        if (value != null) controller.text = value;
      },
    );
  }
}
