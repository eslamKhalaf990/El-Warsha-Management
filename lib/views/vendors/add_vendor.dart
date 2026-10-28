import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/ui/feedback.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';

/// Add a vendor, or edit [vendor] when given.
class AddVendor extends StatefulWidget {
  const AddVendor({super.key, this.vendor});

  final Vendor? vendor;

  @override
  State<AddVendor> createState() => _AddVendorState();
}

class _AddVendorState extends State<AddVendor> {
  late final _nameController = TextEditingController(text: widget.vendor?.name);
  late final _phoneController = TextEditingController(text: widget.vendor?.phone);
  late final _emailController = TextEditingController(text: widget.vendor?.email);
  late final _addressController = TextEditingController(text: widget.vendor?.address);
  late final _taxNumberController = TextEditingController(text: widget.vendor?.taxNumber);
  late final _contactPersonController = TextEditingController(text: widget.vendor?.contactPerson);
  late final _notesController = TextEditingController(text: widget.vendor?.notes);

  static const _fields = ['name', 'phone', 'email', 'address', 'taxNumber', 'contactPerson', 'notes'];

  bool get _isEdit => widget.vendor != null;

  @override
  void initState() {
    super.initState();
    // Errors from a previous visit don't belong to this form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VendorVM>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<VendorVM>();
    final request = VendorRequest(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      taxNumber: _taxNumberController.text,
      contactPerson: _contactPersonController.text,
      notes: _notesController.text,
    );
    final ok = _isEdit ? await vm.update(widget.vendor!.vendorId, request) : await vm.add(request);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSuccess(context, _isEdit ? 'Vendor updated.' : 'Vendor added.');
    } else if (_fields.every((f) => vm.fieldError(f) == null)) {
      // Not about a field (network, server...): say it in a snackbar.
      showError(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorVM = context.watch<VendorVM>();

    return Scaffold(
      appBar: AppBar(
        title: DefaultText(txt: _isEdit ? "Edit Vendor" : "Add New Vendor", bold: true, size: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN: Identification & Contact (Flex 4)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildSectionContainer(
                    context,
                    title: "Legal & Tax Info",
                    child: Column(
                      children: [
                        DefaultVendorForm(
                          title: "Tax Registration Number",
                          controller: _taxNumberController,
                          errorText: vendorVM.fieldError('taxNumber'),
                          maxLength: VendorVM.taxNumberMaxLength,
                          onChanged: (_) => vendorVM.clearError(),
                          icon: Iconsax.document_text_copy,
                        ),
                        const SizedBox(height: 20),
                        DefaultVendorForm(
                          title: "Company Email",
                          controller: _emailController,
                          errorText: vendorVM.fieldError('email'),
                          maxLength: VendorVM.emailMaxLength,
                          onChanged: (_) => vendorVM.clearError(),
                          icon: Iconsax.sms_copy,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionContainer(
                    context,
                    title: "Location Details",
                    child: DefaultVendorForm(
                      title: "Business Address",
                      controller: _addressController,
                      errorText: vendorVM.fieldError('address'),
                      maxLength: VendorVM.addressMaxLength,
                      onChanged: (_) => vendorVM.clearError(),
                      icon: Iconsax.location_copy,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // RIGHT COLUMN: Vendor Details & Actions (Flex 6)
            Expanded(
              flex: 6,
              child: _buildSectionContainer(
                context,
                title: "Vendor Details",
                child: Column(
                  children: [
                    DefaultVendorForm(
                      title: "Vendor/Company Name *",
                      controller: _nameController,
                      errorText: vendorVM.fieldError('name'),
                      maxLength: VendorVM.nameMaxLength,
                      onChanged: (_) => vendorVM.clearError(),
                      icon: Iconsax.shop_copy,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DefaultVendorForm(
                            title: "Contact Person",
                            controller: _contactPersonController,
                            errorText: vendorVM.fieldError('contactPerson'),
                            maxLength: VendorVM.contactPersonMaxLength,
                            onChanged: (_) => vendorVM.clearError(),
                            icon: Iconsax.user_octagon_copy,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DefaultVendorForm(
                            title: "Phone Number",
                            controller: _phoneController,
                            errorText: vendorVM.fieldError('phone'),
                            maxLength: VendorVM.phoneMaxLength,
                            onChanged: (_) => vendorVM.clearError(),
                            icon: Iconsax.call_calling_copy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DefaultVendorForm(
                      title: "Additional Notes",
                      controller: _notesController,
                      errorText: vendorVM.fieldError('notes'),
                      maxLength: VendorVM.notesMaxLength,
                      onChanged: (_) => vendorVM.clearError(),
                      icon: Iconsax.note_2_copy,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              ),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: DefaultButton(
                            onTap: _save,
                            isValid: !vendorVM.isSaving,
                            isLoading: vendorVM.isSaving,
                            title: _isEdit ? "Save Changes" : "Save Vendor",
                            margin: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }
}

// Reusable Form Field to match your Product style
class DefaultVendorForm extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final String? errorText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const DefaultVendorForm({
    super.key,
    required this.title,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.errorText,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(maxLines > 1 ? 15 : 25);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: title,
        errorText: errorText,
        errorMaxLines: 2,
        counterText: '',
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200),
          borderRadius: radius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
          borderRadius: radius,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          borderRadius: radius,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
          borderRadius: radius,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
    );
  }
}
