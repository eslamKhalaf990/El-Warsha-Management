import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/app_text_field.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/views/customers/governorate_dropdown.dart';

/// Add a customer, or edit [customer] when given. Pops `true` after a save;
/// [CustomerVM.lastSaved] holds the saved customer.
class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key, this.customer});

  final CustomerModel? customer;

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  late final _name = TextEditingController(text: widget.customer?.fullName);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _secondaryPhone = TextEditingController(text: widget.customer?.secondaryPhone);
  late final _governorate = TextEditingController(text: widget.customer?.governorate);
  late final _city = TextEditingController(text: widget.customer?.city);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _email = TextEditingController(text: widget.customer?.email);

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomerVM>().clearError();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _secondaryPhone, _governorate, _city, _address, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<CustomerVM>();
    final request = CustomerRequest(
      fullName: _name.text,
      phone: _phone.text,
      governorate: _governorate.text,
      secondaryPhone: _secondaryPhone.text,
      city: _city.text,
      address: _address.text,
      email: _email.text,
    );
    final ok = _isEdit ? await vm.update(widget.customer!.customerId, request) : await vm.add(request);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      showSuccess(context, _isEdit ? 'Customer updated.' : 'Customer added.');
    } else if (CustomerVM.formFields.every((f) => vm.fieldError(f) == null)) {
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerVM>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget field(String key, String label, TextEditingController c, IconData icon,
            {int? maxLength, TextInputType? keyboard, TextDirection? direction}) =>
        AppTextField(
          label: label,
          controller: c,
          icon: icon,
          maxLength: maxLength,
          keyboardType: keyboard,
          textDirection: direction,
          errorText: vm.fieldError(key),
          onChanged: (_) => vm.clearError(),
        );

    return Scaffold(
      appBar: AppBar(
        title: DefaultText(txt: _isEdit ? "Edit Customer" : "Add Customer", bold: true, size: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: isDesktop ? 0 : 20),
          child: Container(
            width: isDesktop ? 800 : double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.profile_add_copy, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 10),
                    const DefaultText(txt: "Customer Details", size: 18, bold: true),
                  ],
                ),
                const SizedBox(height: 24),
                _responsiveRow(isDesktop, [
                  field('fullName', "Full name *", _name, Iconsax.profile_circle_copy,
                      maxLength: CustomerVM.nameMaxLength),
                  field('phone', "Mobile *", _phone, Iconsax.call_copy,
                      maxLength: CustomerVM.phoneMaxLength, keyboard: TextInputType.phone),
                ]),
                const SizedBox(height: 20),
                _responsiveRow(isDesktop, [
                  field('secondaryPhone', "Second phone", _secondaryPhone, Iconsax.call_add_copy,
                      maxLength: CustomerVM.phoneMaxLength, keyboard: TextInputType.phone),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GovernorateDropdown(controller: _governorate),
                      if (vm.fieldError('governorate') case final String error)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 6),
                          child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                _responsiveRow(isDesktop, [
                  field('city', "City / area", _city, Iconsax.buildings_copy, maxLength: CustomerVM.cityMaxLength),
                  field('email', "Email", _email, Iconsax.sms_copy,
                      maxLength: CustomerVM.emailMaxLength, keyboard: TextInputType.emailAddress),
                ]),
                const SizedBox(height: 20),
                field('address', "Detailed address", _address, Iconsax.location_copy,
                    maxLength: CustomerVM.addressMaxLength),
                const SizedBox(height: 32),
                FormActions(onSave: _save, saving: vm.isSaving, saveLabel: _isEdit ? "Save Changes" : "Save Customer"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _responsiveRow(bool isDesktop, List<Widget> children) {
    if (!isDesktop) {
      return Column(
        children: [for (final w in children) Padding(padding: const EdgeInsets.only(bottom: 20), child: w)],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in children)
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: w)),
      ],
    );
  }
}
