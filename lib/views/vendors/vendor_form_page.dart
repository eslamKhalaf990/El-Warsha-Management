import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';

const _fields = ['name', 'phone', 'email', 'address', 'taxNumber', 'contactPerson', 'notes'];

/// Opens the add form, or the edit form for [vendor].
Future<void> openVendorForm(BuildContext context, {Vendor? vendor}) {
  context.read<VendorVM>().clearError();
  return pushFormPage(
    context,
    draft: () => FormDraft(text: {
      'name': vendor?.name,
      'phone': vendor?.phone,
      'email': vendor?.email,
      'address': vendor?.address,
      'taxNumber': vendor?.taxNumber,
      'contactPerson': vendor?.contactPerson,
      'notes': vendor?.notes,
    }),
    page: VendorFormPage(vendor: vendor),
  );
}

class VendorFormPage extends StatelessWidget {
  const VendorFormPage({super.key, this.vendor});

  final Vendor? vendor;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<VendorVM>();
    final d = context.read<FormDraft>();
    final request = VendorRequest(
      name: d.text('name'),
      phone: d.text('phone'),
      email: d.text('email'),
      address: d.text('address'),
      taxNumber: d.text('taxNumber'),
      contactPerson: d.text('contactPerson'),
      notes: d.text('notes'),
    );
    final ok = vendor == null ? await vm.add(request) : await vm.update(vendor!.vendorId, request);
    if (!context.mounted) return;
    reportResult(
      context,
      ok: ok,
      pop: true,
      errorMessage: vm.errorMessage,
      success: vendor == null ? 'Vendor added.' : 'Vendor updated.',
      fieldError: vm.fieldError,
      fields: _fields,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VendorVM>();
    final d = context.read<FormDraft>();

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
      title: vendor == null ? 'New vendor' : 'Edit vendor',
      subtitle: vendor?.name,
      draft: d,
      saving: vm.isSaving,
      saveLabel: vendor == null ? 'Add vendor' : 'Save changes',
      onSave: () => _save(context),
      sections: [
        FormSection(
          title: 'Company',
          icon: Iconsax.shop_copy,
          children: [
            field('name', 'Vendor name', Iconsax.building_4_copy, VendorVM.nameMaxLength, required: true),
            field('taxNumber', 'Tax number', Iconsax.document_text_copy, VendorVM.taxNumberMaxLength,
                helper: 'Printed on purchase invoices.', dir: TextDirection.ltr),
          ],
        ),
        FormSection(
          title: 'Contact',
          icon: Iconsax.call_copy,
          children: [
            field('contactPerson', 'Contact person', Iconsax.user_copy, VendorVM.contactPersonMaxLength),
            FieldRow(children: [
              field('phone', 'Phone', Iconsax.call_copy, VendorVM.phoneMaxLength,
                  keyboard: TextInputType.phone, dir: TextDirection.ltr),
              field('email', 'Email', Iconsax.sms_copy, VendorVM.emailMaxLength,
                  keyboard: TextInputType.emailAddress, dir: TextDirection.ltr),
            ]),
          ],
        ),
        FormSection(
          title: 'Address & notes',
          icon: Iconsax.location_copy,
          children: [
            field('address', 'Address', Iconsax.location_copy, VendorVM.addressMaxLength, maxLines: 2),
            field('notes', 'Notes', Iconsax.note_1_copy, VendorVM.notesMaxLength,
                maxLines: 4, helper: 'Payment terms, delivery days, anything worth remembering.'),
          ],
        ),
      ],
    );
  }
}
