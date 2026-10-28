import 'package:flutter/material.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/views/customers/add_customer.dart';

/// Edit screen for [customerModel]; the same form as [AddCustomer].
class UpdateCustomer extends StatelessWidget {
  const UpdateCustomer({super.key, required this.customerModel});
  final CustomerModel customerModel;

  @override
  Widget build(BuildContext context) => AddCustomer(customer: customerModel);
}
