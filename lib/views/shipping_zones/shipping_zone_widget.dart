import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';
import 'package:warsha_app/views/shipping_zones/add_shipping_zone.dart';

class ShippingZoneWidget extends StatelessWidget {
  final ShippingZone zone;

  const ShippingZoneWidget({
    super.key,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 700;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Row(
      children: [
        _buildZoneIcon(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(
                txt: zone.cityName,
                size: 16,
                bold: true,
                center: false,
              ),
              const SizedBox(height: 4),
              DefaultText(
                txt: zone.isActive ? "Price: ${zone.priceLabel}" : "Price: ${zone.priceLabel} · not delivering",
                size: 14,
                color: Colors.grey,
                center: false,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildActiveSwitch(context),
            _buildEditButton(context),
            _buildDeleteButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildZoneIcon(context),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: DefaultText(txt: zone.cityName, size: 18, bold: true, center: false),
        ),
        Expanded(
          child: DefaultText(
            txt: zone.priceLabel,
            size: 16,
            bold: true,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Row(
          children: [
            _buildActiveSwitch(context),
            _buildEditButton(context),
            const SizedBox(width: 8),
            _buildDeleteButton(context),
          ],
        )
      ],
    );
  }

  Widget _buildZoneIcon(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Iconsax.truck_fast_copy,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildActiveSwitch(BuildContext context) {
    final zoneVM = context.read<ShippingZoneVM>();
    return Tooltip(
      message: zone.isActive ? "Delivering here (tap to stop)" : "Not delivering here (tap to start)",
      child: Switch(
        value: zone.isActive,
        onChanged: (active) async {
          final ok = await zoneVM.setActive(zone, active);
          if (!context.mounted) return;
          reportResult(
            context,
            ok: ok,
            errorMessage: zoneVM.errorMessage,
            success: active ? "${zone.cityName} is open for delivery." : "${zone.cityName} is hidden from the store.",
          );
        },
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return IconButton(
      tooltip: "Edit",
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddShippingZone(zone: zone))),
      icon: Icon(Iconsax.edit, color: Theme.of(context).colorScheme.primary, size: 24),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final zoneVM = context.read<ShippingZoneVM>();

    return IconButton(
      tooltip: "Delete",
      onPressed: () async {
        final confirm = await confirmAction(
          context,
          title: "Delete Shipping Zone",
          message: "Delete the zone for ${zone.cityName}? Customers there won't be able to check out. "
              "To stop delivering for a while, turn the switch off instead.",
          confirmLabel: "Delete",
        );
        if (!confirm || !context.mounted) return;
        final ok = await zoneVM.delete(zone);
        if (!context.mounted) return;
        reportResult(context, ok: ok, errorMessage: zoneVM.errorMessage, success: "${zone.cityName} deleted.");
      },
      icon: const Icon(Iconsax.trash, color: Colors.red, size: 24),
    );
  }
}
