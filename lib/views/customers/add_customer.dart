import 'package:flutter/material.dart';
import 'package:warsha_app/views/customers/governorate_dropdown.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/add_order/add_customer.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

class AddCustomer extends StatelessWidget {
  const AddCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    final Size size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 800;

    return Consumer2<CustomerProvider, CustomerVM>(
      builder: (context, value, customerVM, child) => Scaffold(
        extendBodyBehindAppBar: true,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: 100,
                horizontal: isDesktop ? 0 : 20,
              ),
              child: Container(
                // Constrain width on Desktop
                width: isDesktop ? 800 : double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.profile_add_copy,
                              color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 10),
                          const DefaultText(
                            txt: "Customer Details",
                            size: 18,
                            bold: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Adaptive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              _buildResponsiveRow(
                                isDesktop: isDesktop,
                                children: [
                                  DefaultCustomerForm(
                                    title: "Full Name",
                                    controller: value.name,
                                    icon: Iconsax.profile_circle_copy,
                                  ),
                                  DefaultCustomerForm(
                                    title: "Primary Phone",
                                    controller: value.phone,
                                    icon: Iconsax.call_copy,
                                    inputType: TextInputType.phone,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildResponsiveRow(
                                isDesktop: isDesktop,
                                children: [
                                  DefaultCustomerForm(
                                    title: "Secondary Phone",
                                    controller: value.secondaryPhone,
                                    icon: Iconsax.call_add_copy,
                                    inputType: TextInputType.phone,
                                  ),
                                  _buildGovernorateDropdown(context, value),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildResponsiveRow(
                                isDesktop: isDesktop,
                                children: [
                                  DefaultCustomerForm(
                                    title: "City / Area",
                                    controller: value.city,
                                    icon: Iconsax.buildings_copy,
                                  ),
                                  DefaultCustomerForm(
                                    title: "Detailed Address",
                                    controller: value.address,
                                    icon: Iconsax.location_copy,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: DefaultButton(
                          onTap: () async {
                            // Basic Validation
                            if (value.name.text.isEmpty || value.phone.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill in Name and Phone"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            String status = await customerVM.addCustomer(
                              value.name.text,
                              value.governorate.text,
                              value.phone.text,
                              value.address.text,
                              value.secondaryPhone.text,
                              value.city.text,
                            );

                            if (status == "customer_added") {
                              if (context.mounted) {
                                Navigator.pop(context);
                                value.clearCustomer();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Customer added successfully"),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          isValid: !customerVM.isLoading,
                          isLoading: customerVM.isLoading,
                          title: "Save Customer",
                          margin: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build rows on desktop and columns on mobile
  Widget _buildResponsiveRow({required bool isDesktop, required List<Widget> children}) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((w) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: w,
        ))).toList(),
      );
    } else {
      return Column(
        children: children.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: w,
        )).toList(),
      );
    }
  }

  Widget _buildGovernorateDropdown(BuildContext context, dynamic value) {
    return GovernorateDropdown(controller: value.governorate);
  }
}

class DefaultCustomerForm extends StatelessWidget {
  const DefaultCustomerForm({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    this.onChange,
    this.inputType,
  });

  final String title;
  final TextEditingController controller;
  final Function(String)? onChange;
  final IconData? icon;
  final TextInputType? inputType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChange,
      keyboardType: inputType,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        errorStyle: TextStyle(color: Colors.red.shade300),
        prefixIcon: icon != null
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
          ),
        )
            : null,
        labelText: title,
        labelStyle: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}