import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// Opens the add form, or the edit form for [zone].
Future<void> openShippingZoneForm(BuildContext context, {ShippingZone? zone}) {
  context.read<ShippingZoneVM>().clearError();
  return showFormDialog(
    context,
    draft: () => FormDraft(
      text: {
        'cityName': zone?.cityName,
        'shippingFee': zone == null ? null : Fmt.money(zone.shippingPrice, currency: false).replaceAll(',', ''),
      },
      values: {'isActive': zone?.isActive ?? true},
    ),
    dialog: _ShippingZoneFormDialog(zone: zone),
  );
}

class _ShippingZoneFormDialog extends StatelessWidget {
  const _ShippingZoneFormDialog({this.zone});

  final ShippingZone? zone;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<ShippingZoneVM>();
    final d = context.read<FormDraft>();
    final ok = await vm.save(
      cityName: d.text('cityName'),
      priceText: d.text('shippingFee'),
      isActive: d.flag('isActive'),
      editingId: zone?.id,
    );
    if (!context.mounted) return;
    reportResult(
      context,
      ok: ok,
      pop: true,
      errorMessage: vm.errorMessage,
      success: zone == null ? 'Shipping zone added.' : 'Shipping zone updated.',
      fieldError: vm.fieldError,
      fields: const ['cityName', 'shippingFee'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShippingZoneVM>();
    final d = context.watch<FormDraft>();
    return FormDialog(
      title: zone == null ? 'New shipping zone' : 'Edit shipping zone',
      icon: Iconsax.truck_copy,
      saveLabel: zone == null ? 'Add zone' : 'Save changes',
      saving: vm.isSaving,
      onSave: () => _save(context),
      children: [
        AppTextField(
          label: 'Governorate',
          required: true,
          icon: Iconsax.map_1_copy,
          hintText: 'e.g. الإسكندرية',
          controller: d.controller('cityName'),
          errorText: vm.fieldError('cityName'),
          maxLength: ShippingZoneVM.nameMaxLength,
          autofocus: zone == null,
          onChanged: (_) => vm.clearError(),
        ),
        AppTextField.money(
          label: 'Delivery price',
          required: true,
          icon: Iconsax.truck_fast_copy,
          controller: d.controller('shippingFee'),
          errorText: vm.fieldError('shippingFee'),
          onChanged: (_) => vm.clearError(),
          onSubmitted: (_) => _save(context),
        ),
        AppSwitchTile(
          title: 'Deliver here',
          subtitle: d.flag('isActive')
              ? 'Customers can choose this governorate.'
              : 'Hidden from the store and the order forms.',
          value: d.flag('isActive'),
          onChanged: (v) => d.set('isActive', v),
        ),
      ],
    );
  }
}
