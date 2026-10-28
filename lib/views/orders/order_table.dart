import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/models/orderModel.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/models/order_totals.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/services/base_url.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/date.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/views/orders/update_order/update_order.dart';
import 'package:warsha_app/views/products/invoices.dart';

import 'order_status_control.dart';
import 'order_ui.dart';

class OrderList extends StatelessWidget {
  const OrderList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderVM>();

    switch (provider.state) {
      case ViewState.loading:
        return Center(
          child: SpinKitChasingDots(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        );
      case ViewState.error:
        return Center(
          child: Text(
            'Error: ${provider.errorMessage}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case ViewState.idle:
        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(context, provider),
            ),
          ),
        );
    }
  }

  // This is the native Flutter DataTable
  Widget _buildDataTable(BuildContext context, OrderVM orderVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: DataTable(
        sortColumnIndex: orderVM.sortColumnIndex,
        sortAscending: orderVM.sortAscending,
        dividerThickness: 0.05,
        columnSpacing: 40,
        headingRowHeight: 45,
        columns: [
          // Id
          DataColumn(
            label: const DefaultText(txt: '#', bold: true),
            onSort: (columnIndex, ascending) {
              orderVM.sort<num>(
                  (order) => order.orderId ?? 0, columnIndex, ascending);
            },
          ),

          // Date
          DataColumn(
            label: Row(
              children: [
                const DefaultText(txt: 'Order Date', bold: true),
                IconButton(
                  icon: const Icon(Iconsax.sort_copy, size: 20),
                  onPressed: () async {
                    final DateTimeRange? newDateRange =
                        await showDateRangePicker(
                      context: context,
                      initialDateRange:
                          (orderVM.startDate != null && orderVM.endDate != null)
                              ? DateTimeRange(
                                  start: orderVM.startDate!,
                                  end: orderVM.endDate!)
                              : null,
                      firstDate: DateTime(2025),
                      initialEntryMode: DatePickerEntryMode.inputOnly,
                      lastDate: DateTime.now(),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary:
                                      Theme.of(context).colorScheme.tertiary,
                                ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .tertiary, // "Save" and "Cancel" text color
                              ),
                            ),
                            dialogTheme: DialogThemeData(
                                backgroundColor: Colors.grey[850]),
                          ),
                          child: child!,
                        );
                      },
                    );

                    // Update the ViewModel with the new range
                    orderVM.setDateRange(newDateRange);
                  },
                )
              ],
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<DateTime>(
                (order) => order.orderDate ?? DateTime.now(),
                columnIndex,
                ascending,
              );
            },
          ),

          // Customer
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Customer',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.customer,
                onChanged: (val) => orderVM.applyFilter('customer', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.customer?.fullName ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Phone
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Phone',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.phone,
                onChanged: (val) => orderVM.applyFilter('phone', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.customer?.phone ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Status
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Status',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.status,
                onChanged: (val) => orderVM.applyFilter('status', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.status?.label ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Governorate
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Governorate',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.governorate,
                onChanged: (val) => orderVM.applyFilter('governorate', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.customer?.governorate ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Total
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Total',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.total,
                onChanged: (val) => orderVM.applyFilter('total', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<num>(
                (order) => order.totalPrice ?? 0,
                columnIndex,
                ascending,
              );
            },
          ),

          // Source
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Source',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.source,
                onChanged: (val) => orderVM.applyFilter('source', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.orderSource ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Source
          DataColumn(
            label: SizedBox(
              height: 22,
              width: 120,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Payment Method',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  suffixIcon: Icon(Iconsax.sort_copy, size: 20),
                ),
                controller: orderVM.paymentMethod,
                onChanged: (val) => orderVM.applyFilter('paymentMethod', val),
              ),
            ),
            onSort: (columnIndex, ascending) {
              orderVM.sort<String>(
                (order) => order.paymentMethod ?? '',
                columnIndex,
                ascending,
              );
            },
          ),

          // Actions
          const DataColumn(
            label: DefaultText(txt: 'Actions', bold: true),
          ),
        ],
        rows: orderVM.orders
            .map((order) => _buildDataRow(context, order))
            .toList(),
      ),
    );
  }

  // This is the native Flutter DataRow
  DataRow _buildDataRow(BuildContext context, OrderModel order) {
    return DataRow(
      cells: [
        DataCell(Text('#${order.orderId}')),
        DataCell(Text(DateHelper.formatDatePicker(order.orderDate.toString()))),
        DataCell(Text(
          order.customer?.fullName ?? "-",
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(order.customer?.phone ?? "-")),
        DataCell(
          SizedBox(
            width: 130,
            height: 25,
            child: OrderStatusDropdown(order: order),
          ),
        ),
        DataCell(Text(order.customer?.governorate ?? "-")),
        DataCell(Text('${order.amountDue?.toStringAsFixed(2) ?? "-"} EGP')),
        DataCell(Text(order.orderSource?.toUpperCase() ?? "-")),
        DataCell(Text(order.paymentMethod?.toUpperCase() ?? "-")),
        DataCell(_buildActionButtons(context, order)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel order) {
    final status = order.status;
    final canEdit = status?.isEditable ?? false;
    final canDelete = status == OrderStatus.pending || status == OrderStatus.cancelled;
    final isSaving = context.watch<OrderVM>().isSaving;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Iconsax.eye_copy, size: 20),
          onPressed: () => _showOrderDetails(context, order),
        ),
        IconButton(
          icon: const Icon(Iconsax.document_text_copy,
              size: 20, color: Colors.green),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewPage(
                    pdfPath: "${Baseurl.invoiceAPI}/${order.orderId}"),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Iconsax.edit_2_copy, size: 20),
          color: Colors.blue,
          tooltip: canEdit
              ? 'Edit order'
              : 'Only Pending or Processing orders can be edited',
          onPressed: !canEdit ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateOrder(
                  existingOrder: order,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Iconsax.trash_copy, size: 20),
          color: Colors.red,
          tooltip: canDelete
              ? 'Delete order'
              : 'Only Pending or Cancelled orders can be deleted. Cancel it first.',
          onPressed: canDelete && !isSaving
              ? () async => _deleteOrder(context, order, context.read<OrderVM>())
              : null,
        ),
      ],
    );
  }

  Future<void> _deleteOrder(
    BuildContext context,
    OrderModel order,
    OrderVM provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to delete order #${order.orderId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // Cancel pressed

    if (!context.mounted) return;

    final ok = await provider.deleteOrder(order.orderId!);
    if (!context.mounted) return;
    if (ok) {
      showOrderMessage(context, 'Order #${order.orderId} deleted');
      refreshAfterOrderChange(context);
    } else {
      showOrderError(context, provider.lastError);
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Text('Order Details #${order.orderId}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),

                  // All this UI is copied from your _expanded section
                  _buildDetailSection(
                    context,
                    "Delivery Details",
                    [
                      _buildDetailRow("Address:",
                          "${order.customer?.address ?? "-"} - ${order.customer?.governorate ?? "-"}"),
                      _buildDetailRow("Status:", order.status?.label ?? "-"),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildDetailSection(
                    context,
                    "Payment",
                    [
                      _buildDetailRow("Method:", order.paymentMethod ?? "-"),
                      OrderTotalsView(OrderTotals.ofOrder(order)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildDetailSection(
                    context,
                    "Order Items",
                    [
                      // Items Header
                      const Row(
                        children: [
                          Expanded(
                              flex: 4,
                              child: Text('Product',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text('Qty',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text('Price',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text('Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withAlpha(50),
                      ),
                      // Items List
                      ...order.orderItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(item.displayName)),
                              Expanded(
                                  flex: 2,
                                  child: Text(item.quantity.toString())),
                              Expanded(
                                  flex: 2,
                                  child: Text("${item.unitPrice} EGP")),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.unitPrice * item.quantity} EGP',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    context,
                    "Additional Notes",
                    [
                      Text(order.notes ?? "-"),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for the modal
  Widget _buildDetailSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withAlpha(50),
              width: 1),
          borderRadius: Constants.BORDER_RADIUS_20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Divider(
            color: Theme.of(context).colorScheme.tertiary.withAlpha(50),
          ),
          ...children,
        ],
      ),
    );
  }

  // Helper widget for the modal
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
