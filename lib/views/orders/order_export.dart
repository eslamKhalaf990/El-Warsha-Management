import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_options.dart';

/// The Orders sheet of the Excel export.
final orderExportColumns = <ExcelColumn<OrderModel>>[
  ExcelColumn('Order', (o) => o.orderId),
  ExcelColumn('Date', (o) => o.orderDate),
  ExcelColumn('Status', (o) => o.status?.label),
  ExcelColumn('Customer', (o) => o.customer?.fullName),
  ExcelColumn('Mobile', (o) => o.customer?.phone),
  ExcelColumn('Second phone', (o) => o.customer?.secondaryPhone),
  ExcelColumn('Governorate', (o) => o.customer?.governorate),
  ExcelColumn('City', (o) => o.customer?.city),
  ExcelColumn('Address', (o) => o.customer?.address),
  ExcelColumn('Source', (o) => optionLabel(orderSources, o.orderSource)),
  ExcelColumn('Payment method', (o) => optionLabel(paymentMethods, o.paymentMethod)),
  ExcelColumn('Pieces', (o) => o.orderItems.fold<int>(0, (n, i) => n + i.quantity)),
  ExcelColumn('Items', (o) => o.orderItems.map((i) => '${i.displayName} ×${i.quantity}').join(', ')),
  ExcelColumn('Discount', (o) => o.discount, money: true),
  ExcelColumn('Extra discount', (o) => o.extraDiscount, money: true),
  ExcelColumn('Delivery', (o) => o.delivery, money: true),
  ExcelColumn('Total', (o) => o.grandTotal, money: true),
  ExcelColumn('Down payment', (o) => o.downPayment, money: true),
  ExcelColumn('Due', (o) => o.amountDue, money: true),
  ExcelColumn('Notes', (o) => o.notes),
];
