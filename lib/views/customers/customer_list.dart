import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import '../../models/customerModel.dart';
import '../../utils/default_text.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:warsha_app/views/customers/update_customer.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    final customerVM = Provider.of<CustomerVM>(context);

    return FutureBuilder<List<CustomerModel>>(
      future: customerVM.allCustomers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: SpinKitChasingDots(
                color: Theme.of(context).colorScheme.secondary,
                size: 30,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final query =
          customerVM.searchController.text.toLowerCase().trim();
          final filteredCustomers = snapshot.data!.where((customer) {
            final name = customer.fullName.toLowerCase();
            final phone = customer.phone.toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).take(30).toList();

          return Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dividerThickness: 0.05,
                  columnSpacing: 40,
                  headingRowHeight: 70,
                  headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceTint.withAlpha(10)),
                  columns: const [
                    DataColumn(label: DefaultText(txt: '#', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Full Name', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Governorate', bold: true)),
                    DataColumn(label: DefaultText(txt: 'City', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Primary Phone', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Secondary Phone', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Address', bold: true)),
                    DataColumn(label: DefaultText(txt: 'Actions', bold: true)),

                  ],
                  rows: List.generate(filteredCustomers.length, (index) {
                    final customer = filteredCustomers[index];
                    return DataRow(
                      cells: [
                        DataCell(DefaultText(txt: '#${index + 1}')),
                        DataCell(DefaultText(txt: customer.fullName, bold: true)),
                        DataCell(DefaultText(txt: customer.governorate)),
                        DataCell(DefaultText(txt: customer.city, bold: true)),
                        DataCell(DefaultText(txt: customer.phone)),
                        DataCell(DefaultText(txt: customer.secondaryPhone)),
                        DataCell(DefaultText(txt: customer.address)),
                        DataCell(Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UpdateCustomer(customerModel: customer),
                                  ),
                                );
                              },
                              icon: Icon(Iconsax.edit,
                                  color:
                                  Theme.of(context).colorScheme.secondary),
                              label: DefaultText(
                                txt: "Update",
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () {
                                // TODO: Implement delete confirmation logic
                              },
                              icon: Icon(Iconsax.trash, color: Colors.red.shade300),
                              label: DefaultText(
                                txt: "Delete",
                                color: Colors.red.shade300,
                              ),
                            ),
                          ],
                        )),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        } else {
          return const Center(
            child: Text("No customers yet!"),
          );
        }
      },
    );
  }
}
