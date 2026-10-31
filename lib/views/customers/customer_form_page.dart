import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

/// Opens the add form, or the edit form for [customer]. Resolves to the
/// saved customer (so the order form can pick a customer it just created).
Future<CustomerModel?> openCustomerForm(BuildContext context, {CustomerModel? customer, String? phone}) {
  context.read<CustomerVM>().clearError();
  return pushFormPage<CustomerModel>(
    context,
    draft: () => FormDraft(
      text: {
        'fullName': customer?.fullName,
        'phone': customer?.phone ?? phone,
        'secondaryPhone': customer?.secondaryPhone,
        'city': customer?.city,
        'address': customer?.address,
        'email': customer?.email,
      },
      values: {'governorate': (customer?.governorate.trim().isEmpty ?? true) ? null : customer!.governorate.trim()},
    ),
    page: CustomerFormPage(customer: customer),
  );
}

class CustomerFormPage extends StatelessWidget {
  const CustomerFormPage({super.key, this.customer});

  final CustomerModel? customer;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<CustomerVM>();
    final d = context.read<FormDraft>();
    final request = CustomerRequest(
      fullName: d.text('fullName'),
      phone: d.text('phone'),
      secondaryPhone: d.text('secondaryPhone'),
      governorate: d.value<String>('governorate') ?? '',
      city: d.text('city'),
      address: d.text('address'),
      email: d.text('email'),
    );
    final ok = customer == null ? await vm.add(request) : await vm.update(customer!.customerId, request);
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context, vm.lastSaved);
      showSuccess(context, customer == null ? 'Customer added.' : 'Customer updated.');
    } else if (CustomerVM.formFields.every((f) => vm.fieldError(f) == null)) {
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();
    final d = context.watch<FormDraft>();

    AppTextField field(String key, String label, IconData icon, int maxLength,
            {bool required = false, TextInputType? keyboard, int maxLines = 1, String? helper, TextDirection? dir}) =>
        AppTextField(
          label: label,
          icon: icon,
          required: required,
          controller: d.controller(key),
          errorText: vm.fieldError(key),
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboard,
          helperText: helper,
          textDirection: dir,
          onChanged: (_) => vm.clearError(),
        );

    return FormPage(
      title: customer == null ? 'New customer' : 'Edit customer',
      subtitle: customer == null ? null : '#${customer!.customerId} · ${customer!.fullName}',
      draft: d,
      saving: vm.isSaving,
      saveLabel: customer == null ? 'Add customer' : 'Save changes',
      onSave: () => _save(context),
      sections: [
        FormSection(
          title: 'Contact',
          icon: Iconsax.user_copy,
          children: [
            field('fullName', 'Full name', Iconsax.user_copy, CustomerVM.nameMaxLength, required: true),
            FieldRow(children: [
              field('phone', 'Mobile', Iconsax.call_copy, CustomerVM.phoneMaxLength,
                  required: true, keyboard: TextInputType.phone, helper: 'e.g. 01012345678', dir: TextDirection.ltr),
              field('secondaryPhone', 'Second phone', Iconsax.call_add_copy, CustomerVM.phoneMaxLength,
                  keyboard: TextInputType.phone, dir: TextDirection.ltr),
            ]),
            field('email', 'Email', Iconsax.sms_copy, CustomerVM.emailMaxLength,
                keyboard: TextInputType.emailAddress, dir: TextDirection.ltr),
          ],
        ),
        FormSection(
          title: 'Delivery address',
          icon: Iconsax.location_copy,
          children: [
            FieldRow(children: [
              GovernoratePicker(
                value: d.value<String>('governorate'),
                errorText: vm.fieldError('governorate'),
                onChanged: (g) {
                  d.set('governorate', g);
                  vm.clearError();
                },
              ),
              field('city', 'City / area', Iconsax.buildings_copy, CustomerVM.cityMaxLength),
            ]),
            field('address', 'Street address', Iconsax.location_copy, CustomerVM.addressMaxLength,
                maxLines: 2, helper: 'Building, street and a landmark help the courier.'),
          ],
        ),
      ],
    );
  }
}

/// Governorate picker fed by the active shipping zones (with their delivery
/// price), so customers only get governorates the store delivers to. An old
/// value without a zone stays visible so the form still opens.
class GovernoratePicker extends StatelessWidget {
  const GovernoratePicker({super.key, required this.value, required this.onChanged, this.errorText});

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ShippingZoneVM>().activeZones;
    final names = [for (final z in zones) z.cityName];
    final current = value;
    final orphan = current != null && current.isNotEmpty && !names.contains(current);
    final price = {for (final z in zones) z.cityName: z};

    return AppDropdown<String>(
      label: 'Governorate',
      required: true,
      icon: Iconsax.map_1_copy,
      items: [...names, if (orphan) current],
      value: current,
      itemLabel: (n) => price[n] == null ? '$n (no shipping zone)' : '$n · ${price[n]!.priceLabel}',
      helperText: zones.isEmpty ? 'Add shipping zones first.' : null,
      errorText: errorText ?? (orphan ? 'No delivery to $current any more. Pick another governorate.' : null),
      onChanged: onChanged,
    );
  }
}
