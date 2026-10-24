import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/export_orders.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/deafualt_form_field.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/add_order_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/views/orders/add_order/add_order_beta.dart';

class CRUDOrder extends StatelessWidget {
  const CRUDOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check available width
            if (constraints.maxWidth < 900) {
              // --- MOBILE / TABLET LAYOUT (Vertical Stack) ---
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar takes full width
                  TextField(
                    controller: Provider.of<AddOrderVM>(context).searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search By Order Id or customer name',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Buttons wrap to next line if needed
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    children: _buildActionButtons(context),
                  ),
                ],
              );
            } else {
              // --- DESKTOP LAYOUT (Horizontal Row) ---
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: Provider.of<AddOrderVM>(context).searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search By Order Id or customer name or phone',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Spread the buttons in the row
                  ..._buildActionButtons(context),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // Helper method to create the list of buttons
  List<Widget> _buildActionButtons(BuildContext context) {
    return [
      ElevatedButton.icon(
        onPressed: () {
          context.read<OrderVM>().clearError();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddOrderBeta(),
            ),
          );
        },
        icon: const Icon(Iconsax.receipt_item, size: 18),
        label: const Text("Add Order"),
      ),
      const SizedBox(width: 4),
      OutlinedButton.icon(
        onPressed: () {
          exportToExcel(Provider.of<OrderVM>(context, listen: false).orders);
        },
        icon: const Icon(Iconsax.document_download_copy, size: 18, color: Colors.green),
        label: const Text("Export"),
      ),
    ];
  }
}