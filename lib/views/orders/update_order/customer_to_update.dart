import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_text.dart';
import '../../../models/customerModel.dart';

/// Customer picker on the edit-order screen, filtered by [query].
class CustomerToUpdate extends StatelessWidget {
  const CustomerToUpdate({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerVM>();
    final orderVM = context.watch<UpdateOrderVM>();

    if (customerVM.loadFailed) {
      return Center(child: Text(customerVM.errorMessage!, textAlign: TextAlign.center));
    }
    if (!customerVM.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final customers = customerVM.search(query, limit: 50);
    if (customers.isEmpty) {
      return Center(child: Text(query.trim().isEmpty ? "No customers yet." : 'No customer matches "${query.trim()}".'));
    }
    return ListView.builder(
      itemCount: customers.length,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final isSelected = orderVM.orderModel.customer?.customerId == customer.customerId;
        return GestureDetector(
          onTap: () => orderVM.addCustomer = customer,
          child: CustomerWidget(customer: customer, isSelected: isSelected),
        );
      },
    );
  }
}

class CustomerWidget extends StatelessWidget {
  final CustomerModel customer;
  final bool isSelected;

  const CustomerWidget({
    super.key,
    required this.customer,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.tertiary.withAlpha(40)
            : Theme.of(context).colorScheme.surface,
        borderRadius: Constants.BORDER_RADIUS_20,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.tertiary
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar / Icon
          CircleAvatar(
            radius: 25,
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.primary.withAlpha(30),
            child: Icon(
              Iconsax.user_copy,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 15),

          // Details Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DefaultText(
                        txt: customer.fullName,
                        bold: true,
                        size: 16,
                        center: false,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Iconsax.tick_circle,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                DefaultText(
                  txt: customer.governorate,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Iconsax.location, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Flexible Phone Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withAlpha(40),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.call, size: 14, color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      DefaultText(
                        txt: customer.phone,
                        size: 12,
                        color: Theme.of(context).colorScheme.tertiary,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}