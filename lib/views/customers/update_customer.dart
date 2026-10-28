import 'package:flutter/material.dart';
import 'package:warsha_app/views/customers/governorate_dropdown.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/update_order/update_customer.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

class UpdateCustomer extends StatelessWidget {
  const UpdateCustomer({super.key, required this.customerModel});
  final CustomerModel customerModel;

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.read<UpdateCustomerProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      customerProvider.loadCustomer(customerModel);
    });


    return Consumer<UpdateCustomerProvider>(
      builder: (context, value, child) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const DefaultText(txt: "Update Customer"),
        ),
        body: Container(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 60, bottom: 50, right: 15, left: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: Constants.BORDER_RADIUS_15,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              children: [DefaultText(txt: "Customer Info")],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                              child: DefaultCustomerForm(
                                title: "Name",
                                controller: customerProvider.name,
                                icon: Iconsax.bag,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: GovernorateDropdown(controller: customerProvider.governorate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                              child: DefaultCustomerForm(
                                title: "Customer Phone",
                                controller: value.phone,
                                icon: Iconsax.call,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                              child: DefaultCustomerForm(
                                title: "Delivery Address",
                                controller: value.address,
                                icon: Iconsax.location,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Consumer<CustomerVM>(
                                builder: (context, customerVM, child) => Expanded(
                                  flex: 3,
                                  child: DefaultButton(
                                    onTap: () async {
                                      String status = await customerVM.updateCustomer(
                                        customerModel.customerId.toString(),
                                        value.name.text,
                                        value.governorate.text,
                                        value.phone.text,
                                        value.address.text,
                                      );
                                      if (status == "customer_updated") {
                                        Navigator.pop(context);
                                        customerVM.initAllCustomers();
                                        customerVM.getAllCustomers();
                                        value.clearCustomer();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Customer updated successfully"),
                                          ),
                                        );
                                      }
                                    },
                                    isValid: !Provider.of<CustomerVM>(context)
                                        .isLoading,
                                    isLoading: Provider.of<CustomerVM>(context)
                                        .isLoading,
                                    title: "Update Your Customer",
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DefaultCustomerForm extends StatelessWidget {
  const DefaultCustomerForm(
      {super.key,
        required this.title,
        required this.icon,
        required this.controller, this.onChange});
  final String title;
  final TextEditingController controller;
  final Function(String)? onChange;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChange,
      cursorColor: Theme.of(context)
          .colorScheme
          .tertiary
          .withAlpha(Constants.OPACITY_05),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_15),
        errorStyle: TextStyle(color: Colors.red.shade300),
        prefixIcon: icon != null
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
          ),
        )
            : null,
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: Constants.BORDER_RADIUS_15),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_15),
        labelText: title,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}
