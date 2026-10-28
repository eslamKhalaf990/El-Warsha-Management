import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/deafualt_form_field.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';

import 'add_product.dart';

class CRUDProduct extends StatefulWidget {
  const CRUDProduct({super.key});

  @override
  State<CRUDProduct> createState() => _CRUDProductState();
}

class _CRUDProductState extends State<CRUDProduct> {
  late final _searchController = TextEditingController(text: context.read<ProductVM>().query);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            // Check screen width to decide layout
            if (constraints.maxWidth < 700) {
              // --- MOBILE LAYOUT (Vertical) ---
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DefaultForm(
                    title: 'Search For Product By Name or ID',
                    controller: _searchController,
                    onChanged: context.read<ProductVM>().setQuery,
                    numberOfLines: 1,
                  ),
                  const SizedBox(height: 15),
                  // Full width button on mobile
                  _buildAddButton(context, isFullWidth: true),
                ],
              );
            } else {
              // --- DESKTOP LAYOUT (Horizontal) ---
              return Row(
                children: [
                  Expanded(
                    child: DefaultForm(
                      title: 'Search For Product By Name or ID',
                      controller: _searchController,
                    onChanged: context.read<ProductVM>().setQuery,
                      numberOfLines: 1,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Standard sized button on desktop
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
            builder: (context) => const AddProduct(),
          ),
        );
      },
      borderRadius: Constants.BORDER_RADIUS_50,
      child: Container(
        // On mobile, this container will take the width provided by parent (stretch)
        // On desktop, it hugs content + padding.
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          borderRadius: Constants.BORDER_RADIUS_50,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center text on mobile
          mainAxisSize: MainAxisSize.min, // Hug content on desktop
          children: [
            Icon(
              Iconsax.box_add,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            const DefaultText(
              txt: "Add Product",
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}