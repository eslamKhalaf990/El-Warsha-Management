import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/deafualt_form_field.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/views/customers/add_customer.dart';

class CRUDCustomer extends StatefulWidget {
  const CRUDCustomer({super.key});

  @override
  State<CRUDCustomer> createState() => _CRUDCustomerState();
}

class _CRUDCustomerState extends State<CRUDCustomer> {
  late final _searchController = TextEditingController(text: context.read<CustomerVM>().query);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField(BuildContext context) => DefaultForm(
        title: 'Search by name, phone or customer number',
        controller: _searchController,
        numberOfLines: 1,
        onChanged: context.read<CustomerVM>().setQuery,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check screen width
            if (constraints.maxWidth < 700) {
              // --- MOBILE LAYOUT (Vertical) ---
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(context),
                  const SizedBox(height: 15),
                  // Button stretches to full width
                  _buildAddButton(context, isFullWidth: true),
                ],
              );
            } else {
              // --- DESKTOP LAYOUT (Horizontal) ---
              return Row(
                children: [
                  Expanded(
                    child: _buildSearchField(context),
                  ),
                  const SizedBox(width: 15),
                  // Button sized to content
                  _buildAddButton(context, isFullWidth: false),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, {required bool isFullWidth}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddCustomer(),
          ),
        );
      },
      borderRadius: Constants.BORDER_RADIUS_50,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: Constants.BORDER_RADIUS_50,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.profile_add_copy,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            const DefaultText(
              txt: "Add Customer",
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}